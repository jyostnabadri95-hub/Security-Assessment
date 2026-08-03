# Architecture

```mermaid
flowchart LR
    endpoint["Demo endpoint\nWazuh agent + FIM"]
    usb["osquery\nUSB inventory"]
    net["Suricata IDS\nURL traffic"]
    feed["URLhaus\nthreat intelligence"]
    mgr["Wazuh Manager\ndecoding + rules"]
    idx["Wazuh Indexer\nsecurity events"]
    dash["Wazuh Dashboard\nlocalhost:8443"]
    soar["Shuffle SOAR\nlocalhost:3001"]
    ticket["Incident ticket\nconnector"]
    email["Email notification\nconnector"]
    usb -->|"JSON results"| endpoint
    net -->|"EVE JSON"| endpoint
    endpoint -->|"encrypted agent channel"| mgr
    mgr --> idx --> dash
    mgr -->|"alert webhook"| soar
    feed -->|"IOC enrichment"| soar
    soar --> ticket
    soar --> email
```

Every component joins the `security-assessment-net` bridge and uses Compose DNS. There are no host-port dependencies between components. Dashboard TLS uses a generated local certificate.

For a 100-employee production deployment, use actual endpoint agents, clustered Wazuh components, redundant isolated Shuffle workers, authenticated TLS ingress, and immutable off-host backups.

