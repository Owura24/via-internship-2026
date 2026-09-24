#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# @title       Task5_crud_app.sh
# @author      Agyekum-Boateng Owura Nyarko
# @index       7351023
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Menu-driven CRUD Todo List app. Stores records as pipe-
#              separated CSV (id|description|status|due_date) in data.txt
#              next to the script. Backs up data before destructive changes,
#              validates input, and never crashes on a missing record.
# @date        2026-09-13
#
# Exit codes:
#   0 = normal exit via menu
#   1 = usage/help requested or invalid invocation
# ---------------------------------------------------------------------------

DATA_FILE="$(dirname "$0")/data.txt"

usage() {
    echo "Usage: $0"
    echo "  Runs an interactive Todo List CRUD menu. Data is stored in '$DATA_FILE'."
    echo "  Options: -h, --help   show this message"
    exit 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# This script is interactive and takes no positional arguments.
if [[ -n "$1" ]]; then
    echo "Error: unexpected argument '$1'." >&2
    usage
fi

# Ensure the data file exists so read/list operations never fail just
# because nothing has been added yet.
touch "$DATA_FILE" 2>/dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: cannot create or access data file '$DATA_FILE'." >&2
    exit 1
fi

# --- helper: back up data file before any destructive operation -----------
backup_data() {
    cp "$DATA_FILE" "$DATA_FILE.bak" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        echo "Warning: could not create backup before this change." >&2
    fi
}

# --- helper: next available numeric ID -------------------------------------
next_id() {
    local last_id
    last_id=$(tail -n 1 "$DATA_FILE" 2>/dev/null | cut -d'|' -f1)
    if [[ -z "$last_id" || ! "$last_id" =~ ^[0-9]+$ ]]; then
        echo 1
    else
        echo $((last_id + 1))
    fi
}

# --- Create -----------------------------------------------------------------
add_task() {
    local description status due_date id

    read -r -p "Task description: " description
    if [[ -z "$description" ]]; then
        echo "Error: description cannot be empty. Task not added." >&2
        return 1
    fi

    read -r -p "Status (pending/done) [pending]: " status
    status="${status:-pending}"
    if [[ "$status" != "pending" && "$status" != "done" ]]; then
        echo "Error: status must be 'pending' or 'done'. Task not added." >&2
        return 1
    fi

    read -r -p "Due date (optional, YYYY-MM-DD): " due_date

    id=$(next_id)
    echo "${id}|${description}|${status}|${due_date}" >> "$DATA_FILE"
    if [[ $? -eq 0 ]]; then
        echo "Added task #$id."
    else
        echo "Error: failed to write new task to '$DATA_FILE'." >&2
        return 1
    fi
}

# --- Read (list all) ---------------------------------------------------------
list_tasks() {
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "No tasks yet."
        return 0
    fi
    printf "%-4s %-30s %-9s %-12s\n" "ID" "Description" "Status" "Due"
    while IFS='|' read -r id description status due_date; do
        printf "%-4s %-30s %-9s %-12s\n" "$id" "$description" "$status" "$due_date"
    done < "$DATA_FILE"
}

# --- Read (search) -----------------------------------------------------------
search_tasks() {
    local term
    read -r -p "Search term: " term
    if [[ -z "$term" ]]; then
        echo "Error: search term cannot be empty." >&2
        return 1
    fi

    local matches
    matches=$(grep -i -- "$term" "$DATA_FILE")
    if [[ -z "$matches" ]]; then
        echo "No matching tasks found for '$term'."
    else
        echo "$matches"
    fi
}

# --- find a record by id, used by update/delete -----------------------------
find_task_line() {
    local id="$1"
    grep "^${id}|" "$DATA_FILE"
}

# --- Update -------------------------------------------------------------------
update_task() {
    local id existing new_description new_status new_due_date

    read -r -p "ID of task to update: " id
    if [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: invalid ID." >&2
        return 1
    fi

    existing=$(find_task_line "$id")
    if [[ -z "$existing" ]]; then
        echo "Task #$id not found - nothing was changed."
        return 0
    fi

    backup_data

    IFS='|' read -r _ cur_description cur_status cur_due_date <<< "$existing"

    read -r -p "New description [$cur_description]: " new_description
    new_description="${new_description:-$cur_description}"

    read -r -p "New status (pending/done) [$cur_status]: " new_status
    new_status="${new_status:-$cur_status}"
    if [[ "$new_status" != "pending" && "$new_status" != "done" ]]; then
        echo "Error: status must be 'pending' or 'done'. Update cancelled." >&2
        return 1
    fi

    read -r -p "New due date [$cur_due_date]: " new_due_date
    new_due_date="${new_due_date:-$cur_due_date}"

    # Rewrite the file with the matching line replaced, everything else kept.
    local tmp_file
    tmp_file=$(mktemp) || { echo "Error: could not create temp file for update." >&2; return 1; }

    while IFS='|' read -r line_id line_description line_status line_due; do
        if [[ "$line_id" == "$id" ]]; then
            echo "${id}|${new_description}|${new_status}|${new_due_date}" >> "$tmp_file"
        else
            echo "${line_id}|${line_description}|${line_status}|${line_due}" >> "$tmp_file"
        fi
    done < "$DATA_FILE"

    mv "$tmp_file" "$DATA_FILE"
    if [[ $? -eq 0 ]]; then
        echo "Updated task #$id."
    else
        echo "Error: failed to save updated task #$id." >&2
        return 1
    fi
}

# --- Delete -------------------------------------------------------------------
delete_task() {
    local id existing confirm

    read -r -p "ID of task to delete: " id
    if [[ -z "$id" || ! "$id" =~ ^[0-9]+$ ]]; then
        echo "Error: invalid ID." >&2
        return 1
    fi

    existing=$(find_task_line "$id")
    if [[ -z "$existing" ]]; then
        echo "Task #$id not found - nothing was deleted."
        return 0
    fi

    read -r -p "Delete task #$id? This cannot be undone (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Delete cancelled."
        return 0
    fi

    backup_data

    grep -v "^${id}|" "$DATA_FILE" > "$DATA_FILE.tmp"
    if [[ $? -eq 0 ]]; then
        mv "$DATA_FILE.tmp" "$DATA_FILE"
        echo "Deleted task #$id."
    else
        echo "Error: failed to delete task #$id." >&2
        rm -f "$DATA_FILE.tmp"
        return 1
    fi
}

# --- main menu loop -------------------------------------------------------
main_menu() {
    local choice
    while true; do
        echo
        echo "===== Todo List ====="
        echo "1) Add task"
        echo "2) View/List tasks"
        echo "3) Search tasks"
        echo "4) Update task"
        echo "5) Delete task"
        echo "6) Exit"
        read -r -p "Choose an option [1-6]: " choice

        case "$choice" in
            1) add_task ;;
            2) list_tasks ;;
            3) search_tasks ;;
            4) update_task ;;
            5) delete_task ;;
            6) echo "Goodbye."; exit 0 ;;
            *) echo "Invalid option '$choice'. Please choose 1-6." >&2 ;;
        esac
    done
}

main_menu
