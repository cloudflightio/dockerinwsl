package main

import (
	"fmt"
	"fyne.io/systray"
	"github.com/cloudflightio/dockerinwsl/gui/icon"
	"log"
	"os/exec"
	"strings"
	"time"
)

func main() {
	onExit := func() {
		now := time.Now()
		fmt.Println("Exit at", now.String())
	}

	systray.Run(onReady, onExit)
}

func onReady() {
	go buildMenu()
}

func buildMenu() {
	systray.SetTemplateIcon(icon.Data, icon.Data)
	systray.SetTitle("DockerInWsl")
	systray.SetTooltip("DockerInWsl")

	status := systray.AddMenuItem("status", "")
	systray.AddSeparator()

	go checkStatus(status)

	enter := systray.AddMenuItem("Enter", "")
	enterRoot := systray.AddMenuItem("Enter with root", "")
	showLogs := systray.AddMenuItem("Show logs", "")
	showConfig := systray.AddMenuItem("Show configs", "")
	advanced := systray.AddMenuItem("Advanced", "")
	restore := advanced.AddSubMenuItem("Restore", "")
	backup := advanced.AddSubMenuItem("Backup", "")
	systray.AddSeparator()
	restart := systray.AddMenuItem("Restart", "")
	restartAll := systray.AddMenuItem("Restart all", "")
	start := systray.AddMenuItem("Start", "")
	stop := systray.AddMenuItem("Stop", "")
	systray.AddSeparator()
	quit := systray.AddMenuItem("Quit", "")

	for {

		var cmd *exec.Cmd

		select {
		case <-quit.ClickedCh:
			systray.Quit()
		case <-enter.ClickedCh:
			cmd = exec.Command("cmd", "/C", "start", "docker-wsl enter")
		case <-enterRoot.ClickedCh:
			cmd = exec.Command("cmd", "/C", "start", "docker-wsl", "enter-root")
		case <-showLogs.ClickedCh:
			cmd = exec.Command("docker-wsl", "show-logs")
		case <-showConfig.ClickedCh:
			cmd = exec.Command("docker-wsl", "show-config")
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
		}

		if cmd != nil {
			if err := cmd.Run(); err != nil {
				log.Println("Error:", err)
			}
		}
	}
}

func checkStatus(statusMenu *systray.MenuItem) {
	ticker := time.NewTicker(5 * time.Second)

	subMenuMap := make(map[string]*systray.MenuItem)
	handleStatusSubMenu(&subMenuMap, statusMenu)

	for range ticker.C {
		handleStatusSubMenu(&subMenuMap, statusMenu)
	}
}

func getStatus() (output string, err error) {
	bytes, err := exec.Command("docker-wsl", "status").Output()

	return string(bytes), err
}

func handleStatusSubMenu(subMenuMap *map[string]*systray.MenuItem, statusMenu *systray.MenuItem) {
	status, err := getStatus()

	if err != nil {
		log.Println(err)
		statusMenu.SetTitle("Stopped")
		return
	}

	if !strings.Contains(status, "supervisor.sock") && !strings.Contains(status, "error") {
		statusMenu.SetTitle("Running")
		if len(*subMenuMap) == 0 {
			for _, line := range strings.Split(status, "\n") {
				elements := strings.Fields(line)
				if len(elements) > 0 {
					item := statusMenu.AddSubMenuItem(getText(elements), "")
					item.Disable()
					(*subMenuMap)[elements[0]] = item
				}
			}
		} else {
			for _, line := range strings.Split(status, "\n") {
				elements := strings.Fields(line)
				if len(elements) > 0 {
					(*subMenuMap)[elements[0]].SetTitle(getText(elements))
				}
			}
		}
	} else {
		statusMenu.SetTitle("Stopped")
	}
}

func getText(elements []string) string {
	return elements[0] + ": " + strings.ToLower(elements[1])
}
