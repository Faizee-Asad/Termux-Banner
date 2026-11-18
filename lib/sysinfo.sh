#!/usr/bin/env bash
# shellcheck shell=bash
# ---------------------------------------------------------------------------
#  Termux Banner Advanced :: lib/sysinfo.sh
#  Collects the widgets shown inside the info panel.
#  Every widget degrades gracefully when its tool is missing.
# ---------------------------------------------------------------------------

# tb_sys_getprop <prop>
tb_sys_getprop() {
    if tb_has getprop; then
        local v; v="$(getprop "$1" 2>/dev/null)"
        [[ -n "$v" && "$v" != "null" ]] && { printf '%s' "$v"; return 0; }
    fi
    return 1
}

# tb_sys_device
tb_sys_device() {
    local v
    v="$(tb_sys_getprop ro.product.manufacturer)" && [[ -n "$v" ]] && printf '%s ' "$v"
    v="$(tb_sys_getprop ro.product.model)" && [[ -n "$v" ]] && { printf '%s' "$v"; return 0; }
    if [[ -r /sys/devices/virtual/dmi/id/product_name ]]; then
        cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null
        return 0
    fi
    printf 'Linux'
}

# tb_sys_android
tb_sys_android() {
    local v
    v="$(tb_sys_getprop ro.build.version.release)" && [[ -n "$v" ]] && {
        printf 'Android %s' "$v"; return 0; }
    v="$(tb_sys_getprop ro.build.version.sdk)" && [[ -n "$v" ]] && {
        printf 'SDK %s' "$v"; return 0; }
    printf 'Linux'
}

# tb_sys_termux_version
tb_sys_termux_version() {
    local p
    for p in "$PREFIX/share/termux/VERSION" /data/data/com.termux/files/usr/share/termux/VERSION; do
        [[ -r "$p" ]] && { head -n1 "$p" 2>/dev/null; return 0; }
    done
    if tb_has termux-info; then
        termux-info 2>/dev/null | grep -i "version" | head -n1
        return 0
    fi
    printf '-'
}

# tb_sys_uptime
tb_sys_uptime() {
    local up=""
    if [[ -r /proc/uptime ]]; then
        local secs; secs="$(cut -d' ' -f1 /proc/uptime 2>/dev/null)"
        [[ "$secs" =~ ^[0-9]+$ ]] && up="$secs"
    fi
    if [[ -z "$up" ]] && tb_has uptime; then
        up="$(uptime -p 2>/dev/null || uptime 2>/dev/null | sed -E 's/.*up ([^,]*).*/\1/')"
    fi
    [[ -z "$up" ]] && { printf '-'; return 0; }
    if [[ "$up" =~ ^[0-9]+$ ]]; then
        local d=$(( up / 86400 )) h=$(( (up % 86400) / 3600 )) m=$(( (up % 3600) / 60 ))
        if (( d > 0 )); then printf '%dd %dh %dm' "$d" "$h" "$m"
        elif (( h > 0 )); then printf '%dh %dm' "$h" "$m"
        else printf '%dm' "$m"; fi
    else
        printf '%s' "$up"
    fi
}

# tb_sys_battery
tb_sys_battery() {
    local pct="" status=""
    if tb_has termux-battery-percentage; then
        pct="$(termux-battery-percentage 2>/dev/null)"
        status="$(termux-battery-status 2>/dev/null)"
    fi
    if [[ -z "$pct" && -r /sys/class/power_supply/battery/capacity ]]; then
        pct="$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)"
    fi
    [[ -z "$pct" ]] && { printf '-'; return 0; }
    [[ -z "$status" ]] && status="ok"
    printf '%s%% %s' "$pct" "$status"
}

# tb_sys_disk
tb_sys_disk() {
    local target="${PREFIX:-$HOME}"
    [[ -d "$target" ]] || target="/"
    local line
    line="$(df -h "$target" 2>/dev/null | tail -n1)"
    if [[ -z "$line" ]]; then printf '-'; return 0; fi
    local fs size used avail pct mount
    read -r fs size used avail pct mount <<< "$line"
    [[ -z "$avail" ]] && { printf '-'; return 0; }
    printf '%s free / %s' "$avail" "$size"
}

# tb_sys_ram
tb_sys_ram() {
    local line
    line="$(free -h 2>/dev/null | sed -n 's/^Mem:[[:space:]]*//p')"
    if [[ -n "$line" ]]; then
        local total used freec shared buffcache available
        read -r total used freec shared buffcache available <<< "$line"
        [[ -n "$available" ]] && { printf '%s / %s' "$available" "$total"; return 0; }
        [[ -n "$freec" ]] && { printf '%s / %s' "$freec" "$total"; return 0; }
    fi
    if [[ -r /proc/meminfo ]]; then
        local memtotal memavail
        memtotal="$(grep -m1 '^MemTotal:' /proc/meminfo | tr -dc '0-9')"
        memavail="$(grep -m1 '^MemAvailable:' /proc/meminfo | tr -dc '0-9')"
        if [[ -n "$memtotal" && -n "$memavail" ]]; then
            printf '%dM / %dM' $(( memavail / 1024 )) $(( memtotal / 1024 ))
            return 0
        fi
    fi
    printf '-'
}

# tb_sys_ip
tb_sys_ip() {
    local ip=""
    if tb_has ip; then
        ip="$(ip -4 addr show scope global 2>/dev/null | sed -n 's/.*inet \([0-9.]*\).*/\1/p' | head -n1)"
    fi
    if [[ -z "$ip" ]] && tb_has hostname; then
        ip="$(hostname -I 2>/dev/null | tr ' ' '\n' | head -n1)"
    fi
    [[ -z "$ip" ]] && { printf 'offline'; return 0; }
    printf '%s' "$ip"
}

# tb_sys_cpu
tb_sys_cpu() {
    local model=""
    if [[ -r /sys/devices/virtual/dmi/id/processor_name ]]; then
        model="$(cat /sys/devices/virtual/dmi/id/processor_name 2>/dev/null)"
    fi
    if [[ -z "$model" ]] && tb_has getprop; then
        model="$(getprop ro.soc.model 2>/dev/null)"
    fi
    if [[ -z "$model" ]] && tb_has uname; then
        model="$(uname -m 2>/dev/null)"
    fi
    [[ -z "$model" ]] && { printf '-'; return 0; }
    printf '%s' "$model"
}

# tb_sys_user
tb_sys_user() {
    printf '%s' "${USER:-${LOGNAME:-$(whoami 2>/dev/null || echo user)}}"
}

# tb_sys_host
tb_sys_host() {
    local h=""
    tb_has hostname && h="$(hostname 2>/dev/null)"
    [[ -z "$h" ]] && h="${PREFIX##*/}"
    printf '%s' "$h"
}

# tb_sys_shell
tb_sys_shell() {
    printf '%s' "${SHELL:-bash}"
}

# tb_sys_date
tb_sys_date() {
    date "+%a %d %b %Y" 2>/dev/null || printf '-'
}

# tb_sys_time
tb_sys_time() {
    date "+%H:%M:%S" 2>/dev/null || printf '-'
}

# tb_sys_pkg
tb_sys_pkg() {
    local n=0
    if tb_has pkg; then
        n="$(pkg list-installed 2>/dev/null | grep -c '^' )"
    fi
    (( n == 0 )) && { printf '-'; return 0; }
    printf '%s pkgs' "$n"
}

# ---------------------------------------------------------------------------
#  tb_sysinfo_widgets <comma separated list>
#  Emits one "LABEL|value" pair per line.
# ---------------------------------------------------------------------------
tb_sysinfo_widgets() {
    local list="${1:-host,device,android,uptime,battery,disk,ram}"
    local w label value
    local IFS=','
    for w in $list; do
        w="${w// /}"
        [[ -z "$w" ]] && continue
        case "$w" in
            user)     label="USER";    value="$(tb_sys_user)" ;;
            host)     label="HOST";    value="$(tb_sys_host)" ;;
            device)   label="DEVICE";  value="$(tb_sys_device)" ;;
            android)  label="ANDROID"; value="$(tb_sys_android)" ;;
            kernel)   label="KERNEL";  value="$(uname -r 2>/dev/null || printf '-')" ;;
            termux)   label="TERMUX";  value="$(tb_sys_termux_version)" ;;
            uptime)   label="UPTIME";  value="$(tb_sys_uptime)" ;;
            battery)  label="BATTERY"; value="$(tb_sys_battery)" ;;
            disk)     label="STORAGE"; value="$(tb_sys_disk)" ;;
            ram)      label="MEMORY";  value="$(tb_sys_ram)" ;;
            ip)       label="IP";      value="$(tb_sys_ip)" ;;
            cpu)      label="CPU";     value="$(tb_sys_cpu)" ;;
            shell)    label="SHELL";   value="$(tb_sys_shell)" ;;
            date)     label="DATE";    value="$(tb_sys_date)" ;;
            time)     label="TIME";    value="$(tb_sys_time)" ;;
            packages) label="PACKAGES";value="$(tb_sys_pkg)" ;;
            *)        continue ;;
        esac
        printf '%s|%s\n' "$label" "$value"
    done
}
