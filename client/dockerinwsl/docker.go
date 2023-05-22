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

var (
	ctx          context.Context = context.Background()
	dockerClient *client.Client
)

func init() {
	cli, err := client.NewClientWithOpts(client.WithHost("tcp://127.0.0.1:2375"), client.WithAPIVersionNegotiation())

	if err != nil {
		log.Fatal("Error:", err)
	}

	dockerClient = cli
}

func IsDockerReachable() (bool, error) {
	_, err := dockerClient.Ping(ctx)
	if err != nil {
		return false, err
	}
	return true, nil
}

func (c WslContext) startCheckDockerStatusLoop() {
	ticker := time.NewTicker(10 * time.Second)

	go func() {
		for ; true; <-ticker.C {
			reachable, err := IsDockerReachable()
			if err != nil {
				log.Println(err)
			}
			c.DockerStatus <- SocketStatus{
				IsReachable:        reachable,
				LastCheckTimestamp: time.Now().Unix(),
			}
		}
	}()
}
