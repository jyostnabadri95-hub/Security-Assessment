#!/usr/bin/env sh
set -eu
docker compose --env-file .env exec -T suricata curl --fail --silent --show-error \
  --header 'Host: urlhaus-demo.local' http://demo-web/malware-demo >/dev/null
echo 'Generated a harmless HTTP request matching Suricata rule 1000001.'
