# Linux Command Logger + Remote Backup

## Overview
This project sets up **hourly command logging** for Linux users and optionally backs up logs to a remote server. It logs **typed commands only**, not output, in the format:


## Features
- Hourly log files per user.
- Records user, timestamp, current directory, TTY/IP, and command.
- Optional remote backup using `rsync`.
- Automatic log rotation with `logrotate`.

## Setup
1. Copy the setup script to your server:

```bash
sudo chmod +x session_record_setup.sh
sudo ./session_record_setup.sh
source /etc/profile.d/command_record.sh
echo "source /etc/profile.d/command_record.sh" | sudo tee -a /etc/skel/.bashrc



