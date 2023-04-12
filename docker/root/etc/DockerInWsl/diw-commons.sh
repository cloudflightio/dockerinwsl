#!/bin/bash

set -eo pipefail
TMP_DIW_CALLEDUTIL="$0"
DIW_CALLEDUTIL=$(cd "$(dirname -- "${TMP_DIW_CALLEDUTIL}")" >/dev/null; pwd -P)/$(basename -- "${TMP_DIW_CALLEDUTIL}")
DIW_CALLEDUTIL_PLUGIN=$(printf "${DIW_CALLEDUTIL}" | sed 's/\//_/g')

_errors=()

log() {
  echo "[$(date -Ins)] $*"
}

log_error() {
  msg="[$(date -Ins)] $*"
  _errors+=("$msg")
  >&2 echo "$msg"
}

die_on_errors() {
  [ ${#_errors[@]} -eq 0 ] || exit 1
}

### common vars
CMDSHELL="$(command -v cmd.exe || echo '/mnt/c/Windows/system32/cmd.exe')"
PROGRAMFILES="$(wslpath "$($CMDSHELL /V:OFF /C 'echo %PROGRAMFILES%' | tr -d '\n\r')")"
APPDATA="$(wslpath "$($CMDSHELL /V:OFF /C 'echo %APPDATA%' | tr -d '\n\r')")"
LOCALAPPDATA="$(wslpath "$($CMDSHELL /V:OFF /C 'echo %LOCALAPPDATA%' | tr -d '\n\r')")"

DIW_USER="docker"
DIW_LINUSER_HOME="/home/${DIW_USER}"
DIW_WINUSER_HOME="$(wslpath "$($CMDSHELL /V:OFF /C 'echo %USERPROFILE%' | tr -d '\n\r')")"
DIW_WINUSER_BINDDIRS=(".docker")
DIW_CONFIGDIR="${APPDATA}/DockerInWsl/config"
DIW_PLUGINDIR="${APPDATA}/DockerInWsl/plugin"
DIW_DRIVERDIR="${LOCALAPPDATA}/DockerInWsl/driver"
DIW_VARLIBDOCKER_SRC="/mnt/wsl/clf_dockerinwsl"
DIW_VARLIBDOCKER_DST="/var/lib/docker"
DIW_CALLEDUTIL_PLUGIN="${DIW_PLUGINDIR}/${DIW_CALLEDUTIL_PLUGIN}"

### common used init stuff
test -d "${DIW_CONFIGDIR}" || mkdir -p "${DIW_CONFIGDIR}"
test -d "${DIW_PLUGINDIR}" || mkdir -p "${DIW_PLUGINDIR}"

### init plugin hooks and lateron source plugin
_diw_plugin_globalvars() { :; }
_diw_plugin_mainloop() { :; }
test -f "${DIW_CALLEDUTIL_PLUGIN}" && . "${DIW_CALLEDUTIL_PLUGIN}"

### common functions
install_config() {
    src="$1"     # remote  e.g. "${APPDATA}/DockerInWsl/config/daemon.json"
    dst="$2"     # local   e.g. "/etc/docker/daemon.json"
    default="$3" # default e.g. "/etc/DockerInWsl/default-docker-daemon.json"

    tmp_file="/tmp/$(echo "$dst" | tr '/' '_')"

    [ -f "$tmp_file" ] || touch "$tmp_file"

    if [ ! -f "$dst" ] || [ ! -f "$src"  ] || [ ! -s "$src" ]; then
        log "config missing ($dst or $src) or empty"

        if [ ! -f "$dst" ]; then
            log "local config ($dst) does not exists => creating folder"
            mkdir -p "$(dirname "$dst")"
        fi

        if [ ! -f "$src" ] && [ -f "$dst" ]; then
            log "local config ($dst) exists but remote ($src) does not => move"
            cp "$dst" "$src"
            rm "$dst"
        fi

        if [ ! -f "$src" ]; then
            log "remote config ($src) does not exists => creating folder and copying from default file"   
            mkdir -p "$(dirname "$src")"
            cp "$default" "$src"
        elif [ ! -s "$src" ]; then
            log "remote config ($src) is empty => filling with default file"
            cat "$default" > "$src"
        fi

        log "update local config link ($src => $dst)"
        ln -sf "$src" "$dst"
    elif [ "$src" -nt "$tmp_file" ]; then
        echo "$(stat -c %y "$src") -nt $(stat -c %y "$tmp_file")"
        if [ "${src: -5}" == ".json" ]; then
            log "remote config updated => merging defaults"
            if ! jq empty < "$src"; then return; fi
            jq --argjson existing "$(<"$src")" ' . * $existing' "$default" > "$tmp_file"
            cp -f "$tmp_file" "$src"
            sleep 1
            touch "$tmp_file"
        fi
    fi
}

hash () {
    md5sum "$1" | awk '{ print $1 }'
}

install_file () {
    src="$1"
    dst="$2"
    src_filename="$(basename "$1")"

    if [ -f "$src" ]; then
        if [ ! -f "$dst" ]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
            log "copied $src_filename to $dst"
        else
            if [ "$(hash "$src")" != "$(hash "$dst")" ]; then
                cp -f "$src" "$dst"
                log "updated $src_filename at $dst"
            fi
        fi
    fi
    if [ ! -f "$dst" ]; then
        log "$1 not found at $dst"
        exit 1
    fi
}

_exec_wsl () {
    /mnt/c/Windows/system32/wsl.exe "$@"
}

exec_wsl () {
    _exec_wsl -d clf_dockerinwsl "$@"
}

exec_wsl_root () {
    exec_wsl -u root "$@"
}

exec_wsl_data () {
    _exec_wsl -d dockerinwsl_data "$@"
}

exec_wsl_data_root () {
    exec_wsl_data -u root "$@"
}

get_interface_ip () {
    ip -o -f inet addr show "$1" | awk '/scope global/ {print $4}' | head -n1 | cut -d'/' -f1
}

cidr_to_netmask() {
    value="$(( 0xffffffff ^ (1 << (32 - $1)) - 1 ))"
    echo "$(( (value >> 24) & 0xff )).$(( (value >> 16) & 0xff )).$(( (value >> 8) & 0xff )).$(( value & 0xff ))"
}

get_interface_cidr () {
    ip -o -f inet addr show "$1" | awk '/scope global/ {print $4}' | head -n1 | cut -d'/' -f2
}

get_interface_subnet () {
    cidr_to_netmask "$(get_interface_cidr "$1")"
}

get_interface_gateway_ip () {
    interface_ip=$(get_interface_ip "$1")
    interface_sn=$(get_interface_subnet "$1")
    IFS=. read -r i1 i2 i3 i4 <<< "$interface_ip"
    IFS=. read -r m1 m2 m3 m4 <<< "$interface_sn"
    echo "$i4 $m4" > /dev/null
    printf "%d.%d.%d.1\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))"
}
