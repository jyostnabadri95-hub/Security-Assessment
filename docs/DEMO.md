# 5-10 minute demonstration

## Before presenting

1. Run `task up`; wait for core services to become ready.
2. Sign in at `https://localhost:8443` and confirm `demo-endpoint` is active.
3. Open `http://localhost:3001`, complete Shuffle first-user setup, implement/import the blueprints in `services/shuffle/workflows/`, add test ticket/email credentials, and paste the workflow webhook into `SHUFFLE_WEBHOOK_URL`. Restart with `task up`. Connector secrets are not committed.
4. In Wazuh Security Events filter on `rule.id:(100101 OR 100111)`.

## Live sequence

1. Walk through `docs/ARCHITECTURE.md` and the loopback-only exposure.
2. Run `task demo:fim`; show create/modify/delete, diff, and agent attribution.
3. Run `task demo:usb`; show rule `100101`, device fields, and the ticket/email chain.
4. Run `task demo:url`; show Suricata signature `1000001`, Wazuh rule `100111`, and enrichment chain.
5. Show endpoint inventory, active alerts, FIM, network events, and event counts.
6. Close with `docs/SECURITY.md` limitations and roadmap.

All indicators are inert fixtures. No malware is downloaded and no external attack target is contacted.

## Troubleshooting

- Indexer exits: assign Docker 10 GB RAM and ensure `vm.max_map_count >= 262144`.
- Dashboard not ready: initialization often takes one to three minutes; inspect `task logs`.
- No FIM event: confirm agent status and wait up to one minute after the task.
- No URL event: inspect `services/demo/logs/eve.json` and Suricata logs.
- Enrollment fails after partial reset: run `task reset`, then `task up`.
