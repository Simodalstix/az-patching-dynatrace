#!/bin/bash
# Install simple web application for monitoring demo

# Install nginx
dnf install -y nginx

# Create simple HTML page with system info
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>PatchLab Demo App - VM ${vm_index}</title>
    <meta http-equiv="refresh" content="30">
</head>
<body>
    <h1>PatchLab Demo Application</h1>
    <h2>VM Instance: ${vm_index}</h2>
    <p>Timestamp: <span id="timestamp"></span></p>
    <p>Hostname: $(hostname)</p>
    <p>Uptime: $(uptime)</p>
    <script>
        document.getElementById('timestamp').innerHTML = new Date().toLocaleString();
    </script>
</body>
</html>
EOF

# Start and enable nginx
systemctl start nginx
systemctl enable nginx

# Create load generation script
cat > /usr/local/bin/generate_load.sh << 'EOF'
#!/bin/bash
while true; do
    # Generate some CPU load
    dd if=/dev/zero of=/dev/null bs=1M count=100 &
    sleep 60
    pkill dd
    sleep 300
done
EOF

chmod +x /usr/local/bin/generate_load.sh

# Create systemd service for load generation
cat > /etc/systemd/system/load-generator.service << 'EOF'
[Unit]
Description=Load Generator for Monitoring Demo
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/generate_load.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable load-generator
systemctl start load-generator