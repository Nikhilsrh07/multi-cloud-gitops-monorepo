const express = require('express');
const path = require('path');
const client = require('prom-client');
const app = express();
const port = process.env.PORT || 8080;

client.collectDefaultMetrics({ register: client.register });

// Portfolio dashboard (static site)
app.use(express.static(path.join(__dirname, 'public')));

// Liveness probe for Kubernetes
app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

// Prometheus metrics
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Legacy API root (kept for backwards compatibility)
app.get('/api', (req, res) => {
  res.json({ status: 'success', message: "Hello from Nikhil's Multi-Cloud DevOps Portfolio!" });
});

app.listen(port, () => console.log(`Portfolio running on port ${port}`));
