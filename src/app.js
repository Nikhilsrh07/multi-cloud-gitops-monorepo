const express = require('express');
const client = require('prom-client');
const app = express();
const port = process.env.PORT || 8080;

client.collectDefaultMetrics({ register: client.register });

app.get('/', (req, res) => {
  res.json({ status: "success", message: "Hello from Nikhil's Multi-Cloud DevOps Portfolio!" });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.listen(port, () => console.log(`Application running dynamically on port ${port}`));
