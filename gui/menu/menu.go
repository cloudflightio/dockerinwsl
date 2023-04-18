package menu

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"reflect"
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

type systemStatus struct {
	DockerStatus       ComponentStatus `serviceName:"docker.service" displayName:"docker"`
	VpnkitStatus       ComponentStatus `serviceName:"vpnkit.service" displayName:"vpnkit"`
	ChronyStatus       ComponentStatus `serviceName:"chrony.service" displayName:"chrony"`
	ContainerdStatus   ComponentStatus `serviceName:"containerd.service" displayName:"containerd"`
	DnsmasqStatus      ComponentStatus `serviceName:"dnsmasq.service" displayName:"dnsmasq"`
	CheckStatus        ComponentStatus `serviceName:"check.service" displayName:"check"`
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

	dockerStatusUpdate := startCheckDockerStatusLoop()
	componentsStatusUpdate := startCheckSystemStatusLoop()

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
		case dockerStatusReport := <-dockerStatusUpdate:
			updateDockerStatus(statusMenu, &dockerStatusReport)
		case componentsStatusReport := <-componentsStatusUpdate:
			updateSystemStatus(statusMenu, &statusSubMenuItemMap, &componentsStatusReport)
		}

		if cmd != nil {
			if err := cmd.Run(); err != nil {
				log.Println("Error:", err)
			}
		}
	}
}

func startCheckDockerStatusLoop() chan dockerStatus {
	dockerStatusUpdate := make(chan dockerStatus)
	ctx := context.Background()
	ticker := time.NewTicker(10 * time.Second)

	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())

	if err != nil {
		log.Println("Error:", err)
	}

	defer cli.Close()

	if cli != nil {
		go func() {
			for range ticker.C {
				dockerStatusUpdate <- dockerStatus{
					isDockerReachable:  checkIfDockerIsReachable(ctx, cli),
					lastCheckTimestamp: time.Now().Unix(),
				}
			}
		}()
	}

	return dockerStatusUpdate
}

func updateDockerStatus(statusMenu *systray.MenuItem, status *dockerStatus) {
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

func startCheckSystemStatusLoop() chan systemStatus {
	systemStatusUpdate := make(chan systemStatus)
	t := reflect.TypeOf(systemStatus{})
	unitFieldNames := make(map[string]string, t.NumField())
	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)

		tag := field.Tag.Get("serviceName")
		if tag == "" || tag == "-" {
			continue
		}
		unitFieldNames[tag] = field.Name
	}
	unitNames := make([]string, 0, len(unitFieldNames))
	for k := range unitFieldNames {
		unitNames = append(unitNames, k)
	}

	ctx := context.TODO()

	conn, err := NewConnectionContext(ctx)
	if err != nil {
		log.Println(err)
	}

	ticker := time.NewTicker(10 * time.Second)

	go func() {
		for range ticker.C {
			if conn == nil || !conn.Connected() {
				conn, err = NewConnectionContext(ctx)
				if err != nil {
					log.Println(err)
				}
			}
			componentStatus, err := GetComponentStatus(ctx, conn, unitNames)
			if err != nil {
				log.Println(err)
			}
			status := systemStatus{
				lastCheckTimestamp: time.Now().Unix(),
			}
			v := reflect.ValueOf(&status).Elem()
			for _, s := range componentStatus {
				field := v.FieldByName(unitFieldNames[s.Name])
				v2 := reflect.ValueOf(&s).Elem()
				field.Set(v2)
			}
			status.lastCheckTimestamp = time.Now().Unix()

			systemStatusUpdate <- status
		}
	}()

	return systemStatusUpdate
}

func updateSystemStatus(statusMenu *systray.MenuItem, statusSubMenuItemMap *map[string]*systray.MenuItem, status *systemStatus) {
	t := reflect.TypeOf(status).Elem()
	v := reflect.ValueOf(status).Elem()

	firstRun := len(*statusSubMenuItemMap) == 0

	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)
		serviceDisplayName := field.Tag.Get("displayName")
		if serviceDisplayName == "" || serviceDisplayName == "-" {
			continue
		}
		serviceStatus := v.Field(i).Interface().(ComponentStatus)

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

func getStatusMenuTitle(status *dockerStatus) string {
	if !status.isDockerReachable {
		return "Docker is unreachable!"
	}

	return "Docker is reachable"
}

func checkIfDockerIsReachable(ctx context.Context, cli *client.Client) bool {
	_, err := cli.Ping(ctx)
	if err != nil {
		log.Println("Error:", err)
		return false
	}
	return true
}
