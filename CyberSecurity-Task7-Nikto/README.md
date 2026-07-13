Got it. Here's the corrected README with proper formatting throughout. The issue was indentation in certain sections. Replace everything on GitHub with this:
# Task 7: Vulnerability Scanning with Nikto

## Objective

Use Nikto to perform an automated vulnerability scan on a locally hosted Apache web server, analyse the results, and document identified security issues with recommended remediation steps.

---

## Background & Ethical Use

Nikto is an open-source web server scanner that performs comprehensive tests against web servers for multiple items including potentially dangerous files and programs, outdated server software, and version-specific problems. It is designed for security professionals to identify vulnerabilities in web server configurations before attackers can exploit them.

**Ethical Use Notice:** Nikto should only ever be run against web servers you own or have explicit written authorization to test. Running Nikto against a server without permission is illegal in most jurisdictions and constitutes unauthorized access. All scans in this task were performed exclusively against a locally hosted Apache server running on localhost (127.0.0.1), with no external systems targeted.

---

## What Nikto Does

Nikto operates at the application layer, targeting web servers specifically. When pointed at a target, it sends thousands of HTTP requests and checks for:

- Missing security headers that tell browsers how to handle content securely
- Exposed sensitive files and directories that should not be publicly accessible
- Outdated web server software versions with known CVEs
- Default content that ships with web server software and should be removed before deployment
- Known vulnerability signatures including paths associated with common exploits and backdoors

---

## Nikto vs Nmap

| | Nmap | Nikto |
|--|------|-------|
| What it scans | Network ports and services | Web server content and configuration |
| Layer | Network layer | Application layer |
| Speed | Fast | Slower, thorough |
| Stealth | Can be configured to be quiet | Always noisy |
| Output | Open ports, OS, service versions | Vulnerabilities, misconfigurations, dangerous files |

Nmap answers the question "what is running on this machine?" Nikto answers the question "what is wrong with this web server?"

---

## Nikto as a Noisy Scanner

Nikto makes no attempt at stealth. It sends hundreds of HTTP requests in rapid succession, tries thousands of known exploit paths, and leaves obvious traces in web server access logs. Any intrusion detection system or log monitoring tool would immediately flag a Nikto scan as suspicious activity.

This is in contrast to tools like Nmap, which have stealth scan modes designed to minimize detection. Nikto's approach is intentional — thoroughness is prioritized over stealth because it is designed for authorized security audits where detection is not a concern.

This characteristic makes Nikto inappropriate for use on any system without explicit written authorization, as it will be noticed.

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| Nikto | 2.5.0 | Web server vulnerability scanning |
| Apache | 2.4.63 | Target web server (locally hosted) |
| Kali Linux (VMware Fusion) | Rolling release | Host OS / scan environment (virtualized on macOS) |

---

## Installation

Nikto comes pre-installed on Kali Linux. To verify:

```bash
nikto -Version
```

If not installed, on Debian/Ubuntu-based systems:

```bash
sudo apt update
sudo apt install nikto -y
```

Apache was started as the scan target using:

```bash
sudo systemctl start apache2
sudo systemctl status apache2
```

---

## Scans Performed

### Scan 1: Basic Scan

```bash
nikto -h http://127.0.0.1
```

A basic scan against the locally hosted Apache server on port 80. Results printed to terminal.

See screenshot: `nikto1_basic_scan.png`

### Scan 2: Scan with Output Saved to File

```bash
nikto -h http://127.0.0.1 -o nikto_scan_results.txt
```

Same scan as above but with the `-o` flag saving all output to `nikto_scan_results.txt` for documentation and GitHub submission.

See screenshot: `nikto2_scan_with_output.png`

### Scan 3: SSL Check

```bash
nikto -h http://127.0.0.1 -ssl
```

The `-ssl` flag forces Nikto to test for SSL/TLS related vulnerabilities including weak cipher suites, expired certificates, and insecure TLS versions. Since the local Apache server does not have HTTPS configured, this returned zero results, confirming no SSL/TLS service is present on port 80.

See screenshot: `nikto3_ssl.png`

---

## Findings & Analysis

Nikto reported 15 findings across the basic scan. Each is documented below with severity classification, risk explanation, and remediation.

### Severity Classification

| Severity | Count |
|----------|-------|
| High | 1 |
| Medium | 3 |
| Low | 2 |
| Informational | 9 |

---

### Finding 1: Missing X-Frame-Options Header

**Severity:** Medium

**What it is:** The server does not include the `X-Frame-Options` HTTP response header, which tells browsers whether the page can be embedded inside a frame or iframe on another website.

**Why it is a risk:** Without this header, attackers can load your website invisibly inside a malicious page using an iframe and trick users into clicking elements they cannot see. This attack is called clickjacking.

**How to fix it:** Add the following directive to the Apache configuration file:
Header always set X-Frame-Options "SAMEORIGIN"

---

### Finding 2: Missing X-Content-Type-Options Header

**Severity:** Low

**What it is:** The server does not include the `X-Content-Type-Options` header in its responses.

**Why it is a risk:** Without this header, browsers may attempt to guess the content type of a response rather than trusting the declared MIME type. This is called MIME sniffing. An attacker could upload a file disguised as an image that is actually executable JavaScript, and a vulnerable browser might execute it.

**How to fix it:** Add to Apache configuration:
Header always set X-Content-Type-Options "nosniff"

---

### Finding 3: ETag Inode Leakage (CVE-2003-1418)

**Severity:** Low

**What it is:** Apache's ETag header was found to include the file's inode number, a low-level Linux filesystem identifier.

**Why it is a risk:** Exposing inode numbers leaks internal information about the server's filesystem structure, assisting attackers in fingerprinting the server and planning more targeted attacks.

**How to fix it:** Modify the Apache configuration to remove inode information from ETags:
FileETag MTime Size

---

### Finding 4: Exposed /server-status Page

**Severity:** Medium

**What it is:** Apache's built-in status module exposes a page at `/server-status` showing real-time server activity including active connections, request details, and server uptime.

**Why it is a risk:** This page reveals sensitive operational information about the server including current requests being processed, client IP addresses, and request URIs.

**How to fix it:** Restrict access to `/server-status` to localhost only:
<Location /server-status>
Require ip 127.0.0.1
</Location>

---

### Finding 5: Path Traversal via Extra Slash (///etc/hosts)

**Severity:** High

**What it is:** Nikto identified that appending extra forward slashes to a URL path may allow reading of arbitrary system files outside the web root.

**Why it is a risk:** If exploitable, this path traversal vulnerability would allow an attacker to read sensitive system files including `/etc/passwd`, `/etc/shadow`, and configuration files containing credentials.

**How to fix it:** Ensure Apache's document root is properly isolated and apply the latest Apache security patches. Configure strict directory access controls and disable unnecessary Options directives.

---

### Findings 6 to 12: PHP Backdoor File Paths

**Severity:** Informational

**What it is:** Nikto checked for the presence of several known PHP backdoor file paths commonly associated with compromised WordPress installations.

**Why it is a risk:** These files, if present, would indicate a serious server compromise. PHP backdoors give attackers persistent remote access through a browser interface.

**Context for this scan:** These files do not exist on the clean Apache installation used for this task. The findings are false positives but are documented to illustrate Nikto's detection methodology.

**How to fix it:** On real WordPress installations, regularly audit installed files, use file integrity monitoring, and remove any unrecognized PHP files immediately.

---

### Finding 13: D-Link Router Command Execution Path

**Severity:** Informational

**What it is:** Nikto checked for a path associated with a known remote command execution vulnerability in D-Link routers.

**Context for this scan:** Not applicable to an Apache web server. This finding illustrates that Nikto scans broadly across many device types and platforms.

---

### Finding 14: Shell Backdoor Path

**Severity:** Informational

**What it is:** Nikto checked for a path associated with known web shell backdoors.

**Context for this scan:** This path does not exist on the test Apache server. Web shells are malicious scripts that give attackers command execution capability through a browser.

---

### Finding 15: Allowed HTTP Methods

**Severity:** Informational

**What it is:** The server accepts the following HTTP methods: GET, POST, OPTIONS, HEAD.

**Why it matters:** Unnecessary HTTP methods increase attack surface. Methods like PUT and DELETE should be explicitly disabled if not required.

**How to fix it:** Restrict allowed methods in Apache configuration:
<LimitExcept GET POST HEAD>
    Deny from all
</LimitExcept>


## Security Recommendations Summary

| Priority | Action |
|----------|--------|
| High | Patch path traversal vulnerability and restrict directory access |
| Medium | Add X-Frame-Options header to prevent clickjacking |
| Medium | Restrict /server-status to localhost only |
| Low | Add X-Content-Type-Options header |
| Low | Remove inode data from ETag headers |
| Low | Restrict allowed HTTP methods to minimum required |

---

## How to Reproduce

```bash
# Start Apache web server
sudo systemctl start apache2

# Basic scan
nikto -h http://127.0.0.1

# Scan with output saved to file
nikto -h http://127.0.0.1 -o nikto_scan_results.txt

# SSL scan
nikto -h http://127.0.0.1 -ssl
```

---

## Key Learnings

- Nikto operates at the application layer and is specifically designed for web server vulnerability assessment, complementing network-layer tools like Nmap.
- A noisy scanner like Nikto prioritizes thoroughness over stealth. It sends hundreds of requests rapidly and leaves obvious traces in server logs, making it unsuitable for use without explicit authorization.
- Not all Nikto findings are true positives. Several findings in this scan were false positives where Nikto checked for known malicious paths that do not exist on a clean Apache installation. Security analysts must interpret scanner output critically rather than treating every finding as a confirmed vulnerability.
- Missing HTTP security headers are among the most common and easily remediated web server misconfigurations. Adding headers like X-Frame-Options and X-Content-Type-Options requires a single configuration line but significantly reduces attack surface.
- The SSL scan flag is essential when assessing HTTPS-enabled servers, where weak cipher suites or expired certificates represent serious vulnerabilities.

---

## References

- Nikto Official GitHub Repository: https://github.com/sullo/nikto
- Nikto Documentation: https://cirt.net/Nikto2
- Nikto Web Vulnerability Scanner Tutorial: https://www.youtube.com/results?search_query=nikto+web+vulnerability+scanner+tutorial
- OWASP Top 10 Vulnerabilities: https://owasp.org/www-project-top-ten/
- CVE-2003-1418 (ETag Inode Leakage): http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2003-1418
- Mozilla MDN X-Frame-Options: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
- Apache Security Tips: https://httpd.apache.org/docs/2.4/misc/security_tips.html
- OSVDB-561 Apache Server Status: https://www.rapid7.com/db/vulnerabilities/apache-httpd-osvdb-561/
