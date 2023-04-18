package DockerInWsl

import (
	"context"
	"log"
	"time"

	"github.com/docker/docker/client"
)

type SocketStatus struct {
	IsReachable        bool
	LastCheckTimestamp int64
}

func checkIfDockerIsReachable(ctx context.Context, cli *client.Client) bool {
	_, err := cli.Ping(ctx)
	if err != nil {
		log.Println("Error:", err)
		return false
	}
	return true
}

func (c WslContext) startCheckDockerStatusLoop() {
	ctx := context.Background()
	ticker := time.NewTicker(10 * time.Second)

	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())

	if err != nil {
		log.Print("Error:", err)
	}

	defer cli.Close()

	if cli != nil {
		go func() {
			for ; true; <-ticker.C {
				c.DockerStatus <- SocketStatus{
					IsReachable:        checkIfDockerIsReachable(ctx, cli),
					LastCheckTimestamp: time.Now().Unix(),
				}
			}
		}()
	}
}
