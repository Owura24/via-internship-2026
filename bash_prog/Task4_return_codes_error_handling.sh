#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# @title       Task4_return_codes_error_handling.sh
# @author      Agyekum-Boateng Owura Nyarko
# @index       7351023
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Runs four disciplined checks (host reachability, free disk
#              space, config file readability, required tool installed),
#              each validated by a check_status helper that logs pass/fail
#              and exits with a documented code on failure. Cleans up temp
#              files on any exit via trap.
# @date        2026-09-13
#
# Exit codes:
#   0 = all checks passed
#   1 = missing required argument
#   2 = host unreachable
#   3 = insufficient disk space
#   4 = required config file not found/readable
#   5 = required command not found
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 <hostname>"
    echo "  <hostname>  host to ping-check as part of the health checks"
    exit 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

if [[ -z "$1" ]]; then
    echo "Error: missing required <hostname> argument." >&2
    exit 1
fi

HOSTNAME_TO_CHECK="$1"
CONFIG_FILE="/etc/hosts"          # a file that should always exist/be readable
REQUIRED_TOOL="awk"
MIN_FREE_DISK_KB=1048576          # 1 GB, in KB, as reported by df
TMP_FILE=$(mktemp) || { echo "Error: could not create temp file." >&2; exit 1; }

# --- cleanup on any exit (success, failure, or Ctrl+C) ---------------------
cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT INT TERM

# --- helper: log pass/fail for a check and exit with its code on failure ---
# Takes: $1 = result code from the check (usually $?), $2 = description,
#        $3 = exit code to use if the check failed.
check_status() {
    local result="$1"
    local description="$2"
    local fail_exit_code="$3"

    if [[ "$result" -eq 0 ]]; then
        echo "[PASS] $description"
    else
        echo "[FAIL] $description" >&2
        exit "$fail_exit_code"
    fi
}

echo "Running health checks for host '$HOSTNAME_TO_CHECK'..." | tee -a "$TMP_FILE"

# 1. host reachable
ping -c 1 -W 2 "$HOSTNAME_TO_CHECK" > "$TMP_FILE" 2>&1
check_status $? "Host '$HOSTNAME_TO_CHECK' is reachable" 2

# 2. enough free disk space on root filesystem
# df -k gives KB values; awk pulls the "available" column of the second
# data line (the first line is the header).
FREE_KB=$(df -k / | awk 'NR==2 {print $4}')
if [[ -z "$FREE_KB" ]]; then
    echo "[FAIL] Could not determine free disk space" >&2
    exit 3
fi
[[ "$FREE_KB" -ge "$MIN_FREE_DISK_KB" ]]
check_status $? "At least $((MIN_FREE_DISK_KB / 1024)) MB free disk space on /" 3

# 3. required config file exists and is readable
[[ -f "$CONFIG_FILE" && -r "$CONFIG_FILE" ]]
check_status $? "Config file '$CONFIG_FILE' exists and is readable" 4

# 4. required command/tool installed
command -v "$REQUIRED_TOOL" > /dev/null 2>&1
check_status $? "Required tool '$REQUIRED_TOOL' is installed" 5

echo "All checks passed."
exit 0
