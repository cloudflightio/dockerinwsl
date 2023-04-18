package DockerInWsl

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"syscall"

	"github.com/fatih/color"
)

const (
	DISTRONAME = "clf_dockerinwsl"
)

var (
	green  func(a ...interface{}) string
	yellow func(a ...interface{}) string
	red    func(a ...interface{}) string
)

func init() {
	green = color.New(color.FgGreen).SprintFunc()
	yellow = color.New(color.FgYellow).SprintFunc()
	red = color.New(color.FgRed).SprintFunc()
}

func (WslContext) Enter() error {
	cmd := exec.Command("cmd", "/C", "start", "docker-wsl", "enter")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd.Run()
}

func (WslContext) EnterRoot() error {
	cmd := exec.Command("cmd", "/C", "start", "docker-wsl", "enter-root")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd.Run()
}

func (WslContext) ShowLogs() error {
	cmd := exec.Command("powershell.exe", "-command", "Invoke-Item \\\\wsl$\\"+DISTRONAME+"\\var\\log")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd.Run()
}

func (WslContext) ShowConfig() error {
	cmd := exec.Command("powershell.exe", "-command", "Invoke-Item (Join-Path (Join-Path $env:APPDATA -ChildPath \"DockerInWsl\") -ChildPath \"config\")")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	return cmd.Run()
}

func (WslContext) Start() error {

	cmd := exec.Command("wsl.exe", "-d", DISTRONAME, "-u", "root", "/bin/bash", "-c", "echo ...")
	return cmd.Run()
}

func (WslContext) Stop() error {
	cmd := exec.Command("wsl", "--terminate", DISTRONAME)
	return cmd.Run()
}

func (c WslContext) Restart() error {
	if err := c.Stop(); err != nil {
		return err
	}
	if err := c.Start(); err != nil {
		return err
	}
	return nil
}

func (c WslContext) RestartAll() error {
	if err := c.Stop(); err != nil {
		return err
	}
	cmd := exec.Command("wsl", "--shutdown")
	if err := cmd.Run(); err != nil {
		return err
	}
	if err := c.Start(); err != nil {
		return err
	}
	return nil
}

func (WslContext) Restore() error {
	cmd := exec.Command("docker-wsl-control.ps1", "restore")
	return cmd.Run()
}

func (WslContext) Backup() error {
	cmd := exec.Command("docker-wsl-control.ps1", "backup")
	return cmd.Run()
}

func (WslContext) Version() error {
	cmd := exec.Command("powershell.exe", "-command", `Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall" | Get-ItemProperty | Where-Object { ($_.Publisher -match "cloudflight") -and ($_.DisplayName -match "DockerInWSL")} | Select-Object -ExpandProperty DisplayVersion`)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	out, err := cmd.Output()
	if err != nil {
		return err
	}
	fmt.Printf("%s", string(out))
	return nil
}

func (c WslContext) Status() error {
	dockerReachable, err := IsDockerReachable()
	if dockerReachable {
		fmt.Printf("%s\n", green("Docker is reachable"))
	} else {
		fmt.Printf("%s\n(%s)\n", red("Docker is NOT reachable!"), err)
	}
	fmt.Println()
	ctx := context.TODO()
	conn, err := newConnectionContext(ctx)
	if err != nil {
		fmt.Printf("%s\n(%s)\n", red("could not connect to DockerInWsl systemd!"), err)
		return nil
	}
	cs, err := GetComponentStatus(ctx, conn)
	if err != nil {
		fmt.Printf("%s\n(%s)\n", "could not load component status!", err)
		return nil
	}
	for _, status := range cs {
		var stateColor *func(a ...interface{}) string
		if status.ActiveState == "active" {
			stateColor = &green
		} else {
			stateColor = &yellow
		}
		fmt.Printf("%-30s %-10s   pid: %-4d uptime: %s\n", status.DisplayName, (*stateColor)(strings.ToUpper(status.ActiveState)), status.PID, status.GetUptime())
	}
	return nil
}
