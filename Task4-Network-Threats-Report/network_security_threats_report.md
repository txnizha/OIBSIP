# Research Report: Common Network Security Threats

## Introduction

Network security threats represent one of the most significant challenges facing organizations in the modern digital landscape. As businesses become increasingly dependent on networked infrastructure, the potential impact of network-based attacks grows proportionally. Understanding how these attacks work, what damage they can cause, and how to defend against them is a foundational requirement for any security professional. This report examines four of the most prevalent and damaging categories of network security threats: Denial of Service and Distributed Denial of Service attacks, Man-in-the-Middle attacks, IP Spoofing, and DNS Poisoning. For each threat, this report covers the technical mechanism of the attack, a documented real-world incident, the business and operational impact, and specific mitigation strategies that organizations can implement.

---

## 1. Denial of Service and Distributed Denial of Service (DoS/DDoS) Attacks

### How It Works

A Denial of Service attack aims to make a system, service, or network unavailable to its intended users by overwhelming it with illegitimate traffic or requests. The target becomes so consumed handling the attack traffic that it cannot respond to legitimate requests.

A Distributed Denial of Service attack scales this concept by coordinating the attack from thousands or millions of compromised machines called a botnet simultaneously. This makes the attack far more powerful and significantly harder to defend against, as the traffic originates from many different IP addresses around the world.

Common DDoS techniques include:

- **Volumetric attacks:** Flooding the target with enormous amounts of traffic to saturate its bandwidth (e.g., UDP floods, ICMP floods)
- **Protocol attacks:** Exploiting weaknesses in network protocols to consume server resources (e.g., SYN floods, which exploit the TCP 3-way handshake)
- **Application layer attacks:** Targeting specific web application functions with seemingly legitimate requests designed to exhaust server resources (e.g., HTTP floods)

### Real-World Example

In February 2020, Amazon Web Services (AWS) mitigated the largest DDoS attack ever recorded at the time, peaking at 2.3 terabits per second. The attack used a technique called Connection-less Lightweight Directory Access Protocol (CLDAP) reflection, which exploited misconfigured CLDAP servers to amplify attack traffic by a factor of 70. The attack lasted three days and targeted an unnamed AWS customer.

### Impact

DDoS attacks can cause complete service outages for hours or days, resulting in direct revenue loss, reputational damage, and customer churn. For e-commerce platforms, financial services, and healthcare providers, even brief outages can have severe consequences. The global average cost of a DDoS attack is estimated at over $50,000 per hour in direct losses, excluding reputational damage.

### Mitigation Strategies

1. **Rate limiting and traffic filtering:** Configure routers and firewalls to limit the rate of incoming requests from any single source and drop packets that match known attack signatures before they reach the target server.

2. **Content Delivery Network (CDN) and DDoS protection services:** Services such as Cloudflare, AWS Shield, and Akamai absorb and filter attack traffic across their globally distributed infrastructure before it reaches the origin server, providing scalable protection against volumetric attacks.

3. **Anycast network diffusion:** Distribute incoming traffic across a large network of scrubbing centers using anycast routing, so no single point becomes overwhelmed. This is the approach used by major DDoS mitigation providers to absorb terabit-scale attacks.

---

## 2. Man-in-the-Middle (MITM) Attacks

### How It Works

A Man-in-the-Middle attack occurs when an attacker secretly intercepts and potentially alters communications between two parties who believe they are communicating directly with each other. The attacker positions themselves between the victim and the legitimate service, reading, modifying, or injecting data into the communication stream without either party being aware.

Common MITM techniques include:

- **ARP Spoofing:** The attacker sends falsified ARP messages on a local network, associating their MAC address with the IP address of a legitimate host, redirecting traffic through the attacker's machine.
- **SSL Stripping:** The attacker intercepts an HTTPS connection and downgrades it to HTTP, allowing them to read traffic that the victim believes is encrypted.
- **DNS Spoofing:** The attacker poisons DNS cache entries to redirect victims to malicious servers when they request legitimate domains.
- **Evil Twin Attack:** The attacker creates a rogue Wi-Fi access point mimicking a legitimate network, intercepting all traffic from victims who connect to it.

### Real-World Example

In 2015, Lenovo was found to have pre-installed software called Superfish on consumer laptops that performed MITM attacks on its own customers. Superfish installed a self-signed root certificate authority on affected machines, allowing it to intercept all HTTPS traffic, decrypt it, inject advertising, and re-encrypt it before passing it to the user. Security researchers demonstrated that the same vulnerability could be exploited by malicious actors to intercept banking credentials and other sensitive data from affected Lenovo customers.

### Impact

MITM attacks enable credential theft, session hijacking, financial fraud, and corporate espionage. Because the communication appears legitimate to both parties, victims rarely detect the attack in progress. In corporate environments, MITM attacks can lead to the compromise of privileged credentials and lateral movement across the network.

### Mitigation Strategies

1. **Enforce HTTPS with HTTP Strict Transport Security (HSTS):** Configure web servers to require HTTPS for all connections and use the HSTS header to instruct browsers to never connect over plain HTTP. This prevents SSL stripping attacks by ensuring the browser enforces encrypted connections before any data is exchanged.

2. **Implement mutual TLS (mTLS) authentication:** Require both the client and server to present valid certificates during the TLS handshake. This prevents attackers from impersonating either party even if they intercept the connection, as they cannot present a valid certificate for the target domain.

3. **Network segmentation and monitoring:** Segment networks to limit the blast radius of ARP spoofing attacks, which are confined to a single broadcast domain. Deploy network monitoring tools to detect unusual ARP traffic patterns that may indicate spoofing attempts.

---

## 3. IP Spoofing

### How It Works

IP spoofing involves an attacker crafting network packets with a forged source IP address, making the traffic appear to originate from a trusted or different source than the actual sender. Since IP addresses are the primary mechanism by which network devices identify the origin of traffic, spoofed packets can bypass IP-based access controls and be used to impersonate trusted hosts.

IP spoofing is frequently used as a component of larger attacks rather than as an end in itself:

- **DDoS amplification attacks:** The attacker spoofs the victim's IP address as the source when sending requests to amplification servers. The amplified responses are then sent to the victim, overwhelming their network.
- **Session hijacking:** By spoofing a legitimate client's IP address, an attacker may be able to inject packets into an existing TCP session.
- **Bypassing IP-based access controls:** Systems that grant access based on source IP address can be bypassed by spoofing a trusted IP.

### Real-World Example

The Mirai botnet, which caused major internet outages in October 2016 by attacking DNS provider Dyn, used IP spoofing as part of its SYN flood attack technique. By spoofing source IP addresses in its SYN packets, Mirai made it significantly harder for Dyn to distinguish attack traffic from legitimate traffic and block it effectively. The attack took down major websites including Twitter, Netflix, Reddit, and CNN for several hours.

### Impact

IP spoofing enables attackers to bypass security controls, conduct amplification DDoS attacks with minimal bandwidth cost to the attacker, and obscure their true origin making forensic attribution difficult. Organizations relying on IP-based authentication or access control are particularly vulnerable.

### Mitigation Strategies

1. **Implement ingress and egress filtering (BCP38):** Configure routers to drop packets arriving on an interface with a source IP address that could not legitimately originate from that interface. This follows IETF Best Current Practice 38 and prevents spoofed packets from traversing the network.

2. **Abandon IP-based authentication:** Never use source IP address as the sole authentication mechanism for access control. Replace with cryptographic authentication methods such as TLS certificates, SSH keys, or API tokens that cannot be forged by spoofing an IP address.

3. **Deploy anti-spoofing mechanisms at the network perimeter:** Use Unicast Reverse Path Forwarding (uRPF) on border routers to verify that the source IP of incoming packets is reachable via the interface on which the packet arrived. Packets failing this check are dropped.

---

## 4. DNS Poisoning and Spoofing

### How It Works

DNS poisoning, also called DNS cache poisoning or DNS spoofing, is an attack that corrupts the DNS cache of a resolver with falsified records. When a DNS resolver caches a poisoned record, it directs users to attacker-controlled IP addresses when they request legitimate domain names, effectively redirecting internet traffic without the user's knowledge.

The attack exploits the fact that DNS was designed for availability rather than security. Traditional DNS queries are sent over UDP without authentication, making it possible for an attacker to inject forged responses if they can predict the transaction ID and port number used in the query.

### Real-World Example

In 2008, security researcher Dan Kaminsky discovered a critical flaw in the DNS protocol that made cache poisoning attacks practical and fast. The vulnerability affected virtually every DNS implementation in use. Before publicly disclosing the vulnerability, Kaminsky coordinated a simultaneous patch release across all major DNS vendors. Had the vulnerability been discovered and exploited by malicious actors before patching, it could have enabled redirection of internet traffic at global scale, affecting banking, email, and all web services.

### Impact

DNS poisoning enables phishing at scale, credential harvesting, malware distribution, and traffic interception. Because the attack targets the DNS resolver rather than individual users, a single successful poisoning can affect thousands or millions of users who rely on that resolver. Victims see the correct domain name in their browser but are served content from an attacker-controlled server.

### Mitigation Strategies

1. **Deploy DNSSEC (DNS Security Extensions):** DNSSEC adds cryptographic signatures to DNS records, allowing resolvers to verify that responses have not been tampered with. A poisoned DNSSEC-signed record will fail signature validation and be rejected.

2. **Use DNS over HTTPS (DoH) or DNS over TLS (DoT):** These protocols encrypt DNS queries and responses, preventing on-path attackers from intercepting or injecting DNS traffic. Major browsers including Firefox and Chrome have implemented DoH support.

3. **Implement DNS response rate limiting:** Configure DNS resolvers to limit the rate at which they accept responses, reducing the window of opportunity for transaction ID guessing attacks that enable cache poisoning.

---

## Comparison Table

| Threat | Attack Vector | Who is at Risk | Difficulty to Execute | Ease of Mitigation |
|--------|--------------|----------------|----------------------|-------------------|
| DoS/DDoS | Network flood, botnet | Any internet-facing service, e-commerce, financial services | Low to Medium | Medium |
| MITM | Network interception, ARP spoofing | Users on shared or unsecured networks, web applications | Medium | Medium |
| IP Spoofing | Forged packet headers | Systems using IP-based access controls, DDoS victims | Medium | Easy |
| DNS Poisoning | Forged DNS responses | All internet users relying on unprotected DNS resolvers | Medium | Medium |

---

## Conclusion

Three key takeaways for a network administrator:

1. **No single control is sufficient.** Each of the threats covered in this report can bypass defenses that work against other threats. Defense in depth, layering multiple independent controls, is the only reliable approach. HTTPS addresses MITM but not DDoS. Rate limiting addresses DDoS but not DNS poisoning. A comprehensive security posture requires all layers working together.

2. **Encryption is foundational, not optional.** MITM attacks, DNS poisoning, and IP spoofing all derive significant power from the fact that much network traffic is transmitted without cryptographic authentication. Implementing HTTPS with HSTS, DNSSEC, and mutual TLS removes the ability of attackers to intercept, modify, or forge traffic even when they have a privileged network position.

3. **Attackers exploit protocol design flaws, not just implementation bugs.** DNS was designed without authentication. IP was designed without source verification. These are not bugs that can be patched — they are architectural limitations that require protocol-level solutions like DNSSEC, BCP38, and uRPF. Understanding the design limitations of foundational protocols is essential for building networks that are resilient against the attacks that exploit them.

---

## References

- CISA — Understanding Denial of Service Attacks: https://www.cisa.gov/news-events/news/understanding-denial-service-attacks
- NIST SP 800-44 — Guidelines on Securing Public Web Servers: https://csrc.nist.gov/publications/detail/sp/800-44/ver-2/final
- IETF BCP38 — Network Ingress Filtering: https://www.rfc-editor.org/info/bcp38
- MITRE ATT&CK — Network Denial of Service: https://attack.mitre.org/techniques/T1498/
- MITRE ATT&CK — Man in the Middle: https://attack.mitre.org/techniques/T1557/
- Cloudflare — What is a DDoS Attack: https://www.cloudflare.com/learning/ddos/what-is-a-ddos-attack/
- ICANN — DNS Security: https://www.icann.org/resources/pages/dnssec-what-is-it-why-important-2019-03-05-en
- CISA — DNS Protocol Vulnerability: https://www.cisa.gov/news-events/alerts/2008/07/08/multiple-vendors-release-updates-address-dns-protocol-vulnerability
