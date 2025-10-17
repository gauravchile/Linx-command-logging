# 📝 Linux Command Logger + Remote Backup

Automates **hourly command logging** for Linux users and optionally backs up logs to a remote server.  
Logs **typed commands only** (not output) with user, timestamp, current directory, TTY/IP, and command details.

---

## 🌟 Features

- Hourly log files **per user**  
- Logs include: **user, timestamp, current directory, TTY/IP, command**  
- Optional **remote backup** using `rsync`  
- Automatic **log rotation** with `logrotate`  
- Minimal performance impact  

---

## 📁 Project Structure

```
Linux_Command_Logger/
│
├─ README.md                     # Project documentation
├─ session_record_setup.sh        # Setup and configuration script
└─ /etc/profile.d/command_record.sh  # Script sourced by users' shells
```

---

## ⚙️ Setup Instructions

1. Make the setup script executable:

```bash
sudo chmod +x session_record_setup.sh
```

2. Run the setup script:

```bash
sudo ./session_record_setup.sh
```

3. Source the command logger script manually:

```bash
source /etc/profile.d/command_record.sh
```

4. Add it to all new users’ shells:

```bash
echo "source /etc/profile.d/command_record.sh" | sudo tee -a /etc/skel/.bashrc
```

> 💡 Tip: This ensures all future users automatically log commands when they log in.

---

## 🔧 Optional: Remote Backup

1. Configure remote server details in the setup script.  
2. Logs will be automatically synced via `rsync` at the configured interval.  

---

## 🎯 Skills Demonstrated

- Linux user session monitoring  
- Bash scripting for automation  
- Log rotation and management (`logrotate`)  
- Remote backup using `rsync`  
- Security-conscious logging  

---

## 💡 Best Practices

- Store logs in a secure directory with proper permissions.  
- Regularly check backup logs to ensure remote sync is working.  
- Combine with cron jobs for hourly automation.  
- Useful for **auditing, training, or lab monitoring**.
