#!/bin/bash

# <xbar.title>Ping Status</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.desc>Menu bar connection monitor. Colored dot + latency, packet loss in dropdown.</xbar.desc>
# <xbar.dependencies>ping</xbar.dependencies>

TARGET="8.8.8.8"
COUNT=5
TIMEOUT=5   # seconds for whole ping batch

# Run ping, capture output (stderr too)
OUT=$(ping -c "$COUNT" -t "$TIMEOUT" "$TARGET" 2>&1)

# Parse packet loss (e.g. "0.0% packet loss")
LOSS=$(echo "$OUT" | grep -oE '[0-9.]+% packet loss' | grep -oE '^[0-9.]+')

# Parse avg latency from "round-trip min/avg/max/stddev = 29.603/30.281/..."
STATS=$(echo "$OUT" | grep -E 'round-trip|min/avg/max')
AVG=$(echo "$STATS" | sed -E 's#.*= [0-9.]+/([0-9.]+)/.*#\1#')
MIN=$(echo "$STATS" | sed -E 's#.*= ([0-9.]+)/.*#\1#')
MAX=$(echo "$STATS" | sed -E 's#.*= [0-9.]+/[0-9.]+/([0-9.]+)/.*#\1#')

# Defaults if unreachable
[ -z "$LOSS" ] && LOSS="100"
DOWN=0
if [ -z "$AVG" ]; then
  DOWN=1
fi

# Round avg for display
if [ "$DOWN" -eq 0 ]; then
  AVG_INT=$(printf "%.0f" "$AVG")
fi

# Health rule: loss dominates latency
# loss>20% or down -> red ; loss>0 -> yellow ; else by latency
DOT="🟢"
if [ "$DOWN" -eq 1 ]; then
  DOT="🔴"
else
  LOSS_HIGH=$(awk -v l="$LOSS" 'BEGIN{print (l>20)?1:0}')
  LOSS_ANY=$(awk -v l="$LOSS" 'BEGIN{print (l>0)?1:0}')
  if [ "$LOSS_HIGH" -eq 1 ]; then
    DOT="🔴"
  elif [ "$LOSS_ANY" -eq 1 ]; then
    DOT="🟡"
  else
    if [ "$AVG_INT" -gt 150 ]; then
      DOT="🔴"
    elif [ "$AVG_INT" -gt 50 ]; then
      DOT="🟡"
    else
      DOT="🟢"
    fi
  fi
fi

NOW=$(date '+%H:%M:%S')

# --- Menu bar line (clean: dot + latency) ---
if [ "$DOWN" -eq 1 ]; then
  echo "🔴 down | font=Menlo"
else
  echo "$DOT ${AVG_INT}ms | font=Menlo"
fi

# --- Dropdown ---
echo "---"
echo "Target: $TARGET"
if [ "$DOWN" -eq 1 ]; then
  echo "Status: UNREACHABLE | color=red"
  echo "Packet loss: ${LOSS}%"
else
  echo "Latency avg: ${AVG_INT}ms"
  echo "Latency min/max: ${MIN}/${MAX} ms"
  echo "Packet loss: ${LOSS}%"
fi
echo "Packets: $COUNT"
echo "Last check: $NOW"
echo "---"
echo "Refresh now | refresh=true"
