#!/bin/bash

cat > /etc/systemd/system/atlantis-chown-disk.service <<EOF
[Unit]
Description=Chown the Atlantis mount
Wants=konlet-startup.service
After=konlet-startup.service

[Service]
ExecStart=/bin/chown 100 /mnt/disks/gce-containers-mounts/gce-persistent-disks/${disk_name}
Restart=on-failure
RestartSec=30
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

chmod 644 /etc/systemd/system/atlantis-chown-disk.service

systemctl enable /etc/systemd/system/atlantis-chown-disk.service

systemctl start --no-block atlantis-chown-disk.service

/sbin/iptables -A INPUT -p tcp --dport ${atlantis_port} -j ACCEPT