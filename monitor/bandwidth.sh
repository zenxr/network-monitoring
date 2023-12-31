#!/usr/bin/env bash

set -euo pipefail

run_speedtest() {
    speedtest-cli --csv --secure
}

parse_result() {
    local result="$(cat)"
    local strip_to_int='s/([0-9])\..*/\1/'
    local latency_ms
    local download_bps
    local upload_bps

    latency_ms="$(echo "$result" | xsv select 6 | sed -r "$strip_to_int")"
    download_bps="$(echo "$result" | xsv select 7 | sed -r "$strip_to_int")"
    upload_bps="$(echo "$result" | xsv select 8 | sed -r "$strip_to_int")"
    say_info "Latency: $latency_ms, Download bps: $download_bps, Upload bps: $upload_bps"

    echo $latency_ms $(( download_bps / 1024 )) $(( upload_bps / 1024 ))
}

store_result() {
    local input="$(cat)"

    local latency
    local download
    local upload

    read -r latency download upload <<< "$input"

    local sql="insert into bandwidth_metric (source, latency_ms, download_kbs, upload_kbs) values ('speedtest', $latency, $download, $upload)"
    say_info "$sql"
    psql -c "$sql"
}

main() {
    say_info "Running bandwidth monitoring..."
    local output=
    local status=0

    output="$(run_speedtest)" || status=$?

    if [ "$status" -ne 0 ]; then
        say_err "Speedtest failed, storing failure..."
        echo "null null null" | store_result
        exit 1
    fi

    echo "$output" | parse_result | store_result
}

say_info() {
  printf '%s\n' "$@" >&2
}

say_err() {
  echo "ERROR: $*" >&2
}

main "$@"

