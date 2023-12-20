#!/usr/bin/env bash

set -euo pipefail

# a local address used to verify local network is up
LOCAL_ADDRESS="${MONITOR_LOCAL_ADDRESS?Provide single local address to ping}"
# list of addresses checked for network uptime and latency
PING_ADDRESSES="${MONITOR_LATENCY_ADDRESSES?Provide csv list of addresses to ping}"


dumb_ping() {
    local address="$1"
    ping -W 1 -c 1 "$address" 2>/dev/null
}
export -f dumb_ping

main() {
    say_info "Running latency monitoring..."
    check_local_up
    echo "$PING_ADDRESSES" | tr ',' '\n' | parallel -k check_remote_up
}

monitor_ping() {
    :
}

check_local_up() {
    if ! dumb_ping "$LOCAL_ADDRESS"; then
        say_err "Local ping $LOCAL_ADDRESS unsuccessful"
        handle_no_response "LAN"
        return 1
    fi
}

check_remote_up() {
    local address="$1"
    local output=

    output="$(dumb_ping "$address")"
    status=$?

    if [ "$status" -ne 0 ]; then
        handle_no_response "$address" 
        return 0
    fi

    echo "$output" \
        | grep 'time=' \
        | sed -r 's/.*time=([0-9]*).* .*/\1/' \
        | sed "s/^/$address /" \
        | store_result
}
export -f check_remote_up

store_result() {
    local input="$(cat)"
    local address
    local latency
    read -r address latency <<< "$input"
    
    local sql="insert into latency_metric (address, latency_ms) values ('$address', $latency);"
    psql -c "$sql"
}
export -f store_result

handle_no_response() {
    local address="$1"
    say_err "No response at $address"
    echo "$address" | sed "s/$/ null/" | store_result
}
export -f handle_no_response

say_info() {
  printf '%s\n' "$@" >&2
}
export -f say_info

say_err() {
  echo "ERROR: $*" >&2
}
export -f say_err

main "$@"
