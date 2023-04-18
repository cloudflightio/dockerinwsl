package menu

import (
	"fmt"
	"log"
	"os/exec"
	"reflect"
	"syscall"
	"time"

	"fyne.io/systray"
	DockerInWsl "github.com/cloudflightio/dockerinwsl/gui/dockerinwsl"
	"github.com/cloudflightio/dockerinwsl/gui/icon"
)

const CMD_PATH = "C:\\Windows\\system32\\cmd.exe"

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
	var ic []byte
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
	statusSubMenuItemMap := make(map[string]*systray.MenuItem)
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

	ctx, err := DockerInWsl.NewWslContext()
	if err != nil {
		log.Fatal(err)
	}
	ctx.Start()

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
		case dockerStatusReport := <-ctx.DockerStatus:
			updateGlobalState(statusMenu, &dockerStatusReport)
		case componentsStatusReport := <-ctx.SystemStatus:
			updateSystemStatus(statusMenu, &statusSubMenuItemMap, &componentsStatusReport)
		}

		if cmd != nil {
			if err := cmd.Run(); err != nil {
				log.Println("Error:", err)
			}
		}
	}
}

func updateGlobalState(statusMenu *systray.MenuItem, status *DockerInWsl.SocketStatus) {
	currentTimestamp := time.Now().Unix()
	statusMenu.SetTitle(getStatusMenuTitle(status))
	if !status.IsReachable {
		setGlobalState(Error)
	} else if status.LastCheckTimestamp+30 < currentTimestamp {
		setGlobalState(Warn)
	} else {
		setGlobalState(Ok)
	}
}

func updateSystemStatus(statusMenu *systray.MenuItem, statusSubMenuItemMap *map[string]*systray.MenuItem, status *DockerInWsl.SystemStatus) {
	t := reflect.TypeOf(status).Elem()
	v := reflect.ValueOf(status).Elem()

	firstRun := len(*statusSubMenuItemMap) == 0

	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)
		serviceDisplayName := field.Tag.Get("displayName")
		if serviceDisplayName == "" || serviceDisplayName == "-" {
			continue
		}
		serviceStatus := v.Field(i).Interface().(DockerInWsl.ComponentStatus)

		text := fmt.Sprintf("%s is %s", serviceDisplayName, serviceStatus.ActiveState)

		if firstRun {
			item := statusMenu.AddSubMenuItem(text, "")
			item.Disable()
			(*statusSubMenuItemMap)[field.Name] = item
		} else {
			(*statusSubMenuItemMap)[field.Name].SetTitle(text)
		}
	}
}

func getStatusMenuTitle(status *DockerInWsl.SocketStatus) string {
	if !status.IsReachable {
		return "Docker is unreachable!"
	}

	return "Docker is reachable"
}
