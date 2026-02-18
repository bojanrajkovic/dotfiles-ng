#!/bin/bash
set -euo pipefail

echo "Installing Samba..."
sudo dnf install -y samba

echo "Configuring Samba..."
sudo tee /etc/samba/smb.conf > /dev/null <<'SMBCONF'
[global]
    workgroup = WORKGROUP
    server string = Samba on %h
    security = user
    map to guest = Never
    log file = /var/log/samba/log.%m
    max log size = 1000

    # Apple extensions
    vfs objects = catia fruit streams_xattr
    fruit:metadata = stream
    fruit:model = MacSamba
    fruit:encoding = native
    fruit:nfs_aces = no
    fruit:zero_file_id = yes
    fruit:wipe_intentionally_left_blank_rfork = yes
    fruit:delete_empty_adfiles = yes
    fruit:copyfile = yes

    # Protocol
    min protocol = SMB2
    ea support = yes

[homes]
    comment = Home Directories
    browseable = no
    read only = no
    valid users = %S
    create mask = 0644
    directory mask = 0755
SMBCONF

echo "Configuring SELinux..."
sudo setsebool -P samba_enable_home_dirs on

echo "Enabling and restarting Samba..."
sudo systemctl enable --now smb
sudo systemctl restart smb

if command -v firewall-cmd &>/dev/null; then
    echo "Configuring firewall..."
    sudo firewall-cmd --permanent --add-service=samba
    sudo firewall-cmd --reload
fi

if ! sudo pdbedit -L 2>/dev/null | grep -q "^$USER:"; then
    if [ -t 0 ]; then
        echo "Setting Samba password for $USER..."
        sudo smbpasswd -a "$USER"
    else
        echo "NOTE: Run 'sudo smbpasswd -a $USER' to set your Samba password."
    fi
fi

echo "Done!"
