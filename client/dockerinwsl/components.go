package DockerInWsl

import (
	"context"
	"log"
	"reflect"
	"time"

	"github.com/coreos/go-systemd/v22/dbus"
	godbus "github.com/godbus/dbus/v5"
)

func newConnectionContext(ctx context.Context) (*dbus.Conn, error) {

	return dbus.NewConnection(func() (*godbus.Conn, error) {
		return dbusAnonymousAuthConnection(ctx, func(opts ...godbus.ConnOption) (*godbus.Conn, error) {
			return godbus.SystemBusPrivate(opts...)
		})
	})
}

func dbusAnonymousAuthConnection(ctx context.Context, createBus func(opts ...godbus.ConnOption) (*godbus.Conn, error)) (*godbus.Conn, error) {
	conn, err := createBus(godbus.WithContext(ctx))
	if err != nil {
		return nil, err
	}

	methods := []godbus.Auth{godbus.AuthAnonymous()}

	err = conn.Auth(methods)
	if err != nil {
		conn.Close()
		return nil, err
	}

	err = conn.Hello()
	if err != nil {
		conn.Close()
		return nil, err
	}

	return conn, nil
}

type ComponentStatus struct {
	Name               string
	DisplayName        string
	Description        string
	LoadState          string
	ActiveState        string
	SubState           string
	PID                uint32
	StartTimestamp     uint64
	ExitTimestamp      uint64
	LastCheckTimestamp int64
}

func GetComponentStatus(ctx context.Context, conn *dbus.Conn) ([]ComponentStatus, error) {
	unitStatus, err := conn.ListUnitsByNamesContext(ctx, unitNames)
	if err != nil {
		return nil, err
	}
	cs := make([]ComponentStatus, len(unitNames))
	for i, unit := range unitStatus {
		cs[i].Name = unit.Name
		cs[i].DisplayName = unitDisplayNames[unit.Name]
		cs[i].Description = unit.Description
		cs[i].LoadState = unit.LoadState
		cs[i].ActiveState = unit.ActiveState
		cs[i].SubState = unit.SubState

		props, err := conn.GetUnitTypePropertiesContext(ctx, unit.Name, "Service")
		if err != nil {
			return nil, err
		}

		cs[i].PID = props["MainPID"].(uint32)
		cs[i].StartTimestamp = props["ExecMainStartTimestamp"].(uint64)
		cs[i].ExitTimestamp = props["ExecMainExitTimestamp"].(uint64)
		cs[i].LastCheckTimestamp = time.Now().Unix()
	}
	return cs, nil
}

func getTimeFromUInt64Timestamp(timestamp uint64) time.Time {
	return time.Unix(int64(timestamp/1000/1000), 0)
}

func (cs *ComponentStatus) GetStartTime() time.Time {
	return getTimeFromUInt64Timestamp(cs.StartTimestamp)
}

func (cs *ComponentStatus) GetExitTime() time.Time {
	return getTimeFromUInt64Timestamp(cs.ExitTimestamp)
}

func (cs *ComponentStatus) GetUptime() time.Duration {
	return time.Since(cs.GetStartTime()).Truncate(time.Second)
}

func (c WslContext) startCheckSystemStatusLoop() {
	ctx := context.TODO()
	conn, err := newConnectionContext(ctx)
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(10 * time.Second)

	go func() {
		for ; true; <-ticker.C {
			if !conn.Connected() {
				conn, err = newConnectionContext(ctx)
				if err != nil {
					log.Println(err)
				}
			}
			componentStatus, err := GetComponentStatus(ctx, conn)
			if err != nil {
				log.Println(err)
			}
			status := SystemStatus{
				lastCheckTimestamp: time.Now().Unix(),
			}
			v := reflect.ValueOf(&status).Elem()
			for _, s := range componentStatus {
				field := v.FieldByName(unitFieldNames[s.Name])
				v2 := reflect.ValueOf(&s).Elem()
				field.Set(v2)
			}
			status.lastCheckTimestamp = time.Now().Unix()

			c.SystemStatus <- status
		}
	}()
}
