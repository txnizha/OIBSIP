# Task 2: Basic Firewall Configuration with UFW

## Objective

Set up and configure a basic firewall on a Linux system using UFW (Uncomplicated Firewall), applying rules to allow and deny specific types of network traffic.

---

## Background & Ethical Use

A firewall is a network security tool that monitors and controls incoming and outgoing network traffic based on predefined rules. It acts as a barrier between a trusted internal network and untrusted external networks, enforcing the security principle of least privilege at the network level — only explicitly permitted traffic is allowed through.

UFW (Uncomplicated Firewall) is a simplified interface for managing iptables, which is Linux's built-in firewall engine. While iptables is extremely powerful, its syntax is complex. UFW abstracts this complexity into human-readable commands, making firewall configuration accessible without sacrificing control.

**Ethical Use Notice:** Firewall configuration should only be performed on systems you own or administer. Misconfiguring a firewall on a production system can cause outages and security incidents. All configuration in this task was performed on a local Kali Linux VM with no impact on external systems.

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| UFW | Pre-installed on Kali Linux | Firewall configuration and rule management |
| Kali Linux (VMware Fusion) | Rolling release | Host OS / configuration environment (virtualized on macOS) |
| Netcat (nc) | Pre-installed on Kali Linux | Testing firewall rules by probing ports |

---

## Installation

UFW was installed using the following command:

```bash
sudo apt install ufw
```

Verify installation:

```bash
ufw --version
```

---

## Firewall Rules Configured

| Rule | Port | Protocol | Action | Reason |
|------|------|----------|--------|--------|
| Default policy | All | All | Deny incoming | Secure baseline — block everything unless explicitly allowed |
| Default policy | All | All | Allow outgoing | Allow machine to initiate outbound connections |
| SSH | 22 | TCP | Allow | Required for remote administration |
| HTTP | 80 | TCP | Deny | Unencrypted — vulnerable to interception |
| HTTPS | 443 | TCP | Allow | Encrypted web traffic using TLS |
| Telnet | 23 | TCP | Deny | Obsolete protocol, transmits credentials in plain text |

---

## Configuration Steps

### Step 1: Set Default Policies

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Setting default policies before enabling UFW ensures no traffic slips through before rules are applied. Denying all incoming by default means only explicitly allowed services are reachable.

### Step 2: Allow SSH (Port 22)

```bash
sudo ufw allow ssh
```

SSH must be allowed before enabling UFW. Without this rule, enabling the firewall on a remote machine would immediately terminate the SSH session and lock the administrator out.

### Step 3: Deny HTTP (Port 80)

```bash
sudo ufw deny http
```

HTTP transmits all data in plain text, including authentication credentials and session cookies. Denying port 80 forces web communication to use HTTPS (port 443) instead, which encrypts all traffic using TLS.

### Step 4: Allow HTTPS (Port 443)

```bash
sudo ufw allow https
```

HTTPS is the encrypted alternative to HTTP. Allowing port 443 while denying port 80 implements a standard web server hardening practice — only encrypted web communication is permitted.

### Step 5: Deny Telnet (Port 23)

```bash
sudo ufw deny telnet
```

Telnet is a legacy remote access protocol that predates SSH. It transmits all data including usernames and passwords in plain text, making it trivially easy for an attacker on the same network to intercept credentials. SSH (port 22) is its modern, encrypted replacement. Explicitly denying Telnet at the firewall level adds a defense-in-depth layer even if the service itself is not running.

### Step 6: Enable UFW

```bash
sudo ufw enable
```

Activates the firewall with all configured rules. Rules exist but are not enforced until UFW is enabled.

### Step 7: Verify Active Rules

```bash
sudo ufw status verbose
```

---

## Verification Output
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip
To                         Action      From
22/tcp                     ALLOW IN    Anywhere
80/tcp                     DENY IN     Anywhere
443                        ALLOW IN    Anywhere
23/tcp                     DENY IN     Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                DENY IN     Anywhere (v6)
443 (v6)                   ALLOW IN    Anywhere (v6)
23/tcp (v6)                DENY IN     Anywhere (v6)

---

## Testing Denied Traffic

To confirm the deny rules are actually enforced, netcat was used to probe the blocked ports:

```bash
nc -zv 127.0.0.1 80
```

Result:
localhost [127.0.0.1] 80 (http) : Connection refused

```bash
nc -zv 127.0.0.1 22
```

Result:
localhost [127.0.0.1] 22 (ssh) open

Port 80 returned "Connection refused" confirming the deny rule is active. Port 22 returned "open" confirming the allow rule is working correctly.

---

## Security Analysis

**Why these specific rules?**

The rule set implements the principle of least privilege at the network level. Only traffic that serves a legitimate, documented purpose is permitted. Every denied port represents a potential attack vector that has been explicitly closed:

- HTTP (port 80) is denied because unencrypted traffic exposes sensitive data to anyone capable of intercepting packets on the network path. A man-in-the-middle attacker could read or modify traffic in transit.
- Telnet (port 23) is denied because it is functionally equivalent to SSH but without any encryption. Its continued existence on any network is considered a critical misconfiguration by modern security standards.
- The default deny incoming policy ensures that any service installed in the future that opens a new port will be blocked automatically until explicitly reviewed and allowed.

---

## How to Reproduce

Run the provided script to apply all rules in sequence:

```bash
chmod +x ufw_configuration.sh
sudo ./ufw_configuration.sh
```

Or apply rules manually:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw deny http
sudo ufw allow https
sudo ufw deny telnet
sudo ufw enable
sudo ufw status verbose
```

---

## Key Learnings

- Firewalls implement the principle of least privilege at the network level — deny everything by default, allow only what is explicitly needed.
- Setting default policies before enabling UFW is critical to avoid locking yourself out of a remote system.
- The difference between HTTP and HTTPS is not just encryption — it is the difference between data being readable by any network observer versus being protected by TLS.
- Defense in depth means denying dangerous protocols like Telnet even when they are not actively running, closing potential attack vectors before they can be exploited.
- Testing firewall rules after configuration is as important as the configuration itself — a rule that exists but does not work provides false security.

---

## References

- UFW Official Documentation: https://help.ubuntu.com/community/UFW
- UFW Man Page: https://manpages.ubuntu.com/manpages/focal/man8/ufw.8.html
- NIST Guidelines on Firewalls: https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-41r1.pdf
- OWASP Transport Layer Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html
- Linux Firewall Best Practices: https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands
