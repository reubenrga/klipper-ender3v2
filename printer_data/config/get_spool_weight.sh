#!/bin/bash
SPOOLMAN_URL="http://10.4.10.235:7912"
MOONRAKER_URL="http://localhost:7125"

# Get active spool ID from Moonraker
SPOOL_ID=$(curl -s "$MOONRAKER_URL/server/spoolman/status" | jq -r '.result.spool_id')

if [ "$SPOOL_ID" == "null" ] || [ -z "$SPOOL_ID" ]; then
  echo "No active spool selected."
  exit 0
fi

# Fetch remaining weight from Spoolman
WEIGHT=$(curl -s "$SPOOLMAN_URL/api/v1/spool/$SPOOL_ID" | jq -r '.remaining_weight')
printf "Active Spool #%s remaining weight: %.1fg\n" "$SPOOL_ID" "$WEIGHT"
