package cmd

import (
	"github.com/cloudflightio/dockerinwsl/gui/menu"
	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(menuCmd)
}

var menuCmd = &cobra.Command{
	Use:   "menu",
	Short: "Starts systray menu",
	Long:  ``,
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx.Start()
		defer ctx.Stop()
		ctx.StartChecks()
		menu.StartMenu(ctx)
		return nil
	},
}
