package menu

import (
	"context"
	"log"

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

func getUnitStatus(ctx context.Context, conn *dbus.Conn, unitNames []string) ([]dbus.UnitStatus, error) {
	return conn.ListUnitsByNamesContext(ctx, unitNames)
}
