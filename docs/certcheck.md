# certcheck

Shows the TLS certificate a server presents: subject, issuer, validity dates, days until expiry, the names it covers, and whether this machine trusts it. Use it to catch expiring certificates on client portals, mail servers and internal services, or to check what a firewall or proxy is presenting.

| Platform | Usage |
|---|---|
| Linux | `certcheck.sh HOST [PORT] [WARN_DAYS]` |
| PowerShell | `certcheck.ps1 HOST [PORT] [-WarnDays N]` |
| cmd | `certcheck HOST [PORT] [-WarnDays N]` (wrapper) |

Defaults: port 443, warn when fewer than 30 days remain.

## Example
```
certcheck example.com
Host        example.com:443
Subject     CN=example.com
Issuer      CN=..., O=...
Valid from  01/09/2026 00:00
Expires     30/11/2026 23:59
Days left   36
Names       DNS:example.com, DNS:www.example.com
Chain       trusted
```

## Exit codes
`0` valid, trusted and not expiring within the warning window; `2` expired, expiring soon, untrusted or name mismatch; `1` could not connect or no certificate.

## Notes
- Works on any TLS port that starts with a TLS handshake (443, 465, 636, 993, 995, 8443). Ports that upgrade with STARTTLS (25, 587) are not supported.
- If the **Issuer** is your firewall or a proxy rather than a public certificate authority, the connection is being inspected; the tool shows what this machine actually receives.
- Linux needs `openssl`.
