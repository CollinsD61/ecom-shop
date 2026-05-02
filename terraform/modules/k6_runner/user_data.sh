#!/bin/bash
set -euo pipefail
exec > /var/log/user-data.log 2>&1

echo "==> Update packages"
dnf update -y

echo "==> Install k6"
cat > /etc/yum.repos.d/grafana-k6.repo << 'REPO'
[grafana-k6]
name=Grafana k6
baseurl=https://dl.k6.io/rpm/
repo_gpgcheck=1
gpgcheck=0
gpgkey=https://dl.k6.io/key.gpg
enabled=1
REPO

dnf install -y k6 git jq curl

echo "==> Verify k6"
k6 version

echo "==> Create k6 scripts directory"
mkdir -p /home/ec2-user/k6-scripts
chown ec2-user:ec2-user /home/ec2-user/k6-scripts

echo "==> Write spike-test.js"
cat > /home/ec2-user/k6-scripts/spike-test.js << 'SCRIPT'
import http from 'k6/http';
import { check, sleep } from 'k6';

// Chay: k6 run -e ENDPOINT=http://<ALB-DNS> spike-test.js
const BASE_URL = __ENV.ENDPOINT || 'http://localhost';

export const options = {
  stages: [
    { duration: '30s', target: 20  },
    { duration: '1m',  target: 100 },
    { duration: '1m',  target: 200 },
    { duration: '30s', target: 0   },
  ],
};

export default function () {
  const endpoints = [
    BASE_URL + '/api/product',
    BASE_URL + '/api/user',
    BASE_URL + '/api/shopping-cart',
  ];
  const url = endpoints[Math.floor(Math.random() * endpoints.length)];
  const res = http.get(url, { timeout: '10s' });
  check(res, { 'status 2xx': (r) => r.status >= 200 && r.status < 400 });
  sleep(0.5);
}
SCRIPT

chown ec2-user:ec2-user /home/ec2-user/k6-scripts/spike-test.js
echo "==> Done. k6 ready."
echo "    SSH in, then run: k6 run -e ENDPOINT=http://<ALB> ~/k6-scripts/spike-test.js"
