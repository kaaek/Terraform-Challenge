#!/bin/bash
yum update -y

# Install Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create app directory
mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

# Initialize and install Express
npm init -y
npm install express

# Create server.js
cat > server.js << 'APPEOF'
const express = require("express");
const { execSync } = require("child_process");

const app = express();
const PORT = 3000;

function getMeta(path) {
  try {
    const token = execSync(
      'curl -s -X PUT "http://169.254.169.254/latest/api/token" ' +
      '-H "X-aws-ec2-metadata-token-ttl-seconds: 21600"'
    ).toString().trim();
    return execSync(
      `curl -s -H "X-aws-ec2-metadata-token: ${token}" ` +
      `http://169.254.169.254/latest/meta-data/${path}`
    ).toString().trim();
  } catch (e) {
    return "unknown";
  }
}

app.get("/api/health", (req, res) => {
  res.json({
    status: "healthy",
    tier: "backend",
    instanceId: getMeta("instance-id"),
    availabilityZone: getMeta("placement/availability-zone"),
    timestamp: new Date().toISOString(),
  });
});

app.get("/api/data", (req, res) => {
   res.json({
     message: "Hello from the Backend Tier!",
     instanceId: getMeta("instance-id"),
     availabilityZone: getMeta("placement/availability-zone"),
     timestamp: new Date().toISOString(),
     items: [
        { id: 1, name: "VPC", description: "Virtual Private Cloud" },
        { id: 2, name: "ALB", description: "Application Load Balancer" },
        { id: 3, name: "ASG", description: "Auto Scaling Group" },
        { id: 4, name: "IAM", description: "Identity and Access Management" },
        { id: 5, name: "SSM", description: "Systems Manager Parameter Store" },
     ],
   });
});

app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});
APPEOF

# Run the server in the background
chown -R ec2-user:ec2-user /home/ec2-user/app
sudo -u ec2-user nohup node /home/ec2-user/app/server.js > /home/ec2-user/app/backend.log 2>&1 &
