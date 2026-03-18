#!/bin/bash
yum update -y
yum install -y nginx

# Create the frontend HTML
cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Two-Tier App</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Arial, sans-serif; background: #f0f2f5;
            color: #333; padding: 40px 20px; }
    .container { max-width: 800px; margin: 0 auto; }
    h1 { color: #232F3E; margin-bottom: 8px; }
    .subtitle { color: #666; margin-bottom: 30px; }
    .card { background: white; border-radius: 8px; padding: 24px;
             margin-bottom: 20px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .card h2 { font-size: 18px; color: #1A73E8; margin-bottom: 12px; }
    .status { display: inline-block; padding: 4px 12px; border-radius: 12px;
               font-size: 14px; font-weight: bold; }
    .status.healthy { background: #E8F5E9; color: #1B7D40; }
    .status.error { background: #FFEBEE; color: #C62828; }
    .meta { color: #666; font-size: 14px; margin-top: 8px; }
    table { width: 100%; border-collapse: collapse; margin-top: 12px; }
    th { background: #232F3E; color: white; padding: 10px 12px;
          text-align: left; }
    td { padding: 10px 12px; border-bottom: 1px solid #eee; }
    tr:hover { background: #f5f5f5; }
    .loading { color: #999; font-style: italic; }
  </style>
</head>
<body>
<div class="container">
  <!-- CHANGE THE NAME BELOW TO YOUR FULL NAME -->
  <h1>Two-Tier App &mdash; [YOUR NAME HERE]</h1>
  <p class="subtitle">Web Tier &rarr; Nginx Reverse Proxy &rarr; Backend API</p>
  <div class="card">
    <h2>Backend Health Check</h2>
    <div id="health"><span class="loading">Checking backend...</span></div>
  </div>
  <div class="card">
    <h2>Backend Data</h2>
    <div id="data"><span class="loading">Fetching data...</span></div>
  </div>
</div>
<script>
  fetch("/api/health")
    .then(r => r.json())
    .then(d => {
       document.getElementById("health").innerHTML = `
         <span class="status healthy">${d.status}</span>
         <div class="meta">
           Instance: ${d.instanceId}<br>
           AZ: ${d.availabilityZone}<br>
           Time: ${d.timestamp}
         </div>`;
    })
    .catch(() => {
       document.getElementById("health").innerHTML =
         '<span class="status error">unreachable</span>';
    });

  fetch("/api/data")
    .then(r => r.json())
    .then(d => {
       let rows = d.items.map(i =>
         `<tr><td>${i.id}</td><td>${i.name}</td><td>${i.description}</td></tr>`
       ).join("");
       document.getElementById("data").innerHTML = `
         <p>${d.message}</p>
         <div class="meta">
           Instance: ${d.instanceId} | AZ: ${d.availabilityZone}</div>
         <table>
           <tr><th>ID</th><th>Name</th><th>Description</th></tr>
           ${rows}
         </table>`;
    })
    .catch(() => {
       document.getElementById("data").innerHTML =
         '<span class="status error">Failed to load data</span>';
    });
</script>
</body>
</html>
HTMLEOF

# Configure Nginx reverse proxy
cat > /etc/nginx/conf.d/reverse-proxy.conf << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /api/ {
        proxy_pass http://BACKEND_IP:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINXEOF

# Remove the default server block to avoid conflicts
rm -f /etc/nginx/conf.d/default.conf
sed -i '/^\s*server\s*{/,/^\s*}/d' /etc/nginx/nginx.conf 2>/dev/null || true

# Start Nginx
systemctl start nginx
systemctl enable nginx
