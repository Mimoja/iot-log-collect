#!/usr/bin/env bash
# Read edge device journal logs from the journal-remote container
#
# Usage:
#   ./journal-read.sh                  # follow all edge device logs
#   ./journal-read.sh -n 100           # last 100 entries
#   ./journal-read.sh --list-hosts     # list all edge devices that have uploaded
#   ./journal-read.sh -h <hostname>    # follow logs from a specific host
#   ./journal-read.sh -- <args>        # pass arbitrary journalctl args
#
set -euo pipefail

COMPOSE_DIR="$(cd "$(dirname "$0")" && pwd)"
VOLUME="iot-log-collect_journal-remote-data"
JOURNAL_DIR="/var/log/journal/remote"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [-- JOURNALCTL_ARGS...]

Options:
    -f              Follow new entries (default if no other args)
    -n NUM          Show last NUM entries
    -h HOSTNAME     Filter by edge device hostname
    --list-hosts    List all edge devices that have uploaded logs
    --help          Show this help

Examples:
    $(basename "$0")                          # follow all logs
    $(basename "$0") -n 50                    # last 50 entries
    $(basename "$0") -h mydevice              # follow logs from 'mydevice'
    $(basename "$0") -n 20 -h mydevice        # last 20 from 'mydevice'
    $(basename "$0") -- -p err                # follow only error+ priority
    $(basename "$0") -- -o json               # output as JSON
EOF
    exit 0
}

list_hosts() {
    docker run --rm -v "${VOLUME}:${JOURNAL_DIR}:ro" \
        debian:bookworm-slim \
        bash -c "ls -1 ${JOURNAL_DIR}/ 2>/dev/null | sed 's/^remote-//;s/\.journal.*//'" | sort -u
    exit 0
}

FOLLOW=1
NUM=""
HOST=""
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)     usage ;;
        --list-hosts) list_hosts ;;
        -f)         FOLLOW=1; shift ;;
        -n)         NUM="$2"; FOLLOW=0; shift 2 ;;
        -h)         HOST="$2"; shift 2 ;;
        --)         shift; EXTRA_ARGS=("$@"); break ;;
        *)          EXTRA_ARGS+=("$1"); shift ;;
    esac
done

JOURNALCTL_ARGS=("-D" "${JOURNAL_DIR}")

if [[ -n "$HOST" ]]; then
    JOURNALCTL_ARGS+=("_HOSTNAME=${HOST}")
fi

if [[ -n "$NUM" ]]; then
    JOURNALCTL_ARGS+=("-n" "$NUM")
fi

if [[ $FOLLOW -eq 1 ]]; then
    JOURNALCTL_ARGS+=("-f")
fi

JOURNALCTL_ARGS+=("${EXTRA_ARGS[@]}")

exec docker run --rm -it \
    -v "${VOLUME}:${JOURNAL_DIR}:ro" \
    debian:bookworm-slim \
    bash -c "apt-get update -qq && apt-get install -y -qq --no-install-recommends systemd-journal-remote >/dev/null 2>&1 && journalctl ${JOURNALCTL_ARGS[*]}"
