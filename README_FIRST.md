Below is a beginner-friendly runbook for a 5–10 minute local demonstration. You can read the quoted portions almost word-for-word.

# 1. What you built

This project is a small Security Operations Center, or SOC, running in Docker.

The components are:

| Component | Purpose |
|---|---|
| Wazuh Manager | Receives endpoint events, applies detection rules, and creates alerts |
| Wazuh Indexer | Database that stores and searches Wazuh alerts |
| Wazuh Dashboard | Web interface for agents, alerts, FIM, and inventory |
| Wazuh Agent | Represents a monitored Linux endpoint |
| osquery | Collects information such as connected USB devices |
| Suricata | Inspects network traffic and detects suspicious requests |
| Shuffle | Automates responses such as ticket creation and email |
| Demo web server | Harmless internal target used to trigger Suricata |

The simple data flow is:

```text
osquery ─┐
         ├─> Wazuh Agent ─> Wazuh Manager ─> Indexer ─> Dashboard
Suricata ┘                         │
                                  └─> Shuffle ─> Ticket + Email
```

# 2. What to read before the demo

Read these in this order:

1. [README.md](/Users/krish/projects/security-assessment/README.md)
2. [Architecture](/Users/krish/projects/security-assessment/docs/ARCHITECTURE.md)
3. [Demo guide](/Users/krish/projects/security-assessment/docs/DEMO.md)
4. [Security recommendations](/Users/krish/projects/security-assessment/docs/SECURITY.md)

You do not need to understand every Wazuh or Docker setting. Focus on:

- What each component does
- How events flow through the system
- Why only local UI ports are published
- How each demonstration creates a harmless event
- Docker Desktop limitations for physical USB and network capture

# 3. Important URLs and credentials

Wazuh:

```text
URL: https://localhost:8443
Username: admin
Password: SecretPassword
```

If you changed `WAZUH_INDEXER_PASSWORD` in `.env`, use that password.

Shuffle:

```text
URL: http://localhost:3001
```

Shuffle has no default UI account. The first registered user becomes the initial administrator.

The browser warning on the Wazuh URL is expected because the demo uses a locally generated, self-signed TLS certificate.

# 4. Preparation before presenting

Start the stack at least five minutes before the demonstration:

```sh
cd /Users/krish/projects/security-assessment
task up
```

Check the containers:

```sh
task status
```

You want the important containers to say `Up`:

```text
wazuh.indexer
wazuh.manager
wazuh.dashboard
wazuh.agent
suricata
osquery
shuffle-backend
shuffle-frontend
```

Check that Wazuh responds:

```sh
curl -k -I https://localhost:8443
```

A `302` response is normal—it redirects to the login page.

Open Wazuh and confirm the API is online:

1. Log in.
2. Open the menu in the upper-left.
3. Go to **Server management → Dev Tools** or **Server APIs**.
4. Confirm the API connection shows **Online**.

Confirm the agent:

1. Open **Agents management → Summary**.
2. Find `demo-endpoint`.
3. Confirm its status is **Active**.

If the agent has just started, allow approximately one minute for it to appear.

# 5. Clean demonstration setup

Before presenting, open these windows:

- Wazuh Dashboard: `https://localhost:8443`
- Shuffle: `http://localhost:3001`
- A terminal in the project directory
- [Architecture](/Users/krish/projects/security-assessment/docs/ARCHITECTURE.md)

In Wazuh, locate **Threat hunting** or **Security events**. The precise menu wording may vary slightly.

Set the time range to something recent:

```text
Last 15 minutes
```

Do not run `task demo:all` too early. Generate each event separately during the presentation so the audience can see cause and effect.

# 6. Suggested presentation script

## Minute 0–1: Introduction

Say:

> This is an integrated open-source security operations proof of concept for a fintech organization with Windows and Linux endpoints. It combines endpoint monitoring, file integrity monitoring, USB detection, network intrusion detection, centralized dashboards, and automated incident response.

> Everything runs locally in Docker. The services communicate over a dedicated Docker bridge network. The Wazuh and Shuffle user interfaces are bound to localhost, while the manager, indexer, sensors, and databases are not published to the host network.

Show the architecture diagram.

Explain:

- The endpoint sends events to Wazuh Manager.
- Wazuh applies rules.
- The indexer stores the alerts.
- The Dashboard presents them.
- Selected alerts can be forwarded to Shuffle.
- Shuffle can enrich them and create tickets or emails.

## Minute 1–2: Docker architecture

Run:

```sh
task status
```

Say:

> Each service has its own configuration directory. The root Compose file includes those service definitions and puts them on one Docker bridge network.

Optionally show the network:

```sh
docker network inspect security-assessment-net
```

Explain that `expose` makes ports available only between containers, while `ports` publishes them to the host.

The published UI bindings are:

```text
127.0.0.1:8443 → Wazuh Dashboard
127.0.0.1:3001 → Shuffle development UI
```

Say:

> Binding to 127.0.0.1 prevents other machines on the network from directly accessing these demonstration interfaces.

## Minute 2–3: Endpoint detection and inventory

In Wazuh:

1. Open **Agents management → Summary**.
2. Select `demo-endpoint`.
3. Show that it is active.
4. Show inventory sections such as operating system, network interfaces, packages, processes, or hardware.

Say:

> This container represents a Linux endpoint. The Wazuh agent enrolls with the manager, sends security events, performs system inventory, and monitors protected directories.

# 7. FIM/DLP demonstration

FIM means File Integrity Monitoring. It detects files being created, modified, or deleted.

Run:

```sh
task demo:fim
```

The script:

1. Creates a synthetic finance CSV file.
2. Modifies it.
3. Deletes it.

It does not touch real financial or HR data.

Say:

> I am simulating changes to a protected Finance document. The endpoint monitors Finance, HR, and Confidential directories in real time.

Wait approximately 30–60 seconds.

In Wazuh:

1. Open the `demo-endpoint` agent.
2. Open **File Integrity Monitoring**.
3. Set the time range to **Last 15 minutes**.
4. Refresh.

Look for paths containing:

```text
/demo/finance
```

You should see creation, modification, or deletion events.

If using Threat Hunting, search for:

```text
rule.groups:syscheck
```

You can also try:

```text
syscheck.path:"/demo/finance/*"
```

Say:

> Wazuh records the affected path, the operation, the endpoint, timestamps, hashes, and—where the operating system supports it—user attribution. This supports both DLP monitoring and incident investigation.

Relevant configuration:

- [agent.conf](/Users/krish/projects/security-assessment/services/wazuh/config/agent.conf)
- [demo-fim.sh](/Users/krish/projects/security-assessment/scripts/demo-fim.sh)

The important FIM setting is:

```xml
<directories realtime="yes" whodata="yes" report_changes="yes">
  /demo/finance,/demo/hr,/demo/confidential
</directories>
```

Meaning:

- `realtime`: detect changes quickly
- `whodata`: collect attribution when supported
- `report_changes`: record content differences where appropriate

# 8. USB/osquery demonstration

Run:

```sh
task demo:usb
```

Say:

> On native Linux, osquery can query the `usb_devices` table for physical device information. Because Docker Desktop runs containers inside a Linux virtual machine, it cannot reliably see a Mac’s physical USB devices. For a deterministic local demonstration, this command generates the same JSON event format that osquery would produce.

The event contains:

- Device insertion action
- Manufacturer
- Model
- Vendor ID
- Device ID
- Serial number
- Removable-device flag

In Wazuh Threat Hunting, search:

```text
rule.id:100101
```

If necessary, set the time range to **Last 15 minutes**, wait up to one minute, and refresh.

Expected alert:

```text
Unauthorized removable USB device inserted
```

Say:

> Custom Wazuh rule 100101 detects an osquery USB-add event where the device is removable. It raises a level-10 alert and labels it as USB, DLP, incident, and Shuffle-related.

Relevant files:

- [osquery.conf](/Users/krish/projects/security-assessment/services/osquery/config/osquery.conf)
- [local_rules.xml](/Users/krish/projects/security-assessment/services/wazuh/config/local_rules.xml)
- [demo-usb.sh](/Users/krish/projects/security-assessment/scripts/demo-usb.sh)

The osquery schedule runs:

```sql
SELECT usb_address, usb_port, vendor, vendor_id,
       model, model_id, serial, removable
FROM usb_devices;
```

The Wazuh rule assigns MITRE ATT&CK technique:

```text
T1052.001 — Exfiltration over USB
```

# 9. Suricata network-detection demonstration

Run:

```sh
task demo:url
```

This makes an internal HTTP request to:

```text
http://demo-web/malware-demo
```

No malware is downloaded. The response is a harmless text fixture.

Say:

> Suricata is monitoring its container network interface. I am generating an inert HTTP request whose path matches a local demonstration signature.

In Wazuh search:

```text
rule.id:100111
```

Or search for the original Suricata signature:

```text
data.alert.signature_id:1000001
```

Expected Suricata information:

```text
Signature ID: 1000001
Signature: DEMO Malicious URL access
URL: /malware-demo
Host: urlhaus-demo.local
Action: allowed
```

Say:

> Suricata writes the event in EVE JSON format. The Wazuh agent reads that log, sends it to the manager, and custom rule 100111 turns the Suricata event into a level-12 Wazuh alert.

Relevant files:

- [suricata.yaml](/Users/krish/projects/security-assessment/services/suricata/config/suricata.yaml)
- [local.rules](/Users/krish/projects/security-assessment/services/suricata/rules/local.rules)
- [demo-url.sh](/Users/krish/projects/security-assessment/scripts/demo-url.sh)
- [local_rules.xml](/Users/krish/projects/security-assessment/services/wazuh/config/local_rules.xml)

The local Suricata rule is:

```text
alert HTTP traffic when the URI contains /malware-demo
```

The corresponding Wazuh alert uses MITRE ATT&CK:

```text
T1071.001 — Web protocols
```

# 10. Shuffle/SOAR demonstration

SOAR means Security Orchestration, Automation, and Response.

Open:

```text
http://localhost:3001
```

Say:

> Shuffle receives selected high-priority Wazuh alerts through a webhook. It can enrich indicators, create an incident ticket, and send a notification automatically.

The two intended workflows are:

## Unauthorized USB workflow

```text
USB detection
→ Validate device against allowlist
→ Create incident ticket
→ Send email notification
```

Blueprint:

[unauthorized-usb.json](/Users/krish/projects/security-assessment/services/shuffle/workflows/unauthorized-usb.json)

## Malicious URL workflow

```text
Suricata alert
→ Extract URL and hostname
→ Query URLhaus
→ Create incident ticket
→ Send email notification
```

Blueprint:

[malicious-url.json](/Users/krish/projects/security-assessment/services/shuffle/workflows/malicious-url.json)

Important honesty for the demo:

> The workflow blueprints and Wazuh-to-Shuffle forwarder are included, but actual ticket and email actions require connector credentials. Those credentials are intentionally not committed to the repository.

To enable real forwarding:

1. Create a webhook-triggered workflow in Shuffle.
2. Copy its webhook URL.
3. Put it in `.env`:

```dotenv
SHUFFLE_WEBHOOK_URL=http://shuffle-backend:5001/api/v1/hooks/YOUR_HOOK_ID
```

4. Restart the forwarder:

```sh
docker compose --env-file .env up -d \
  --force-recreate shuffle-alert-forwarder
```

5. Generate a fresh alert:

```sh
task demo:usb
```

or:

```sh
task demo:url
```

6. Open the workflow execution history in Shuffle.

# 11. Dashboard and reporting section

Show these areas if time permits:

- Active agents
- Agent inventory
- Threat Hunting
- File Integrity Monitoring
- Security alerts
- Rule severity
- Event timeline/counts

Say:

> The Wazuh Dashboard provides a single interface for endpoint inventory, file changes, USB events, network IDS alerts, alert severity, and incident investigation.

For your custom detections, use:

```text
rule.id:100101 OR rule.id:100111
```

# 12. Configuration file map

The root orchestration files are:

| File | Purpose |
|---|---|
| [compose.yml](/Users/krish/projects/security-assessment/compose.yml) | Includes all service stacks |
| [Taskfile.yml](/Users/krish/projects/security-assessment/Taskfile.yml) | Provides simple commands |
| [.env.example](/Users/krish/projects/security-assessment/.env.example) | Documents local variables |
| `.env` | Contains active local passwords and ports; not committed |

Wazuh:

| File | Purpose |
|---|---|
| [compose.yml](/Users/krish/projects/security-assessment/services/wazuh/compose.yml) | Manager, indexer, dashboard, agent |
| [agent.conf](/Users/krish/projects/security-assessment/services/wazuh/config/agent.conf) | Agent, FIM, and log collection |
| [local_rules.xml](/Users/krish/projects/security-assessment/services/wazuh/config/local_rules.xml) | USB and Suricata rules |
| [indexer.yml](/Users/krish/projects/security-assessment/services/wazuh/config/indexer.yml) | OpenSearch/indexer settings |
| [dashboard.yml](/Users/krish/projects/security-assessment/services/wazuh/config/dashboard.yml) | Dashboard/indexer connection |
| [wazuh-dashboard-app.yml](/Users/krish/projects/security-assessment/services/wazuh/config/wazuh-dashboard-app.yml) | Dashboard/Manager API connection |
| [certs.yml](/Users/krish/projects/security-assessment/services/wazuh/config/certs.yml) | Local certificate subjects |

osquery:

| File | Purpose |
|---|---|
| [compose.yml](/Users/krish/projects/security-assessment/services/osquery/compose.yml) | osquery container |
| [osquery.conf](/Users/krish/projects/security-assessment/services/osquery/config/osquery.conf) | Scheduled USB and mount queries |

Suricata:

| File | Purpose |
|---|---|
| [compose.yml](/Users/krish/projects/security-assessment/services/suricata/compose.yml) | Suricata container and capabilities |
| [suricata.yaml](/Users/krish/projects/security-assessment/services/suricata/config/suricata.yaml) | Interface, rules, and EVE output |
| [local.rules](/Users/krish/projects/security-assessment/services/suricata/rules/local.rules) | Harmless URL signatures |

Shuffle:

| File | Purpose |
|---|---|
| [compose.yml](/Users/krish/projects/security-assessment/services/shuffle/compose.yml) | Backend, frontend, database, worker |
| [forwarder.py](/Users/krish/projects/security-assessment/services/shuffle/forwarder.py) | Sends selected Wazuh alerts to a webhook |
| Workflow blueprints | Documents workflow actions |

Demo:

| File | Purpose |
|---|---|
| [demo-fim.sh](/Users/krish/projects/security-assessment/scripts/demo-fim.sh) | FIM create/change/delete |
| [demo-usb.sh](/Users/krish/projects/security-assessment/scripts/demo-usb.sh) | osquery USB JSON fixture |
| [demo-url.sh](/Users/krish/projects/security-assessment/scripts/demo-url.sh) | Harmless Suricata HTTP request |

# 13. Task commands to remember

```sh
task up
```

Starts the complete platform.

```sh
task status
```

Shows container state and URLs.

```sh
task logs
```

Follows logs from all containers.

```sh
task demo:fim
task demo:usb
task demo:url
```

Runs demonstrations individually.

```sh
task demo:all
```

Runs all three demonstrations.

```sh
task down
```

Stops containers but preserves indexed data.

```sh
task reset
```

Removes the containers and persistent volumes. This deletes indexed demo evidence and asks for confirmation.

# 14. Limitations you should disclose

Say:

> This is a proof of concept optimized for a local Docker demonstration. It is not a production deployment.

Specific limitations:

- Physical USB enumeration is limited on Docker Desktop.
- Suricata observes controlled container traffic, not the Mac’s complete physical network interface.
- Shuffle ticket/email actions require external test credentials.
- Wazuh uses a single manager and single indexer.
- Certificates are locally generated.
- Passwords are demo passwords.
- The Shuffle worker mounts the Docker socket, which is highly privileged.

# 15. Production recommendations

Finish by saying:

> For production, I would deploy Wazuh agents natively on endpoints, attach Suricata to a TAP or SPAN port, replace local certificates with organizational PKI, use SSO and MFA, store secrets in a secrets manager, cluster the Wazuh manager and indexer, isolate Shuffle workers, and send backups and audit logs to immutable storage.

Also mention:

- Device allowlists
- Detection tuning
- Role-based access control
- Alert retention policies
- Human approval before endpoint isolation
- Regular incident-response exercises
- Vulnerability scanning and threat-intelligence enrichment

# 16. Likely questions and answers

**Why Wazuh?**

> It combines endpoint monitoring, log analysis, FIM, inventory, vulnerability detection, alerting, and dashboards in one open-source platform.

**Why osquery if Wazuh already has an agent?**

> osquery provides a SQL interface to detailed operating-system state. It is useful for questions such as which USB devices, users, processes, packages, or mounts exist.

**Why Suricata?**

> Wazuh primarily analyzes endpoint and log data. Suricata adds network-level intrusion detection and protocol metadata.

**Why Shuffle?**

> Detection without response creates manual work. Shuffle turns alerts into repeatable actions such as enrichment, tickets, emails, containment requests, and evidence collection.

**Is the malicious URL real?**

> No. It is an inert internal fixture designed to match a local IDS rule safely.

**Is USB detection real?**

> The query and Wazuh processing path are real. On Docker Desktop, physical USB passthrough is unreliable, so the demo supplies a realistic osquery result. A production endpoint would run osquery natively.

**Why are only two ports published?**

> Internal services communicate through Docker DNS on the bridge network. Only the local Wazuh and Shuffle interfaces need host access, and both bind to loopback.

**Why does Shuffle mount the Docker socket?**

> Its local Orborus worker uses Docker to start workflow applications. That grants significant host privileges, so production workers should be isolated.

# 17. Final 30-second summary

You can close with:

> This proof of concept demonstrates an end-to-end security operations pipeline. Wazuh provides endpoint visibility, FIM, centralized detection, storage, and reporting. osquery supplies USB telemetry. Suricata supplies network detections. Shuffle provides the automation layer for enrichment, tickets, and notifications. The system is modular, locally reproducible, and designed with clear steps for production hardening.