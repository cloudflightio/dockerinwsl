package main

import (
	"github.com/cloudflightio/dockerinwsl/gui/cmd"
	DockerInWsl "github.com/cloudflightio/dockerinwsl/gui/dockerinwsl"
)

func main() {
	ctx := DockerInWsl.NewWslContext()
	cmd.Execute(ctx)
}
