#!/bin/bash
# UFW Firewall Configuration Script
# Description: Configures UFW firewall with secure baseline rules

# Reset UFW to default state before applying rules
# This ensures a clean slate and prevents rule conflicts
sudo ufw reset

# Set default policies
# Deny all incoming traffic unless explicitly allowed
# Allow all outgoing traffic
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (port 22/tcp)
# Required for remote administration access
# Without this rule, enabling UFW would block SSH connections
sudo ufw allow ssh

# Deny HTTP (port 80/tcp)
# HTTP transmits data in plain text, making it vulnerable to
# interception. Denying port 80 forces use of encrypted HTTPS instead
sudo ufw deny http

# Allow HTTPS (port 443)
# HTTPS encrypts all traffic using TLS, protecting data in transit
# This is the secure alternative to HTTP
sudo ufw allow https

# Deny Telnet (port 23/tcp)
# Telnet is an obsolete remote access protocol that transmits
# all data including credentials in plain text
# SSH (port 22) is the modern secure replacement
sudo ufw deny telnet

# Enable UFW
sudo ufw enable

# Display active rules for verification
sudo ufw status verbose
