#!/bin/bash

LOGFILE="/var/log/monitoring.log"
STATEFILE="/var/run/test-monitor.pid"
URL="https://test.com/monitoring/test/api"
SERVICE="test-monitor.service"

touch "$LOGFILE"

while true; do
    PID=$(systemctl show -p MainPID --value "$SERVICE")

    if [[ "$PID" != "0" ]]; then
        LASTPID=""
        [[ -f "$STATEFILE" ]] && LASTPID=$(cat "$STATEFILE")

        if [[ "$LASTPID" != "" && "$LASTPID" != "$PID" ]]; then
            echo "$(date '+%F %T') | Service $SERVICE restarted (old pid=$LASTPID, new pid=$PID)" >> "$LOGFILE"
        fi

        echo "$PID" > "$STATEFILE"

        STATUS_HTTP=$(curl -s -k -o /dev/null -m 10 --connect-timeout 5 -w "%{http_code}" "$URL")
        if [[ ! "$STATUS_HTTP" =~ ^[23] ]]; then
            echo "$(date '+%F %T') | Monitoring server $URL is not available (HTTP $STATUS_HTTP)" >> "$LOGFILE"
        fi
    fi

    sleep 60
done
