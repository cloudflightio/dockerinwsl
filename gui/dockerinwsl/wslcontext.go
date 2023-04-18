package DockerInWsl

import "reflect"

type WslContext struct {
	SystemStatus chan SystemStatus
	DockerStatus chan SocketStatus
}

func NewWslContext() *WslContext {
	context := WslContext{
		SystemStatus: make(chan SystemStatus),
		DockerStatus: make(chan SocketStatus),
	}

	return &context
}

func (c WslContext) StartChecks() {
	c.startCheckSystemStatusLoop()
	c.startCheckDockerStatusLoop()
}

type SystemStatus struct {
	DockerSocketStatus SocketStatus
	DockerStatus       ComponentStatus `serviceName:"docker.service" displayName:"docker"`
	VpnkitStatus       ComponentStatus `serviceName:"vpnkit.service" displayName:"vpnkit"`
	ChronyStatus       ComponentStatus `serviceName:"chrony.service" displayName:"chrony"`
	ContainerdStatus   ComponentStatus `serviceName:"containerd.service" displayName:"containerd"`
	DnsmasqStatus      ComponentStatus `serviceName:"dnsmasq.service" displayName:"dnsmasq"`
	RsyslogStatus      ComponentStatus `serviceName:"rsyslog.service" displayName:"rsyslog"`
	StartupStatus      ComponentStatus `serviceName:"startup.service" displayName:"startup"`
	lastCheckTimestamp int64
}

var (
	unitNames        []string
	unitFieldNames   map[string]string
	unitDisplayNames map[string]string
)

func init() {
	t := reflect.TypeOf(SystemStatus{})
	unitFieldNames = make(map[string]string, t.NumField())
	unitDisplayNames = make(map[string]string, t.NumField())
	for i := 0; i < t.NumField(); i++ {
		field := t.Field(i)

		tag := field.Tag.Get("serviceName")
		if tag == "" || tag == "-" {
			continue
		}
		unitFieldNames[tag] = field.Name
		unitDisplayNames[tag] = field.Tag.Get("displayName")
	}
	unitNames = make([]string, 0, len(unitFieldNames))
	for k := range unitFieldNames {
		unitNames = append(unitNames, k)
	}
}
