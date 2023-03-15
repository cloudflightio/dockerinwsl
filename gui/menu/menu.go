package menu

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"strings"
	"syscall"
	"time"

	"fyne.io/systray"
	"github.com/cloudflightio/dockerinwsl/gui/icon"
	"github.com/docker/docker/client"
)

const CMD_PATH = "C:\\Windows\\system32\\cmd.exe"

type dockerStatus struct {
	isDockerReachable  bool
	lastCheckTimestamp int64
}

type GlobalState int

const (
	Default GlobalState = iota
	Ok
	Warn
	Error
)

func StartMenu() {
	onExit := func() {
		now := time.Now()
		fmt.Println("Exit at", now.String())
	}

	systray.Run(onReady, onExit)
}

func setGlobalState(s GlobalState) {
	ic := icon.DataDefault
	switch s {
	case Ok:
		ic = icon.DataOk
	case Warn:
		ic = icon.DataWarn
	case Error:
		ic = icon.DataErr
	default:
		ic = icon.DataDefault
	}
	systray.SetTemplateIcon(ic, ic)
}

func onReady() {
	systray.SetTemplateIcon(icon.DataDefault, icon.DataDefault)
	systray.SetTitle("DockerInWsl")
	systray.SetTooltip("DockerInWsl")

	statusMenu := systray.AddMenuItem("Docker status", "Docker status")
	check := statusMenu.AddSubMenuItem("Check components", "")
	systray.AddSeparator()

	enter := systray.AddMenuItem("Enter", "Enter")
	enterRoot := systray.AddMenuItem("Enter with root", "Enter with root")
	showLogs := systray.AddMenuItem("Show logs", "Show logs")
	showConfig := systray.AddMenuItem("Show configs", "Show configs")
	advanced := systray.AddMenuItem("Advanced", "Advanced")
	restore := advanced.AddSubMenuItem("Restore", "Restore")
	backup := advanced.AddSubMenuItem("Backup", "Backup")
	systray.AddSeparator()
	restart := systray.AddMenuItem("Restart", "Restart")
	restartAll := systray.AddMenuItem("Restart all", "Restart all")
	start := systray.AddMenuItem("Start", "Start")
	stop := systray.AddMenuItem("Stop", "Stop")
	systray.AddSeparator()
	quit := systray.AddMenuItem("Quit", "Quit")

	status := dockerStatus{
		isDockerReachable:  false,
		lastCheckTimestamp: 0,
	}
	go startCheckDockerStatusLoop(&status)
	go startStatusUpdateLoop(statusMenu, &status)
	statusSubMenuItemMap := make(map[string]*systray.MenuItem)

	for {
		var cmd *exec.Cmd

		select {
		case <-quit.ClickedCh:
			systray.Quit()
		case <-enter.ClickedCh:
			cmd = exec.Command("cmd", "/C", "start", "docker-wsl", "enter")
			cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		case <-enterRoot.ClickedCh:
			cmd = exec.Command("cmd", "/C", "start", "docker-wsl", "enter-root")
			cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		case <-showLogs.ClickedCh:
			cmd = exec.Command("docker-wsl", "show-logs")
			cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		case <-showConfig.ClickedCh:
			cmd = exec.Command("docker-wsl", "show-config")
			cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
		case <-restart.ClickedCh:
			cmd = exec.Command("docker-wsl", "restart")
		case <-restartAll.ClickedCh:
			cmd = exec.Command("docker-wsl", "restart-all")
		case <-start.ClickedCh:
			cmd = exec.Command("docker-wsl", "start")
		case <-stop.ClickedCh:
			cmd = exec.Command("docker-wsl", "stop")
		case <-restore.ClickedCh:
			cmd = exec.Command("docker-wsl", "restore")
		case <-backup.ClickedCh:
			cmd = exec.Command("docker-wsl", "backup")
		case <-check.ClickedCh:
			checkSupervisorStatus(&statusSubMenuItemMap, statusMenu)
		}

		if cmd != nil {
			if err := cmd.Run(); err != nil {
				log.Println("Error:", err)
			}
		}
	}
}

func startCheckDockerStatusLoop(status *dockerStatus) {
	ctx := context.Background()
	ticker := time.NewTicker(10 * time.Second)

	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())

	if err != nil {
		log.Println("Error:", err)
	}

	defer cli.Close()

	if cli != nil {
		for range ticker.C {
			currentTimestamp := time.Now().Unix()
			status.isDockerReachable = checkIfDockerIsReachable(ctx, cli)
			status.lastCheckTimestamp = currentTimestamp
		}
	}
}

func startStatusUpdateLoop(statusMenu *systray.MenuItem, status *dockerStatus) {
	ticker := time.NewTicker(1 * time.Second)

	for range ticker.C {
		currentTimestamp := time.Now().Unix()
		statusMenu.SetTitle(getStatusMenuTitle(status))
		if !status.isDockerReachable {
			setGlobalState(Error)
		} else if status.lastCheckTimestamp+30 < currentTimestamp {
			setGlobalState(Warn)
		} else {
			setGlobalState(Ok)
		}
	}
}

func getStatusMenuTitle(status *dockerStatus) string {
	if !status.isDockerReachable {
		return "Docker is stopped"
	}

	return "Docker is running"
}

func checkIfDockerIsReachable(ctx context.Context, cli *client.Client) bool {
	_, err := cli.Ping(ctx)
	if err != nil {
		log.Println("Error:", err)
		return false
	}
	return true
}

func checkSupervisorStatus(statusSubMenuItemMap *map[string]*systray.MenuItem, statusMenu *systray.MenuItem) {
	status, err := getStatus()

	if err != nil {
		log.Println(err)
	}

	if !strings.Contains(status, "supervisor.sock") && !strings.Contains(status, "error") {
		if len(*statusSubMenuItemMap) == 0 {
			for _, line := range strings.Split(status, "\n") {
				elements := strings.Fields(line)
				if len(elements) > 0 {
					item := statusMenu.AddSubMenuItem(getText(elements), "")
					item.Disable()
					(*statusSubMenuItemMap)[elements[0]] = item
				}
			}
		} else {
			for _, line := range strings.Split(status, "\n") {
				elements := strings.Fields(line)
				if len(elements) > 0 {
					(*statusSubMenuItemMap)[elements[0]].SetTitle(getText(elements))
				}
			}
		}
	} else {
		log.Println(status)
	}
}

func getStatus() (output string, err error) {
	bytes, err := exec.Command("docker-wsl", "status").Output()

	return string(bytes), err
}

func getText(elements []string) string {
	return elements[0] + ": " + strings.ToLower(elements[1])
}
