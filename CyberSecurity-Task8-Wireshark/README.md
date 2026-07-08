# Task 8: Capture Network Traffic with Wireshark

## Objective

Capture and analyze live network traffic using Wireshark, apply protocol filters to isolate specific traffic types, and document findings with security observations.

---

## Background & Ethical Use

Every piece of data transmitted across a network is broken into small chunks called packets. Wireshark is a packet analyzer that captures these packets in real time and allows analysts to inspect their contents, including the protocol used, source and destination addresses, and the actual data payload.

Packet analysis is used defensively by security analysts to detect anomalies, monitor for suspicious traffic, and investigate incidents. The same capability used offensively by attackers demonstrates why unencrypted protocols like HTTP are fundamentally dangerous on any shared network.

**Ethical Use Notice:** Network traffic capture should only ever be performed on networks you own or have explicit authorization to monitor. Capturing traffic on public Wi-Fi, university networks, or any network without authorization is illegal in most jurisdictions. All captures in this task were performed exclusively on a local Kali Linux VM's own network interface, with no third-party networks involved.

---

## Tools Used

| Tool | Version | Purpose |
|------|---------|---------|
| Wireshark | 4.4.4 | Packet capture and protocol analysis |
| Kali Linux (VMware Fusion) | Rolling release | Host OS / capture environment (virtualized on macOS) |
| curl | Pre-installed | Generating HTTP and HTTPS traffic for capture |
| ping | Pre-installed | Generating ICMP and DNS traffic for capture |

---

## Installation

Wireshark comes pre-installed on Kali Linux. To verify:

```bash
wireshark --version
```

To launch with root privileges required for packet capture:

```bash
sudo wireshark
```

Root privileges are required because capturing raw network packets is a privileged operation. Without elevated permissions, Wireshark cannot access the network interface at the packet level.

---

## Methodology

### Step 1: Select Network Interface

On launch, Wireshark displays all available network interfaces. The `eth0` interface was selected as it is the primary Ethernet interface carrying live network traffic on the Kali VM, confirmed by the live activity graph displayed next to it.

### Step 2: Generate Traffic

To ensure a variety of protocols were captured, the following commands were run in a separate terminal while Wireshark was capturing:

```bash
curl http://neverssl.com
curl http://httpforever.com
curl https://example.com
ping -c 5 google.com
ping -c 5 github.com
```

This generated HTTP, HTTPS, DNS, ICMP, and TCP traffic across the capture window.

### Step 3: Stop and Save Capture

After capturing for over 2 minutes, the capture was stopped and saved as `wireshark_capture.pcap` using File → Save As, selecting the Wireshark/tcpdump pcap format.

### Step 4: Apply Display Filters

Display filters were applied to isolate specific protocol traffic for analysis.

---

## Findings & Analysis

### Finding 1: HTTP Traffic

**Filter applied:** `http`

Six HTTP packets were captured, including GET requests from the local machine (192.168.197.128) to external servers. The filtered view confirmed that HTTP traffic was present and readable.

See screenshot: `wireshark1_http.png`

### Finding 2: DNS Traffic

**Filter applied:** `dns`

34 DNS packets were captured, showing standard query and response pairs for domains including google.com, github.com, httpforever.com, and neverssl.com. DNS traffic is unencrypted by default, meaning domain lookups are visible to anyone monitoring the network. This is a known privacy and security concern addressed by DNS over HTTPS (DoH) and DNS over TLS (DoT).

See screenshot: `wireshark2_dns.png`

### Finding 3: TCP 3-Way Handshake

**Filter applied:** `tcp and ip.addr==34.223.124.45`

A complete TCP 3-way handshake was identified between the local machine (192.168.197.128) and the remote server (34.223.124.45):

| Packet | Direction | Flag | Meaning |
|--------|-----------|------|---------|
| 7 | 192.168.197.128 → 34.223.124.45 | SYN | Client initiates connection request |
| 8 | 34.223.124.45 → 192.168.197.128 | SYN, ACK | Server acknowledges and responds |
| 9 | 192.168.197.128 → 34.223.124.45 | ACK | Client confirms, connection established |

Immediately following the handshake, packet 10 shows the HTTP GET request being transmitted, confirming the connection was successfully established before data transfer began.

See screenshot: `wireshark3_tcp_handshake.png`

### Finding 4: Unencrypted Data in HTTP Packet

**Packet analyzed:** Packet 10 (HTTP GET request to neverssl.com)

Expanding the Hypertext Transfer Protocol layer in packet 10 revealed the following information in plain text:
GET / HTTP/1.1
Host: neverssl.com
User-Agent: curl/8.12.1
Accept: /
Full request URI: http://neverssl.com/

This demonstrates the core security risk of HTTP. Every field of this request is readable by any party capable of intercepting the traffic, including the destination host, the software making the request, and the full URL being accessed. In a real-world scenario involving a login form or session cookie transmitted over HTTP, credentials and authentication tokens would be equally visible.

See screenshot: `wireshark4_unencrypted.png`

---

## Why Unencrypted HTTP Traffic is Dangerous

When data is transmitted over HTTP, it travels across the network as plain text. Any device on the same network path between the client and server can intercept and read the contents of every packet. This includes:

- Usernames and passwords submitted via login forms
- Session cookies used to maintain authenticated sessions
- Form data containing personal or financial information
- The full URLs of every page visited

This attack is known as a man-in-the-middle (MITM) interception and requires no special exploits. Any network monitoring tool, including Wireshark, can passively read HTTP traffic without the client or server being aware.

---

## How HTTPS Prevents Eavesdropping

HTTPS wraps HTTP inside TLS (Transport Layer Security), a cryptographic protocol that establishes an encrypted tunnel between the client and server before any data is exchanged. The process works as follows:

1. The client and server perform a TLS handshake, negotiating encryption algorithms and exchanging cryptographic keys
2. All subsequent data is encrypted using those keys before transmission
3. Even if an attacker intercepts the packets, the payload appears as random encrypted bytes with no readable content

In a Wireshark capture of HTTPS traffic, the protocol shows as TLS rather than HTTP, and the packet contents are entirely unreadable without the private key. This is why Task 2 denied HTTP (port 80) and allowed only HTTPS (port 443).

---

## Glossary

**Packet:** A small unit of data transmitted over a network. Large messages are broken into multiple packets, each containing a header (routing information) and a payload (the actual data). Packets may travel different routes and are reassembled at the destination.

**Protocol:** A set of rules that defines how data is formatted, transmitted, and received between devices. Examples include HTTP (web), DNS (domain lookup), TCP (reliable delivery), and TLS (encryption). Protocols ensure that different systems can communicate consistently.

**Port:** A numbered channel on a machine used to direct network traffic to the correct application. Port 80 is used for HTTP, port 443 for HTTPS, and port 22 for SSH. Think of an IP address as a building and ports as individual doors, each leading to a different service.

**Payload:** The actual content or data being carried inside a packet, as opposed to the header information used for routing and delivery. In an HTTP GET request, the payload includes the request method, host, and headers. In an HTTPS packet, the payload is encrypted and unreadable.

**Handshake:** A process where two devices exchange messages to establish a connection and agree on communication parameters before data transfer begins. The TCP 3-way handshake (SYN, SYN-ACK, ACK) establishes a reliable connection. The TLS handshake negotiates encryption keys. Both must complete successfully before any application data is exchanged.

---

## How to Reproduce

```bash
# Step 1: Launch Wireshark with root privileges
sudo wireshark

# Step 2: Select eth0 interface and start capture

# Step 3: Generate traffic in a separate terminal
curl http://neverssl.com
curl http://httpforever.com
curl https://example.com
ping -c 5 google.com
ping -c 5 github.com

# Step 4: Stop capture after 2 minutes
# Step 5: Save as wireshark_capture.pcap via File → Save As

# Step 6: Apply filters for analysis
# HTTP traffic: http
# DNS traffic: dns
# TCP handshake: tcp and ip.addr==34.223.124.45
```

---

## Key Learnings

- Wireshark captures every packet on a network interface, making it a powerful tool for both security monitoring and demonstrating the risks of unencrypted protocols.
- HTTP transmits all data in plain text. A single Wireshark capture session was sufficient to read the full contents of an HTTP request including the destination host, request path, and client software.
- DNS traffic is also unencrypted by default, meaning domain lookups are visible to network observers. DNS over HTTPS (DoH) and DNS over TLS (DoT) address this gap.
- The TCP 3-way handshake is the foundation of every reliable network connection. Understanding it is essential for analyzing network behavior and detecting anomalies like port scanning or connection hijacking attempts.
- HTTPS prevents eavesdropping by encrypting the entire HTTP payload using TLS, rendering intercepted packets unreadable without the private key.

---

## References

- Wireshark Official Documentation: https://www.wireshark.org/docs/
- Wireshark User Guide: https://www.wireshark.org/docs/wsug_html_chunked/
- Wireshark Display Filter Reference: https://www.wireshark.org/docs/dfref/
- TCP 3-Way Handshake Explained: https://www.cloudflare.com/learning/ddos/glossary/tcp-ip/
- OWASP Transport Layer Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Protection_Cheat_Sheet.html
- DNS over HTTPS Overview: https://www.cloudflare.com/learning/dns/dns-over-tls/
