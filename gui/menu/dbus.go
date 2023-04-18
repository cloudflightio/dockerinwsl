package menu

import (
	"context"
	"log"
	"time"

	"github.com/coreos/go-systemd/v22/dbus"
	godbus "github.com/godbus/dbus/v5"
)

func NewConnectionContext(ctx context.Context) (*dbus.Conn, error) {

	return dbus.NewConnection(func() (*godbus.Conn, error) {
		return dbusAnonymousAuthConnection(ctx, func(opts ...godbus.ConnOption) (*godbus.Conn, error) {
			return godbus.SystemBusPrivate(opts...)
		})
	})
}

func NewRawConnectionContext(ctx context.Context) (*godbus.Conn, error) {
	conn, err := dbusAnonymousAuthConnection(ctx, func(opts ...godbus.ConnOption) (*godbus.Conn, error) {
		return godbus.SystemBusPrivate(opts...)
	})
	if err != nil {
		return nil, err
	}
	return conn, err
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

func getConnection(ctx context.Context) *dbus.Conn {
	conn, err := NewConnectionContext(ctx)
	if err != nil {
		log.Println(err)
	}
	return conn
}

type ComponentStatus struct {
	Name           string
	Description    string
	LoadState      string
	ActiveState    string
	SubState       string
	PID            uint32
	StartTimestamp uint64
	ExitTimestamp  uint64
}

func GetComponentStatus(ctx context.Context, conn *dbus.Conn, unitNames []string) ([]ComponentStatus, error) {
	unitStatus, err := conn.ListUnitsByNamesContext(ctx, unitNames)
	if err != nil {
		return nil, err
	}
	cs := make([]ComponentStatus, len(unitNames))
	for i, unit := range unitStatus {
		cs[i].Name = unit.Name
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
		cs[i].ExitTimestamp = props["ExecMainExitTimestamp"].(uint64) //time.Unix(int64(props["ExecMainExitTimestamp"].(uint64)), 0)
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
