#!/bin/bash

set -eo pipefail
TMP_DIW_CALLEDUTIL="$0"
DIW_CALLEDUTIL=$(cd "$(dirname -- "${TMP_DIW_CALLEDUTIL}")" >/dev/null; pwd -P)/$(basename -- "${TMP_DIW_CALLEDUTIL}")
DIW_CALLEDUTIL_PLUGIN=$(printf "${DIW_CALLEDUTIL}" | sed 's/\//_/g')

log() {
  echo "[$(date -Ins)] $*"
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
            jq --argjson existing "$(<"$src")" ' . * $existing' "$default" > "$tmp_file"
            cp -f "$tmp_file" "$src"
            sleep 1
            touch "$tmp_file"
        fi
    fi
}
