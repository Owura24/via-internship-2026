#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# @title       Task1_file_handling.sh
# @author      Agyekum-Boateng Owura Nyarko
# @index       7351023
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Creates a target directory, writes/appends/reads a file in it,
#              backs it up, then deletes the original after confirming it
#              exists. Every step checks its own exit code before moving on.
# @date        2026-09-13
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 <target-directory>"
    echo "  <target-directory>  path to the directory this script will create/use"
    exit 1
}

# --- argument validation -----------------------------------------------
# We validate first because every later step depends on having a real
# directory to work inside. Failing fast here avoids confusing errors
# further down (e.g. "file not found" when really the arg was just missing).
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

if [[ -z "$1" ]]; then
    echo "Error: no target directory supplied." >&2
    usage
fi

TARGET_DIR="$1"
TARGET_FILE="$TARGET_DIR/notes.txt"
BACKUP_FILE="$TARGET_FILE.bak"

# --- 1. create directory if missing -------------------------------------
# mkdir -p is used so an already-existing directory is not an error; we
# check beforehand so we can tell the user which case actually happened.
if [[ -d "$TARGET_DIR" ]]; then
    echo "Directory '$TARGET_DIR' already existed."
else
    mkdir -p "$TARGET_DIR"
    if [[ $? -eq 0 ]]; then
        echo "Created directory '$TARGET_DIR'."
    else
        echo "Error: failed to create directory '$TARGET_DIR' (check permissions)." >&2
        exit 1
    fi
fi

# --- 2. create file and write content -----------------------------------
echo "Log created on $(date)" > "$TARGET_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error: could not write to '$TARGET_FILE'." >&2
    exit 1
fi
echo "Created file '$TARGET_FILE' with initial content."

# --- 3. append additional content ---------------------------------------
echo "Appended line at $(date)" >> "$TARGET_FILE"
if [[ $? -ne 0 ]]; then
    echo "Error: could not append to '$TARGET_FILE'." >&2
    exit 1
fi
echo "Appended additional content."

# --- 4. read and display file contents -----------------------------------
if [[ -r "$TARGET_FILE" ]]; then
    echo "----- Contents of $TARGET_FILE -----"
    cat "$TARGET_FILE"
    echo "-------------------------------------"
else
    echo "Error: '$TARGET_FILE' is not readable." >&2
    exit 1
fi

# --- 5. copy file to a .bak version ---------------------------------------
cp "$TARGET_FILE" "$BACKUP_FILE"
if [[ $? -eq 0 ]]; then
    echo "Backed up file to '$BACKUP_FILE'."
else
    echo "Error: backup of '$TARGET_FILE' failed." >&2
    exit 1
fi

# --- 6. delete original only after confirming it exists -------------------
# We re-check existence right before deleting (rather than trusting the
# earlier check) in case something else removed it in the meantime.
if [[ -f "$TARGET_FILE" ]]; then
    echo "About to delete '$TARGET_FILE' (backup already saved at '$BACKUP_FILE')."
    rm "$TARGET_FILE"
    if [[ $? -eq 0 ]]; then
        echo "Deleted original file '$TARGET_FILE'."
    else
        echo "Error: failed to delete '$TARGET_FILE'." >&2
        exit 1
    fi
else
    echo "Error: '$TARGET_FILE' no longer exists, nothing to delete." >&2
    exit 1
fi

echo "Task 1 completed successfully."
exit 0
