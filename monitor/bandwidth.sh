#!/usr/bin/env bash

set -euo pipefail

run_speedtest() {
    speedtest-cli --csv
}

parse_result() {
    local result="$(cat)"
    local strip_to_int='s/([0-9])\..*/\1/'

    local latency_ms="$(echo "$result" | cut -d ',' -f 7 | sed -r "$strip_to_int")"
    local download_bits_sec="$(echo "$result" | cut -d ',' -f 8 | sed -r "$strip_to_int")"
    local upload_bits_sec="$(echo "$result" | cut -d ',' -f 9 | sed -r "$strip_to_int")"

    echo $latency_ms $(( download_bits_sec / 1024 )) $(( upload_bits_sec / 1024 ))
}

store_result() {
    local input="$(cat)"
    echo input is "$input"

    local latency
    local download
    local upload

    read -r latency download upload <<< "$input"

    local sql="insert into bandwidth_metric (source, latency_ms, download_mbs, upload_mbs) values ('speedtest', $latency, $download, $upload)"
    psql -c "$sql"
}

main() {
    local output=
    local status=0

    output="$(run_speedtest)" || status=$?

    if [ "$status" -ne 0 ]; then
        echo "null null null" | store_result
        exit 1
    fi

    echo "$output" | parse_result | store_result
}

main "$@"

