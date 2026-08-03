#!/usr/bin/env sh
set -eu
mkdir -p services/demo/logs
printf '%s\n' "{\"name\":\"usb_inventory_linux\",\"hostIdentifier\":\"demo-endpoint\",\"calendarTime\":\"$(date -u '+%a %b %d %H:%M:%S %Y UTC')\",\"unixTime\":$(date +%s),\"action\":\"added\",\"columns\":{\"usb_address\":\"1\",\"usb_port\":\"2\",\"vendor\":\"Demo Unknown Vendor\",\"vendor_id\":\"1337\",\"model\":\"Unauthorized USB Storage\",\"model_id\":\"0001\",\"serial\":\"DEMO-UNAUTHORIZED-001\",\"removable\":\"1\"}}" >> services/demo/logs/osquery-results.log
echo 'Generated a harmless unauthorized-USB osquery event.'

