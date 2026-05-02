import http from 'k6/http';
import { check, sleep } from 'k6';

// Chay: k6 run -e ENDPOINT=http://<ALB-DNS> spike-test.js
const BASE_URL = __ENV.ENDPOINT || 'http://localhost';

export const options = {
  stages: [
    { duration: '30s', target: 20  },  // warm-up
    { duration: '1m',  target: 100 },  // ramp-up
    { duration: '1m',  target: 200 },  // spike
    { duration: '30s', target: 0   },  // cool-down
  ],
};

export default function () {
  const endpoints = [
    `${BASE_URL}/api/product`,
    `${BASE_URL}/api/user`,
    `${BASE_URL}/api/shopping-cart`,
  ];

  const url = endpoints[Math.floor(Math.random() * endpoints.length)];
  const res = http.get(url, { timeout: '10s' });

  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 400,
  });

  sleep(0.5);
}
