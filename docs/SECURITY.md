# Security recommendations and production roadmap

This is a local PoC, not a production deployment.

1. Replace all demo secrets, store them in a secrets manager, rotate credentials, and use separate service identities.
2. Use organizational PKI, end-to-end certificate validation, SSO/MFA, and an allowlisted reverse proxy.
3. Remove the Docker socket from the primary host; isolate Shuffle workers and constrain registry access and egress.
4. Cluster Wazuh across failure domains; use encrypted snapshots, tested restores, retention policy, and capacity alerts.
5. Deploy Wazuh/osquery natively. Add tamper protection, signed config, device allowlists, Windows event channels, and Linux audit.
6. Attach Suricata to TAP/SPAN or a routed sensor. Separate capture/management networks, tune `HOME_NET`, update signed rules, and monitor packet drops.
7. Validate and cache URLhaus data, apply timeouts, and treat threat-intelligence fields as untrusted input.
8. Initially require approval for disruptive response. Add endpoint isolation only after testing rollback and exclusions.
9. Send audit logs to immutable storage and alert on sensor gaps, workflow edits, failed notifications, and queue backlog.
10. Add vulnerability scanning, phishing telemetry, MISP/AbuseIPDB, ticket lifecycle metrics, and quarterly exercises.

Minimize Finance/HR content in alerts. Hash or redact content, restrict analyst roles, and align retention with privacy requirements.

