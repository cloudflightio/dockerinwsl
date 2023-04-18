package DockerInWsl

type WslContext struct {
	SystemStatus chan SystemStatus
	DockerStatus chan SocketStatus
}

func NewWslContext() (*WslContext, error) {
	context := WslContext{
		SystemStatus: make(chan SystemStatus),
		DockerStatus: make(chan SocketStatus),
	}

	return &context, nil
}

type SystemStatus struct {
	DockerSocketStatus SocketStatus
	DockerStatus       ComponentStatus `serviceName:"docker.service" displayName:"docker"`
	VpnkitStatus       ComponentStatus `serviceName:"vpnkit.service" displayName:"vpnkit"`
	ChronyStatus       ComponentStatus `serviceName:"chrony.service" displayName:"chrony"`
	ContainerdStatus   ComponentStatus `serviceName:"containerd.service" displayName:"containerd"`
	DnsmasqStatus      ComponentStatus `serviceName:"dnsmasq.service" displayName:"dnsmasq"`
	lastCheckTimestamp int64
}

func (c WslContext) Start() {
	c.startCheckSystemStatusLoop()
	c.startCheckDockerStatusLoop()
}
