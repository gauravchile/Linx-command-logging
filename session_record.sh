#!/bin/bash
# ==========================================================
# Universal Command Logging System (All Users)
# Secure, per-user, per-hour command logging
# ==========================================================

BASE_DIR="/var/log/command_logs"
PROFILE_SCRIPT="/etc/profile.d/command_logging.sh"
LOGROTATE_FILE="/etc/logrotate.d/command_logs"
LOG_GROUP="cmdlogs"

echo "=== Setting up Secure Command Logging for All Users ==="

# ----------------------------------------------------------
# 1. Create dedicated group for logging
# ----------------------------------------------------------
if ! getent group "$LOG_GROUP" >/dev/null; then
    groupadd "$LOG_GROUP"
    echo "[+] Group '$LOG_GROUP' created"
else
    echo "[i] Group '$LOG_GROUP' already exists"
fi

# ----------------------------------------------------------
# 2. Create secure parent directory
# ----------------------------------------------------------
mkdir -p "$BASE_DIR"
chown root:"$LOG_GROUP" "$BASE_DIR"
chmod 2770 "$BASE_DIR"    # rwx for owner & group, sticky group

echo "[+] Log root directory ready: $BASE_DIR"

# ----------------------------------------------------------
# 3. Add ALL normal users to cmdlogs group
# ----------------------------------------------------------
echo "[+] Adding all users to $LOG_GROUP ..."

for u in $(awk -F: '$3>=1000 && $1!="nobody" {print $1}' /etc/passwd); do
    usermod -aG "$LOG_GROUP" "$u"
    echo "  - Added: $u"
done

# ----------------------------------------------------------
# 4. Install improved /etc/profile.d/ logging script
# ----------------------------------------------------------
cat << 'EOF' > "$PROFILE_SCRIPT"
#!/bin/bash

BASE_DIR="/var/log/command_logs"
USER_DIR="$BASE_DIR/$USER"

# Ensure per-user log directory exists
if [[ ! -d "$USER_DIR" ]]; then
    mkdir -p "$USER_DIR"
    chmod 770 "$USER_DIR"
    chown $USER:cmdlogs "$USER_DIR"
fi

# Get clean TTY name
tty_raw=$(tty 2>/dev/null)
tty_clean=$(basename "$tty_raw")

# Handle shells without tty (cron, system)
if [[ -z "$tty_clean" || "$tty_clean" == "not a tty" ]]; then
    tty_clean="notty"
fi

# Detect remote / local IP
if [[ -n "$SSH_CLIENT" ]]; then
    IP=${SSH_CLIENT%% *}
else
    IP="local"
fi

# Build per-hour logfile
get_log_file() {
    local datetime=$(date +"%Y-%m-%d_%H")
    echo "$USER_DIR/${USER}_${tty_clean}_${datetime}.log"
}

# Log each command
export PROMPT_COMMAND='
CMD_LOG=$(get_log_file)
history 1 | {
    read _ cmd
    echo "$(date +"%Y-%m-%d %H:%M:%S") | $USER | $(pwd) | '"$IP"' | $cmd" >> "$CMD_LOG"
}
'
EOF

chmod +x "$PROFILE_SCRIPT"

echo "[+] Profile script installed: $PROFILE_SCRIPT"
echo "[i] Logging becomes active for **new sessions**."

# ----------------------------------------------------------
# 5. Install logrotate configuration
# ----------------------------------------------------------
cat << EOF > "$LOGROTATE_FILE"
$BASE_DIR/*/*.log {
    hourly
    rotate 168
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    create 0640 root $LOG_GROUP
}
EOF

echo "[+] Logrotate installed: $LOGROTATE_FILE"

echo "=== Setup Complete ==="
echo "Logs will appear in: /var/log/command_logs/<user>/"
echo "File format: <user>_<tty>_<YYYY-MM-DD_HH>.log"
echo "Example:"
echo "vagrant_pts0_2025-11-09_19.log"

