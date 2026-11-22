#!/bin/bash
REQ_WEIGHT=${1:-0}
SPOOLMAN_URL="http://10.4.10.235:7912"
MOONRAKER_URL="http://localhost:7125"

python3 - "$REQ_WEIGHT" "$SPOOLMAN_URL" "$MOONRAKER_URL" << 'EOF'
import sys, json, urllib.request, subprocess

req_weight = float(sys.argv[1])
spoolman_url = sys.argv[2]
moonraker_url = sys.argv[3]

def send_gcode(cmd):
    payload = json.dumps({"script": cmd})
    subprocess.Popen(
        ["curl", "-s", "-X", "POST", f"{moonraker_url}/printer/gcode/script",
         "-H", "Content-Type: application/json", "-d", payload],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )

with urllib.request.urlopen(f"{moonraker_url}/server/spoolman/status", timeout=3) as r:
    spool_id = json.loads(r.read().decode()).get("result", {}).get("spool_id")

if not spool_id:
    print("No active spool selected.")
    if req_weight > 0:
        send_gcode("_ABORT_SPOOL_CHECK MSG='Print aborted: No active Spoolman spool selected.'")
    sys.exit(0)

with urllib.request.urlopen(f"{spoolman_url}/api/v1/spool/{spool_id}", timeout=3) as r:
    rem_weight = float(json.loads(r.read().decode()).get("remaining_weight") or 0)

print(f"Active Spool #{spool_id} remaining weight: {rem_weight:.1f}g")

if req_weight > 0 and rem_weight < req_weight:
    msg = f"Print aborted: Not enough filament (need {req_weight:.1f}g, {rem_weight:.1f}g remaining)."
    send_gcode(f"_ABORT_SPOOL_CHECK MSG='{msg}'")
EOF
