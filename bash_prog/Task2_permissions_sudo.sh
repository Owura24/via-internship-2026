#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# @title       Task2_permissions_sudo.sh
# @author      Agyekum-Boateng Owura Nyarko
# @index       7351023
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Reports a file's permissions (symbolic + numeric), changes
#              them with both numeric and symbolic chmod syntax, attempts a
#              chown only when run as root, then reports permissions again.
# @date        2026-09-13
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 <file-path>"
    echo "  <file-path>  path to an existing file whose permissions will be shown/changed"
    exit 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

if [[ -z "$1" ]]; then
    echo "Error: no file path supplied." >&2
    usage
fi

FILE_PATH="$1"

# Validate the target exists before touching it - no point reporting
# permissions on a file that isn't there.
if [[ ! -e "$FILE_PATH" ]]; then
    echo "Error: '$FILE_PATH' does not exist." >&2
    exit 1
fi

# --- helper: print symbolic + numeric permissions -------------------------
report_permissions() {
    local label="$1"
    # stat's format differs between GNU and BSD stat; GNU (%A/%a) is assumed
    # here since the TryHackMe/Linux target environment is GNU coreutils.
    local symbolic numeric
    symbolic=$(stat -c '%A' "$FILE_PATH" 2>/dev/null)
    numeric=$(stat -c '%a' "$FILE_PATH" 2>/dev/null)

    if [[ -z "$symbolic" || -z "$numeric" ]]; then
        echo "Error: could not stat '$FILE_PATH' to read permissions." >&2
        exit 1
    fi

    echo "$label permissions of '$FILE_PATH':"
    echo "  Symbolic: $symbolic"
    echo "  Numeric : $numeric"
}

# --- 1. report current permissions ----------------------------------------
report_permissions "Current"

# --- 2. change permissions: numeric then symbolic --------------------------
# Numeric form demonstrated first (explicit rw-r--r--), symbolic form second
# (adds execute for the owner) - kept as two separate, visible steps.
chmod 644 "$FILE_PATH"
if [[ $? -eq 0 ]]; then
    echo "Applied numeric chmod 644 to '$FILE_PATH'."
else
    echo "Error: numeric chmod on '$FILE_PATH' failed." >&2
    exit 1
fi

chmod u+x "$FILE_PATH"
if [[ $? -eq 0 ]]; then
    echo "Applied symbolic chmod u+x to '$FILE_PATH'."
else
    echo "Error: symbolic chmod on '$FILE_PATH' failed." >&2
    exit 1
fi

# --- 3. check for root/sudo, attempt chown if privileged -------------------
# id -u prints 0 only for the root user (or an effectively-root sudo run),
# so we branch on that rather than assuming chown will just work.
if [[ "$(id -u)" -eq 0 ]]; then
    chown "$(whoami)" "$FILE_PATH"
    if [[ $? -eq 0 ]]; then
        echo "Running as root: chown succeeded on '$FILE_PATH'."
    else
        echo "Running as root, but chown on '$FILE_PATH' failed." >&2
    fi
else
    echo "Not running as root/sudo - skipping chown step (requires root privileges)."
fi

# --- 4. report permissions again to show before/after ----------------------
report_permissions "Updated"

echo "Task 2 completed successfully."
exit 0
