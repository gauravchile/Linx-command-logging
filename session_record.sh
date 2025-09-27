#!/bin/bash
# =====================================================
# Linux Command Logging + Remote Backup (Hourly)
# =====================================================

LOG_DIR="/var/log/command_logs"
PROFILE_SCRIPT="/etc/profile.d/command_record.sh"
LOGROTATE_FILE="/etc/logrotate.d/command_logs"

echo "=== Setting up Hourly Command Logging ==="

# 1️⃣ Create secure log directory
mkdir -p "$LOG_DIR"
chmod 730 "$LOG_DIR"
chown root:adm "$LOG_DIR"

# 2️⃣ Install session logging in profile
cat << 'EOF' > "$PROFILE_SCRIPT"
#!/bin/bash
# Command logging per user, per hour, no output

LOG_DIR="/var/log/command_logs"
# Determine IP or local
if [ -n "$SSH_CLIENT" ]; then
    IP=${SSH_CLIENT%% *}
else
    IP="local"
fi

# Function to get current hourly log file
get_log_file() {
    local user=$(whoami)
    local datetime=$(date +"%Y-%m-%d_%H")
    echo "$LOG_DIR/${user}_${tty}_${datetime}.log"
}

# Record every command typed
export PROMPT_COMMAND='
CMD_LOG=$(get_log_file)
history 1 | { read x cmd; echo "$(date +"%Y-%m-%d %H:%M:%S") | $USER | $(pwd) | '"$IP"' | $cmd" >> "$CMD_LOG"; }'
EOF

chmod +x "$PROFILE_SCRIPT"
source "$PROFILE_SCRIPT"
echo "[*] Profile script installed. Logging active for new sessions."

# 3️⃣ Configure log rotation (keep 7 days)
cat << EOF > "$LOGROTATE_FILE"
$LOG_DIR/*.log {
    hourly
    rotate 168
    compress
    missingok
    notifempty
    create 0640 root adm
}
EOF

# 4️⃣ Remote backup configuration
read -p "Do you want to configure remote backup? (y/n): " choice
if [[ "$choice" == "y" ]]; then
    read -p "Remote user: " REMOTE_USER
    read -p "Remote server (IP or hostname): " REMOTE_SERVER
    read -p "Remote path (e.g., /backups/command_logs): " REMOTE_PATH

    # Generate SSH key if not exist
    [ ! -f /root/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519

    echo "[*] Copying SSH key to remote server..."
    ssh-copy-id "${REMOTE_USER}@${REMOTE_SERVER}"

    # Add cron job for hourly sync
    CRON_JOB="0 * * * * rsync -az --remove-source-files $LOG_DIR/ ${REMOTE_USER}@${REMOTE_SERVER}:${REMOTE_PATH}/"
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "[*] Cron job added: Hourly sync to remote server."
fi

echo "=== Setup Complete ==="
echo "Logs format:"
echo "2025-09-26 15:30:12 | gaurav | /home/gaurav | 192.168.1.50 | ls -la"
echo "Logs directory: $LOG_DIR"
source "$PROFILE_SCRIPT"
