#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# @title       Task3_pipes_redirection.sh
# @author      Agyekum-Boateng Owura Nyarko
# @index       7351023
# @school      Kwame Nkrumah University of Science and Technology (KNUST)
# @description Generates its own sample log data via a heredoc, then uses
#              pipes and standard text tools to compute line counts, per-level
#              counts, top IPs, and ERROR lines. Summary goes to results.txt,
#              pipeline errors go to errors.log.
# @date        2026-09-13
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0"
    echo "  Takes no arguments. Generates sample_log.txt, results.txt and errors.log"
    echo "  in the current directory."
    exit 1
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
fi

# This script deliberately takes no positional arguments, so any stray
# argument is treated as a usage mistake rather than silently ignored.
if [[ -n "$1" ]]; then
    echo "Error: this script does not accept arguments." >&2
    usage
fi

LOG_FILE="sample_log.txt"
RESULTS_FILE="results.txt"
ERRORS_FILE="errors.log"

# --- generate self-contained sample data (>=50 lines) via heredoc ---------
cat > "$LOG_FILE" <<'EOF'
2026-09-11 10:03:21 INFO 192.168.1.10 User login successful
2026-09-11 10:03:45 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:04:02 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:04:15 INFO 192.168.1.11 User login successful
2026-09-11 10:05:01 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:05:33 INFO 192.168.1.12 File uploaded
2026-09-11 10:06:00 WARN 192.168.1.10 CPU usage above 90%
2026-09-11 10:06:20 INFO 192.168.1.10 User logout
2026-09-11 10:07:11 ERROR 192.168.1.45 Authentication failed
2026-09-11 10:07:40 INFO 192.168.1.13 User login successful
2026-09-11 10:08:02 INFO 192.168.1.14 File downloaded
2026-09-11 10:08:30 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:09:00 WARN 192.168.1.11 Memory usage above 85%
2026-09-11 10:09:25 INFO 192.168.1.15 User login successful
2026-09-11 10:10:00 INFO 192.168.1.10 User login successful
2026-09-11 10:10:35 ERROR 192.168.1.45 Authentication failed
2026-09-11 10:11:02 INFO 192.168.1.16 File uploaded
2026-09-11 10:11:40 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:12:05 INFO 192.168.1.12 User logout
2026-09-11 10:12:50 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:13:10 INFO 192.168.1.17 User login successful
2026-09-11 10:13:44 INFO 192.168.1.10 File downloaded
2026-09-11 10:14:00 WARN 192.168.1.18 CPU usage above 90%
2026-09-11 10:14:35 ERROR 192.168.1.45 Authentication failed
2026-09-11 10:15:01 INFO 192.168.1.19 User login successful
2026-09-11 10:15:29 INFO 192.168.1.10 User logout
2026-09-11 10:16:00 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:16:31 WARN 192.168.1.11 Memory usage above 85%
2026-09-11 10:17:02 INFO 192.168.1.20 User login successful
2026-09-11 10:17:40 INFO 192.168.1.10 File uploaded
2026-09-11 10:18:05 ERROR 192.168.1.45 Authentication failed
2026-09-11 10:18:33 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:19:00 INFO 192.168.1.21 User login successful
2026-09-11 10:19:28 INFO 192.168.1.12 User logout
2026-09-11 10:20:00 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:20:45 INFO 192.168.1.10 File downloaded
2026-09-11 10:21:10 WARN 192.168.1.18 CPU usage above 90%
2026-09-11 10:21:39 INFO 192.168.1.22 User login successful
2026-09-11 10:22:00 ERROR 192.168.1.45 Authentication failed
2026-09-11 10:22:30 INFO 192.168.1.10 User logout
2026-09-11 10:23:00 WARN 192.168.1.11 Memory usage above 85%
2026-09-11 10:23:25 INFO 192.168.1.23 User login successful
2026-09-11 10:24:00 INFO 192.168.1.10 File uploaded
2026-09-11 10:24:35 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:25:00 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:25:31 INFO 192.168.1.24 User login successful
2026-09-11 10:26:00 INFO 192.168.1.12 User logout
2026-09-11 10:26:29 ERROR 192.168.1.45 Authentication failed
2026-09-11 10:27:00 INFO 192.168.1.10 File downloaded
2026-09-11 10:27:35 WARN 192.168.1.18 CPU usage above 90%
2026-09-11 10:28:00 INFO 192.168.1.25 User login successful
2026-09-11 10:28:30 ERROR 192.168.1.23 Connection timeout
EOF

if [[ $? -ne 0 ]]; then
    echo "Error: failed to generate sample log data." >&2
    exit 1
fi
echo "Generated sample log data in '$LOG_FILE' ($(wc -l < "$LOG_FILE") lines)."

# Start the results file fresh, and route only stderr from this point on
# into errors.log for the whole pipeline block below.
{
    echo "===== Log Analysis Report ====="
    echo "Generated: $(date)"
    echo

    # 1. total number of log lines
    echo "-- Total log lines --"
    wc -l < "$LOG_FILE"
    echo

    # 2. count of lines per log level
    # awk picks out the fixed log-level column (3rd field) rather than
    # grepping each level separately, so one pass covers all three.
    echo "-- Lines per log level --"
    awk '{print $3}' "$LOG_FILE" | sort | uniq -c | sort -rn
    echo

    # 3. top 3 most frequent IP addresses
    echo "-- Top 3 IP addresses --"
    awk '{print $4}' "$LOG_FILE" | sort | uniq -c | sort -rn | head -n 3
    echo

    # 4. all ERROR lines only
    echo "-- ERROR lines --"
    grep "ERROR" "$LOG_FILE"

} > "$RESULTS_FILE" 2> "$ERRORS_FILE"

PIPELINE_STATUS=$?
if [[ $PIPELINE_STATUS -eq 0 ]]; then
    echo "Analysis complete. Summary written to '$RESULTS_FILE'."
else
    echo "Error: one or more commands in the analysis pipeline failed; see '$ERRORS_FILE'." >&2
    exit 1
fi

echo "Task 3 completed successfully."
exit 0
