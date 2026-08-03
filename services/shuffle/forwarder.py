"""Forward selected Wazuh JSON alerts to a configured Shuffle webhook."""
import json
import os
import time
import urllib.error
import urllib.request

alert_file = os.getenv("ALERT_FILE", "/var/ossec/logs/alerts/alerts.json")
webhook = os.getenv("SHUFFLE_WEBHOOK_URL", "").strip()
rule_ids = {item.strip() for item in os.getenv("RULE_IDS", "100101,100111").split(",")}

if not webhook:
    print("SHUFFLE_WEBHOOK_URL is empty; alert forwarding is disabled", flush=True)

while not os.path.exists(alert_file):
    time.sleep(2)

with open(alert_file, encoding="utf-8") as stream:
    stream.seek(0, os.SEEK_END)
    while True:
        line = stream.readline()
        if not line:
            time.sleep(1)
            continue
        try:
            alert = json.loads(line)
            rule_id = str(alert.get("rule", {}).get("id", ""))
            if not webhook or rule_id not in rule_ids:
                continue
            body = json.dumps(alert).encode()
            request = urllib.request.Request(
                webhook, data=body, headers={"Content-Type": "application/json"}, method="POST"
            )
            with urllib.request.urlopen(request, timeout=10) as response:
                print(f"forwarded Wazuh rule {rule_id}: HTTP {response.status}", flush=True)
        except (json.JSONDecodeError, OSError, urllib.error.URLError) as error:
            print(f"forwarding error: {error}", flush=True)
