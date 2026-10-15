const express = require('express');
const path = require('path');
const client = require('prom-client');
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-proto');
const { resourceFromAttributes } = require('@opentelemetry/resources');

const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || process.env.OTEL_EXPORTER_OTLP_TRACES_ENDPOINT || 'http://localhost:4318/v1/traces';

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    'service.name': process.env.OTEL_SERVICE_NAME || 'portfolio-app'
  }),
  traceExporter: new OTLPTraceExporter({ url: otlpEndpoint }),
  instrumentations: [getNodeAutoInstrumentations()]
});

sdk.start();

const app = express();
const port = process.env.PORT || 8080;

client.collectDefaultMetrics({ register: client.register });

app.use(express.static(path.join(__dirname, 'public')));

app.get('/healthz', (req, res) => {
  res.json({ status: 'ok' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.get('/api', (req, res) => {
  res.json({ status: 'success', message: "Hello from Nikhil's Multi-Cloud DevOps Portfolio!" });
});

app.listen(port, () => console.log(`Portfolio running on port ${port}`));

process.on('SIGTERM', async () => {
  await sdk.shutdown();
  process.exit(0);
});
