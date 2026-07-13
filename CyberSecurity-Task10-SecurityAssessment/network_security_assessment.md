# Network Security Assessment Report

## Assessment Overview

| Field | Detail |
|-------|--------|
| Report Title | Local Network Security Assessment |
| Target | localhost (127.0.0.1) |
| Assessed By | Tanisha Sinha |
| Tools Used | Nmap 7.95, Wireshark 4.4.4, Nikto 2.5.0 |
| Environment | Kali Linux (VMware Fusion) on macOS |

---

## Scope Definition

**Target IP Range:** 127.0.0.1 (localhost only)

**Services in Scope:**
- All TCP services on the default Nmap port range (top 1000 ports)
- HTTP web server running on port 80
- SSH service running on port 22
- All network traffic on the eth0 interface

**Out of Scope:**
- External IP addresses or third-party systems
- Any systems not owned by the assessor

**Assessment Methodology:**
This assessment follows a three-phase approach modeled on industry-standard penetration testing frameworks including the PTES (Penetration Testing Execution Standard) and OWASP Testing Guide:

- Phase 1: Network Reconnaissance using Nmap
- Phase 2: Traffic Analysis using Wireshark
- Phase 3: Web Vulnerability Scanning using Nikto

---

## Executive Summary

This security assessment was conducted against a locally hosted Kali Linux system running on VMware Fusion. The assessment identified a total of 18 findings across three phases of testing.

The most significant finding is the presence of an unencrypted HTTP web server (Apache 2.4.63) accessible on port 80. HTTP transmits all data in plain text, meaning any traffic between clients and this server is readable by anyone capable of intercepting the connection. This is compounded by 15 web server misconfigurations identified during the Nikto scan, including missing security headers, an exposed server status page, and a potential path traversal vulnerability rated High severity.

The SSH service running on port 22 was found to be running a patched version (9.9p2-1) and does not present an immediate vulnerability, though it remains a target for brute-force attacks if exposed to untrusted networks.

Network traffic analysis over a 5+ minute capture window revealed unencrypted HTTP requests containing readable host information and request headers, confirming the risk posed by the HTTP service. DNS traffic was observed in plain text, exposing domain lookup activity. ARP traffic analysis showed normal gateway communication with no signs of ARP spoofing.

**Overall Risk Posture: Medium**

Immediate remediation of the HTTP service configuration and web server security headers is recommended before any external exposure of this system.

---

## Phase 1: Network Reconnaissance

**Tool:** Nmap 7.95
**Command:** `nmap -sV -O 127.0.0.1`
**Target:** 127.0.0.1

### Results
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.9p1 Debian 3 (protocol 2.0)
80/tcp open  http    Apache httpd 2.4.63 ((Debian))
Device type: general purpose
Running: Linux 2.6.X|5.X
OS details: Linux 2.6.32, Linux 5.0 - 6.2
Network Distance: 0 hops

### Analysis

Two open ports were identified on the target host:

**Port 22 (SSH):** OpenSSH 9.9p1 is running for remote administration. Cross-referencing this version against public CVE databases initially flagged CVE-2025-26465 and CVE-2025-26466 as potentially affecting this version. However, verification via the system package manager confirmed the actual installed version is 9.9p2-1, which includes patches for both CVEs. The service does not present an immediate vulnerability but remains a target for brute-force attacks.

**Port 80 (HTTP):** Apache 2.4.63 is running an unencrypted web server. HTTP transmits all data in plain text and should not be exposed on any production system without HTTPS enforcement. This finding directly led to Phase 3 web vulnerability scanning.

**OS Fingerprint:** Nmap identified the target as running Linux with a kernel in the 5.0 to 6.2 range, consistent with Kali Linux's rolling release kernel.

See screenshot: `task10_1_nmap.png`

---

## Phase 2: Traffic Analysis

**Tool:** Wireshark 4.4.4
**Interface:** eth0
**Capture Duration:** 5+ minutes

### HTTP Traffic Analysis

**Filter applied:** `http`

HTTP traffic was captured showing unencrypted GET requests from the local machine to external servers including neverssl.com and httpforever.com. Expanding the Hypertext Transfer Protocol layer in Wireshark revealed the following readable data in plain text:
GET / HTTP/1.1
Host: neverssl.com
User-Agent: curl/8.12.1
Accept: /
Full request URI: http://neverssl.com/

This demonstrates that HTTP traffic exposes the destination host, request path, client software, and all request headers to any network observer. In a real-world scenario involving login forms or session cookies transmitted over HTTP, credentials and authentication tokens would be equally visible.

See screenshot: `task10_2_http.png`

### DNS Traffic Analysis

**Filter applied:** `dns`

DNS queries and responses were captured showing domain resolution activity for google.com, github.com, neverssl.com, and httpforever.com. DNS traffic is unencrypted by default, meaning all domain lookups are visible to any observer on the network path. This represents a privacy and security concern as an observer can determine which websites a user is visiting even without being able to read the encrypted HTTPS content.

See screenshot: `task10_3_dns.png`

### ARP Traffic Analysis

**Filter applied:** `arp`

ARP (Address Resolution Protocol) traffic was captured showing normal gateway communication between the Kali VM (192.168.197.128) and the VMware virtual gateway (192.168.197.2). The following ARP exchange was observed:

| Packet | Type | Description |
|--------|------|-------------|
| Request | Broadcast | Gateway asking "Who has 192.168.197.128?" |
| Reply | Unicast | Kali VM responding with its MAC address |
| Request | Unicast | Kali VM asking "Who has 192.168.197.2?" |
| Reply | Unicast | Gateway responding with its MAC address |

No ARP spoofing indicators were detected. ARP spoofing would appear as unsolicited ARP replies attempting to associate a legitimate IP address with an attacker's MAC address.

See screenshot: `task10_4_arp.png`

---

## Phase 3: Web Vulnerability Scan

**Tool:** Nikto 2.5.0
**Command:** `nikto -h http://127.0.0.1`
**Target:** Apache 2.4.63 on port 80

Nikto identified 15 findings against the Apache web server. Full details are documented in Task 7. Key findings relevant to this assessment are summarized below:

| Finding | Severity |
|---------|----------|
| Path traversal via extra slash (///etc/hosts) | High |
| Exposed /server-status page | Medium |
| Missing X-Frame-Options header | Medium |
| Missing X-Content-Type-Options header | Low |
| ETag inode leakage (CVE-2003-1418) | Low |
| PHP backdoor paths checked (false positives) | Informational |

See screenshot: `task10_5_nikto.png`

---

## Findings Register

| Finding ID | Description | Severity | Affected Asset | Recommended Fix |
|------------|-------------|----------|----------------|-----------------|
| F-001 | Unencrypted HTTP service running on port 80 | High | Apache 2.4.63 (port 80) | Implement HTTPS with valid TLS certificate, redirect HTTP to HTTPS |
| F-002 | Path traversal via extra slash (///etc/hosts) | High | Apache 2.4.63 (port 80) | Apply Apache security patches, restrict directory access |
| F-003 | SSH service exposed on port 22 | Medium | OpenSSH 9.9p1 (port 22) | Enforce key-based authentication, disable password login |
| F-004 | Exposed /server-status page | Medium | Apache 2.4.63 (port 80) | Restrict /server-status to localhost only |
| F-005 | Missing X-Frame-Options header | Medium | Apache 2.4.63 (port 80) | Add Header always set X-Frame-Options SAMEORIGIN |
| F-006 | DNS traffic unencrypted | Medium | Network (eth0) | Implement DNS over HTTPS or DNS over TLS |
| F-007 | Missing X-Content-Type-Options header | Low | Apache 2.4.63 (port 80) | Add Header always set X-Content-Type-Options nosniff |
| F-008 | ETag inode leakage (CVE-2003-1418) | Low | Apache 2.4.63 (port 80) | Configure FileETag MTime Size |
| F-009 | HTTP methods unnecessarily exposed | Low | Apache 2.4.63 (port 80) | Restrict to GET, POST, HEAD only |
| F-010 | Unencrypted HTTP request data readable | Info | Network (eth0) | Enforce HTTPS for all web communication |

---

## Remediation Roadmap

| Priority | Finding ID | Action | Effort |
|----------|------------|--------|--------|
| 1 | F-001 | Configure HTTPS on Apache with TLS certificate | Medium |
| 2 | F-002 | Apply Apache security patches and restrict directory access | Easy |
| 3 | F-004 | Restrict /server-status to localhost | Easy |
| 4 | F-005 | Add X-Frame-Options header to Apache config | Easy |
| 5 | F-007 | Add X-Content-Type-Options header to Apache config | Easy |
| 6 | F-008 | Configure FileETag directive | Easy |
| 7 | F-009 | Restrict HTTP methods | Easy |
| 8 | F-003 | Enforce SSH key-based authentication | Medium |
| 9 | F-006 | Implement DNS over HTTPS | Hard |

Items 2 through 7 are all single-line Apache configuration changes and can be completed in a single maintenance window with minimal effort. F-001 (HTTPS implementation) should be treated as the highest priority as it addresses the root cause of multiple findings.

---

## Key Learnings

- A structured three-phase assessment approach (reconnaissance, traffic analysis, web scanning) provides comprehensive coverage that no single tool can achieve alone.
- Findings from different phases correlate and reinforce each other. Nmap identified the HTTP service, Wireshark demonstrated the data exposure risk it creates, and Nikto enumerated the specific misconfigurations within it.
- False positives are a normal part of automated scanning. Nikto flagged several WordPress backdoor paths that do not exist on a clean Apache installation. Analyst judgment is required to distinguish real findings from noise.
- Version discrepancies between scanner output and actual installed versions highlight the importance of verifying findings through multiple sources before reporting.

---

## References

- OWASP Testing Guide: https://owasp.org/www-project-web-security-testing-guide/
- PTES Technical Guidelines: http://www.pentest-standard.org/index.php/PTES_Technical_Guidelines
- CVSS Scoring System: https://www.first.org/cvss/
- Nmap Official Documentation: https://nmap.org/docs.html
- Wireshark User Guide: https://www.wireshark.org/docs/wsug_html_chunked/
- Nikto Official Repository: https://github.com/sullo/nikto
- Apache Security Tips: https://httpd.apache.org/docs/2.4/misc/security_tips.html
- DNS over HTTPS Overview: https://www.cloudflare.com/learning/dns/dns-over-tls/
