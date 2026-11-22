#!/bin/bash
SPOOLMAN_URL="http://10.4.10.235:7912"
MOONRAKER_URL="http://localhost:7125"

SPOOL_ID=$(curl -s "$MOONRAKER_URL/server/spoolman/status" | jq -r '.result.spool_id')
WEIGHT=$(curl -s "$SPOOLMAN_URL/api/v1/spool/$SPOOL_ID" | jq -r '.remaining_weight // -1')

printf "Active Spool #%s remaining weight: %.1fg\n" "$SPOOL_ID" "$WEIGHT"
curl -s -X POST "$MOONRAKER_URL/printer/gcode/script?script=SAVE_VARIABLE%20VARIABLE=spool_weight%20VALUE=$WEIGHT" > /dev/null &
