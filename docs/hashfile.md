# hashfile

Calculates file hashes, for example to check a download against a published checksum or to confirm two copies of a file are identical.

| Platform | Usage |
|---|---|
| Linux | `hashfile.sh [-a sha256\|sha1\|md5\|sha512] FILE [FILE...]` |
| PowerShell | `hashfile.ps1 FILE [FILE...] [-Algorithm SHA256\|SHA1\|MD5\|SHA512]` |
| cmd | `hashfile FILE [SHA256\|SHA1\|MD5\|SHA512]` |

Default algorithm: SHA256. Output is the lowercase hash followed by the file path, the same format as Linux `sha256sum`.

## Notes
- PowerShell accepts wildcards (`hashfile.ps1 *.msi`).
- cmd hashes one file per run and uses the built-in `certutil`.
- MD5 and SHA1 are fine for spotting accidental changes but not for security checks. Use SHA256 when verifying software.
