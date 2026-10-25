# dnscheck

Resolves a name with this machine's DNS resolver and with other DNS servers side by side, and flags when they disagree. Useful for diagnosing DNS filtering, split DNS, stale records after a change, or a resolver that is not answering.

| Platform | Usage |
|---|---|
| Linux | `dnscheck.sh NAME [TYPE] [SERVER...]` |
| PowerShell | `dnscheck.ps1 NAME [TYPE] [-Server S1,S2]` |
| cmd | `dnscheck NAME [TYPE] [SERVER...]` |

`TYPE`: A (default), AAAA, CNAME, MX, TXT, NS, SRV, SOA, PTR.
Servers default to `1.1.1.1` (Cloudflare) and `8.8.8.8` (Google). For the system resolver only: `none` (Linux, cmd) or `-Server @()` (PowerShell).

## Privacy
Querying public DNS servers sends the name you look up to those providers. For client or internal names, compare against your own resolvers instead, for example `-Server 10.0.0.1`.

## Output and exit codes
Linux and PowerShell print one line per resolver and compare the answers (order ignored).
`0` all agree; `2` answers differ; `1` invalid arguments or no DNS tool available.

Differences are normal for names served by CDNs (Microsoft 365, Google, Cloudflare-hosted sites), which hand out different addresses by location. They are worth investigating for your own domains.

## Notes
- The system resolver line reflects any DNS filtering or DoH profile applied to the device, so a mismatch against public servers can mean the name is being filtered.
- cmd shows raw `nslookup` output for each resolver rather than a comparison.
- Linux needs `dig` (dnsutils / bind-utils) for the comparison; with only `nslookup` it shows raw output.
