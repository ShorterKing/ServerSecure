#!/bin/bash

# Ensure script is run as root or with sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root or with sudo"
  exit 1
fi

# Install fail2ban if not already installed
if ! command -v fail2ban-client &> /dev/null; then
  echo "📦 Installing fail2ban..."
  apt update && apt install -y fail2ban
else
  echo "✅ fail2ban is already installed."
fi

# Create jail configuration
echo "🛠️ Creating /etc/fail2ban/jail.d/custom.local..."
cat > /etc/fail2ban/jail.d/custom.local <<EOF
[sshd]
enabled = true
bantime = -1
findtime = 600
maxretry = 1
EOF

# Create custom filter
echo "🛠️ Creating /etc/fail2ban/filter.d/sshd.local..."
cat > /etc/fail2ban/filter.d/sshd.local <<'EOF'
[Definition]
failregex = ^%(__prefix_line)sConnection closed by (authenticating|invalid) user .* <HOST> port \d+ \[preauth\]$
            ^%(__prefix_line)sInvalid user .* from <HOST> port \d+$
            ^%(__prefix_line)serror: kex_exchange_identification: .*$ 
            ^%(__prefix_line)sbanner exchange: Connection from <HOST> port \d+: invalid format$
EOF

# Restart fail2ban to apply changes
echo "🔄 Restarting fail2ban..."
systemctl restart fail2ban

# Show status
echo "✅ Setup complete. Checking status..."
fail2ban-client status sshd || echo "⚠️ SSHD jail may not be active yet. Check fail2ban logs."
