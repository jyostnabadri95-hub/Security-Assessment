# Integrated Open-Source Security Operations PoC

Local Docker proof of concept for the Information Security Engineering assignment. It combines Wazuh EDR/FIM, an enrolled Linux demo endpoint, osquery USB inventory, Suricata IDS, Shuffle SOAR, and Wazuh Dashboard.

## Quick start

Prerequisites: Docker Desktop/Engine with Compose v2, [Task](https://taskfile.dev/), 4 CPU cores, at least 10 GB RAM assigned to Docker, and about 30 GB free disk. Linux hosts must set `vm.max_map_count=262144`.

```sh
cp .env.example .env
# Replace demo passwords and SHUFFLE_ENCRYPTION_MODIFIER in .env.
task up
```

Startup can take several minutes on the first run. Open Wazuh at `https://localhost:8443` and sign in as `admin` with `WAZUH_INDEXER_PASSWORD`. The generated local certificate causes an expected browser warning. Shuffle is local-only at `http://localhost:3001`.

```sh
task status       # health and URLs
task logs         # all logs
task demo:all     # safe FIM, USB, and URL detections
task down         # preserve indexed data
task reset        # confirmed destructive reset
```

## Security boundary

All services communicate on the `security-assessment-net` bridge. Only Wazuh Dashboard and the Shuffle development UI have published ports, both bound to `127.0.0.1`. Manager/API, indexer, osquery, Suricata, demo target, and Shuffle internals are container-only.

Shuffle Orborus needs `/var/run/docker.sock` to launch workflow containers. This is effectively host-level privilege. Use it only on a disposable demo environment; production should use isolated workers or narrowly scoped Kubernetes permissions.

The `shuffle-alert-forwarder` tails Wazuh alerts and forwards rules `100101` and `100111` after `SHUFFLE_WEBHOOK_URL` is set. Ticket/email connectors require your test credentials and are deliberately not stored here.

## Repository layout

```text
.
├── compose.yml                 # composition only
├── Taskfile.yml                # operator interface
├── docs/                       # architecture, demo, hardening
├── scripts/                    # harmless event generators
└── services/
    ├── wazuh/                  # manager/indexer/dashboard/agent
    ├── osquery/                # scheduled USB queries
    ├── suricata/               # IDS config and signatures
    ├── shuffle/                # SOAR and workflow blueprints
    └── demo/                   # monitored data/internal target
```

Each service owns its Compose fragment and configuration. The root file only includes fragments and declares shared resources.

## Demo detections

- `task demo:fim` creates, edits, and removes a synthetic Finance file. Wazuh agent `demo-endpoint` monitors Finance, HR, and Confidential paths with real-time FIM.
- `task demo:usb` appends a realistic osquery differential result. Wazuh rule `100101` raises a level-10 unauthorized USB alert.
- `task demo:url` makes a harmless internal request to `/malware-demo`. Suricata rule `1000001` emits EVE JSON and Wazuh rule `100111` raises a level-12 alert.

See `docs/DEMO.md` for the presentation sequence and `docs/SECURITY.md` for production recommendations.

## Docker Desktop caveat

Native Linux can expose host USB and a capture interface to these sensors. Docker Desktop runs Linux containers in a VM, so USB devices and host traffic are not transparently visible. Fixture commands exercise the same log-decoding and alert paths deterministically and are labeled `DEMO`; they do not claim physical-device or complete host-network visibility on macOS/Windows.
