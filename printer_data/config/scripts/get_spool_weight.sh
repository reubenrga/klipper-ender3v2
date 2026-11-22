#!/bin/bash
REQ_WEIGHT=${1:-0}
SPOOLMAN_URL="http://10.4.10.235:7912"
MOONRAKER_URL="http://localhost:7125"

# Helper to send G-code back to Klipper via Moonraker
send_gcode() {
  curl -s -X POST "$MOONRAKER_URL/printer/gcode/script" \
    -H "Content-Type: application/json" \
    -d "{\"script\": \"$1\"}" > /dev/null
}

# Get active spool ID from Moonraker
SPOOL_ID=$(curl -s "$MOONRAKER_URL/server/spoolman/status" | jq -r '.result.spool_id')

if [ "$SPOOL_ID" == "null" ] || [ -z "$SPOOL_ID" ]; then
  echo "No active spool selected."
  # Only abort if a print actually requested a weight check (or always abort during START_PRINT)
  if [ "$(awk -v req="$REQ_WEIGHT" 'BEGIN { print (req > 0) ? 1 : 0 }')" -eq 1 ]; then
    send_gcode "_ABORT_SPOOL_CHECK MSG='Print aborted: No active Spoolman spool selected.'"
  fi
  exit 0
fi

# Fetch remaining weight from Spoolman
WEIGHT=$(curl -s "$SPOOLMAN_URL/api/v1/spool/$SPOOL_ID" | jq -r '.remaining_weight // 0')
printf "Active Spool #%s remaining weight: %.1fg\n" "$SPOOL_ID" "$WEIGHT"

# Compare required weight vs remaining weight
IS_ENOUGH=$(awk -v req="$REQ_WEIGHT" -v rem="$WEIGHT" 'BEGIN { print (req <= 0 || rem >= req) ? 1 : 0 }')

if [ "$IS_ENOUGH" -eq 0 ]; then
  MSG=$(printf "Print aborted: Not enough filament (need %.1fg, %.1fg remaining)." "$REQ_WEIGHT" "$WEIGHT")
  send_gcode "_ABORT_SPOOL_CHECK MSG='$MSG'"
fi
