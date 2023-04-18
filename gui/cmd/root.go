package cmd

import (
	DockerInWsl "github.com/cloudflightio/dockerinwsl/gui/dockerinwsl"
	"github.com/spf13/cobra"
)

var ctx *DockerInWsl.WslContext

var rootCmd = &cobra.Command{
	Use:   "docker-wsl",
	Short: "Docker in WSL2",
	Long:  `A simple docker-desktop replacement based on WSL2, ubuntu, docker-ce and wsl-vpnkit`,
}

var startCmd = &cobra.Command{
	Use:   "start",
	Short: "Start docker in wsl",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.Start()
	},
}

var stopCmd = &cobra.Command{
	Use:   "stop",
	Short: "Stop docker in wsl",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.Stop()
	},
}

var restartCmd = &cobra.Command{
	Use:   "restart",
	Short: "Restart docker in wsl",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.Restart()
	},
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Gets the status for all components and the docker-socket",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.Status()
	},
}

var testCmd = &cobra.Command{
	Use:   "test",
	Short: "",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.Test()
	},
}

var showLogsCmd = &cobra.Command{
	Use:   "show-logs",
	Short: "",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.ShowLogs()
	},
}

var showConfigCmd = &cobra.Command{
	Use:   "show-config",
	Short: "",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.ShowConfig()
	},
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "",
	RunE: func(cmd *cobra.Command, args []string) error {
		return ctx.Version()
	},
}

func Execute(context *DockerInWsl.WslContext) error {
	ctx = context
	return rootCmd.Execute()
}

func init() {
	rootCmd.AddCommand(startCmd)
	rootCmd.AddCommand(stopCmd)
	rootCmd.AddCommand(restartCmd)
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(testCmd)
	rootCmd.AddCommand(showLogsCmd)
	rootCmd.AddCommand(showConfigCmd)
	rootCmd.AddCommand(versionCmd)
}
