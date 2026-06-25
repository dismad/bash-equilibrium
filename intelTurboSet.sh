#!/bin/bash
# CPU Control Script: Turbo Boost + Governor + HT status (BIOS)

set -euo pipefail

TURBO_FILE="/sys/devices/system/cpu/intel_pstate/no_turbo"
SMT_ACTIVE="/sys/devices/system/cpu/smt/active"
GOVERNOR_FILE="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
AVAILABLE_GOVERNORS="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"

check_status() {
    echo "=== Current CPU Configuration ==="
    
    echo "Turbo Boost:"
    if [ -f "$TURBO_FILE" ]; then
        if [ "$(cat "$TURBO_FILE")" = "1" ]; then
            echo "   DISABLED (CPU capped at base frequency)"
        else
            echo "   ENABLED"
        fi
    else
        echo "   intel_pstate driver not available"
    fi

    echo "Hyper-Threading (BIOS controlled):"
    if [ -f "$SMT_ACTIVE" ]; then
        if [ "$(cat "$SMT_ACTIVE")" = "1" ]; then
            echo "   ENABLED"
        else
            echo "   DISABLED"
        fi
    else
        echo "   SMT status not available"
    fi

    echo "Logical CPUs online: $(nproc)"
    
    echo "Current governor: $(cat "$GOVERNOR_FILE" 2>/dev/null || echo 'unknown')"
    if [ -f "$AVAILABLE_GOVERNORS" ]; then
        echo "Available governors: $(cat "$AVAILABLE_GOVERNORS")"
    fi
    echo "================================="
}

toggle_turbo() {
    local state=$1  # 0=enable, 1=disable
    if [ -f "$TURBO_FILE" ]; then
        echo "$state" | sudo tee "$TURBO_FILE" > /dev/null
        echo "Turbo Boost $( [ "$state" = "1" ] && echo "disabled" || echo "enabled" )."
    else
        echo "Error: Turbo control not available."
    fi
}

set_governor() {
    local gov=$1
    if [ -f "$GOVERNOR_FILE" ]; then
        echo "$gov" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        echo "Governor set to '$gov' across all cores."
    else
        echo "Error: Governor control not available."
    fi
}

echo "CPU Turbo + Governor Control Script"
check_status

echo -e "\nOptions:"
echo "1) Disable Turbo Boost"
echo "2) Enable Turbo Boost"
echo "3) Set governor to 'performance'"
echo "4) Set governor to 'powersave'"
echo "5) Refresh status"
echo "q) Quit"

while true; do
    read -r -p "Choose [1-5/q]: " choice
    case "$choice" in
        1)
            toggle_turbo 1
            check_status
            ;;
        2)
            toggle_turbo 0
            check_status
            ;;
        3)
            set_governor "performance"
            check_status
            ;;
        4)
            set_governor "powersave"
            check_status
            ;;
        5)
            check_status
            ;;
        q|Q)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done