# Task 1: Basic Network Scanning with Nmap
**OIBSIP | Oasis Infobyte Cybersecurity Internship**
**Author:** Tanisha Sinha
**Task Level:** Beginner

---

## Objective

Perform a network scan to identify open ports and active services on a local machine using Nmap, and document findings with security implications.

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| Nmap | Pre-installed on Kali Linux | Network discovery and port scanning |
| Kali Linux | Rolling release | Host OS / scan environment |

---

## Methodology

Three progressive scans were performed on localhost (127.0.0.1) to simulate a real-world reconnaissance workflow:

| Scan Type | Command | Purpose |
|-----------|---------|---------|
| Basic TCP scan | `nmap 127.0.0.1` | Identify open ports |
| Service & version detection | `nmap -sV 127.0.0.1` | Identify running services and versions |
| OS + aggressive detection | `nmap -A 127.0.0.1` | Full fingerprinting with OS detection |

> All scans were performed on localhost only. No external or third-party systems were targeted.

---

## Scan Results Summary

> See `nmap_scan_results.txt` for full raw output.

### Scan 1: Basic TCP Scan
```
nmap 127.0.0.1
```
```
Starting Nmap 7.95 ( https://nmap.org ) at 2026-06-30 15:26 AEST
Nmap scan report for localhost (127.0.0.1)
Host is up (0.0000010s latency).
Not shown: 999 closed tcp ports (reset)
PORT   STATE SERVICE
22/tcp open  ssh

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```

### Scan 2: Service & Version Detection
```
nmap -sV 127.0.0.1
```
```
Starting Nmap 7.95 ( https://nmap.org ) at 2026-06-30 15:46 AEST
Nmap scan report for localhost (127.0.0.1)
Host is up (0.0000010s latency).
Not shown: 999 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.9p1 Debian 3 (protocol 2.0)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 0.29 seconds
```

### Scan 3: Aggressive Scan (OS + Scripts)
```
nmap -A 127.0.0.1
```
```
Starting Nmap 7.95 ( https://nmap.org ) at 2026-06-30 16:11 AEST
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000045s latency).
Not shown: 999 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.9p1 Debian 3 (protocol 2.0)
| ssh-hostkey:
|   256 fe:a8:d3:04:59:93:6e:5f:c1:cc:01:34:a7:f1:3c:e0 (ECDSA)
|_  256 f8:54:14:76:f5:47:8c:60:05:08:a5:a9:bf:d1:a2:92 (ED25519)
Device type: general purpose
Running: Linux 2.6.X|5.X
OS CPE: cpe:/o:linux:linux_kernel:2.6.32 cpe:/o:linux:linux_kernel:5 cpe:/o:linux:linux_kernel:6
OS details: Linux 2.6.32, Linux 5.0 - 6.2
Network Distance: 0 hops
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

OS and Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 1.82 seconds
```

---

## Findings & Analysis

### Summary of Discovery

A single open port was identified on the target host: **port 22/TCP, running SSH (Secure Shell)**. This is expected behavior on a Kali Linux installation, as SSH is commonly enabled by default to support remote administration. No other services were found listening on the top 1000 scanned ports.

### Finding 1: Open SSH Service (Port 22)

| Attribute | Detail |
|-----------|--------|
| Port | 22/TCP |
| State | Open |
| Service | SSH (Secure Shell) |
| Version (per Nmap banner) | OpenSSH 9.9p1, Debian 3, protocol 2.0 |
| Host key types | ECDSA, ED25519 (both modern, secure algorithms) |
| OS guess | Linux (kernel 5.0–6.2 range), low confidence due to localhost scan |

**Risk Context:** SSH is the standard protocol for encrypted remote administration. It is also one of the most consistently targeted services on the internet, as automated bots continuously probe for exposed SSH servers to attempt brute-force or credential-stuffing attacks. While this finding poses no risk in the current scenario (localhost-only, no external exposure), it represents the kind of finding that would require immediate scrutiny in a production or internet-facing environment.

### Finding 2: Version Discrepancy and Vulnerability Verification

Nmap's service detection (`-sV`) reported the installed SSH version via its banner-grabbing technique as **OpenSSH 9.9p1**. Cross-referencing this version against public vulnerability databases revealed two relevant CVEs:

- **CVE-2025-26465** (CVSS 6.8) — a logic flaw allowing an on-path attacker to impersonate an SSH server when the `VerifyHostKeyDNS` client option is enabled
- **CVE-2025-26466** (CVSS 5.9) — a pre-authentication denial-of-service vulnerability affecting both SSH client and server

Both CVEs affect OpenSSH versions up to and including 9.9p1, which initially suggested the scanned system could be vulnerable.

**Verification:** To confirm this finding before drawing a conclusion, the installed package version was independently checked using the system's package manager:

```bash
apt changelog openssh-server
```

This revealed the actual installed package version to be **9.9p2-1** — one patch revision beyond what Nmap's banner indicated. OpenSSH 9.9p2 was released specifically to remediate both CVE-2025-26465 and CVE-2025-26466. **The system is therefore not vulnerable to either disclosed CVE.**

**Key Analytical Insight:** This finding illustrates a practical limitation of automated banner-grabbing during vulnerability scanning. Nmap's version detection reflects what a service announces during the protocol handshake, which can lag behind the true installed version if a vendor patches a vulnerability without updating the announced version string. Relying solely on scanner output without secondary verification against package-level metadata can lead to false-positive vulnerability assessments. Best practice in a professional security audit is to corroborate automated scan findings against the host's native package information before reaching conclusions.

### Reference Table: Common Ports and General Security Significance

While only port 22 was found open in this scan, the following table documents the general risk profile of commonly encountered ports, for context in future audits:

| Port | Service | Risk Level | Explanation |
|------|---------|-----------|-------------|
| 22 | SSH | Medium | Allows remote login. Brute-force and credential-stuffing attacks target this port. Should be restricted by IP whitelist and key-based auth only. |
| 80 | HTTP | High | Unencrypted web traffic. Data in transit is visible to anyone on the network (MITM risk). Should be redirected to HTTPS (443). |
| 443 | HTTPS | Low-Medium | Encrypted web traffic. Still vulnerable if outdated TLS versions (TLS 1.0/1.1) are in use. |
| 3306 | MySQL | Critical | Database port should never be exposed externally. An open MySQL port could allow direct database access if misconfigured. |
| 631 | CUPS (Printing) | Low | Printing service. Not typically exploitable, but should be disabled if not in use to reduce attack surface. |

---

## Security Recommendations

1. **Verify patch status, not just version banners**: As demonstrated in this audit, Nmap's reported version (9.9p1) did not match the actual patched package (9.9p2-1). Always cross-check scanner output against the host's package manager before concluding a system is vulnerable.
2. **Restrict SSH access**: Use key-based authentication and disable password login (`PasswordAuthentication no` in `/etc/ssh/sshd_config`) as a general hardening measure, regardless of current patch status.
3. **Keep `VerifyHostKeyDNS` disabled**: This is the default setting and should remain so, as it is a precondition for CVE-2025-26465 exploitation.
4. **Close unused ports**: Every open port is a potential attack vector. Disable services that are not required.
5. **Regularly re-scan and re-verify**: Nmap scans should be part of routine security audits to catch newly opened ports or version drift from software updates.

---

## Repository Structure

```
OIBSIP_Task1/
├── README.md                  # This file
├── nmap_scan_results.txt      # Raw Nmap output from all three scans
└── screenshots/
    ├── scan1_basic.png
    ├── scan2_service_detection.png
    └── scan3_aggressive.png
```

---

## How to Reproduce

```bash
# Step 1: Verify Nmap is installed
nmap --version

# Step 2: Run basic scan
nmap 127.0.0.1 -oN nmap_scan_results.txt

# Step 3: Run service detection (appends to file)
nmap -sV 127.0.0.1 >> nmap_scan_results.txt

# Step 4: Run aggressive scan
nmap -A 127.0.0.1 >> nmap_scan_results.txt
```

The `-oN` flag saves output to a file automatically.

---

## Key Learnings

- Nmap is the industry-standard tool for network reconnaissance and is used in both offensive (penetration testing) and defensive (network auditing) security contexts.
- Identifying open ports is the first step in understanding a system's attack surface.
- The difference between a **port being open** and a **service being secure** is critical — an open port with an outdated service version is more dangerous than a closed one.
- **Scanner output should be verified, not trusted blindly.** Nmap's banner-grabbing reported a version (9.9p1) that appeared vulnerable to two CVEs, but cross-checking with the system's package manager revealed the actual installed version (9.9p2-1) was already patched. This reinforced the importance of corroborating automated tool output with a second, independent source before drawing security conclusions.

---

*Submitted as part of AICTE Oasis Infobyte Security Analyst Internship Program*
*Submission Deadline: 15 July 2026*
