// =====================================================================
// AzureOps Portal — Minimal Express server
// =====================================================================

const appInsights = require('applicationinsights');
if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights
    .setup()
    .setAutoCollectRequests(true)
    .setAutoCollectPerformance(true, true)
    .setAutoCollectExceptions(true)
    .setAutoCollectDependencies(true)
    .setSendLiveMetrics(true)
    .start();
}

const express = require('express');
const path = require('path');
const { getPool } = require('./db');

const app = express();
const port = process.env.PORT || 8080;

// Body parser for JSON payloads (required for POST /api/deployments)
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Mount routes
const deploymentsRouter = require('./routes/deployments');
const incidentsRouter = require('./routes/incidents');
const remediateRouter = require('./routes/remediate');
const eventsRouter = require('./routes/events');
const metricsRouter = require('./routes/metrics');
const alertsRouter = require('./routes/alerts');

app.use(deploymentsRouter);
app.use(incidentsRouter);
app.use(remediateRouter);
app.use(eventsRouter);
app.use(metricsRouter);
app.use(alertsRouter);

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    service: 'AzureOps Portal',
    timestamp: new Date().toISOString()
  });
});

app.get('/api/status', (req, res) => {
  res.status(200).json({
    project: 'AzureOps',
    phase: 'Phase 4 — Application Development (in progress)',
    servicesIntegrated: [
      'Microsoft Entra ID',
      'Azure Key Vault',
      'Azure SQL Database',
      'Azure App Service',
      'Azure Service Bus'
    ]
  });
});

app.get('/api/users', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(
      'SELECT UserId, DisplayName, Email, Role, CreatedAt FROM Users ORDER BY UserId'
    );
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('Database query failed:', err.message);
    res.status(500).json({ error: 'Unable to reach the database', detail: err.message });
  }
});

app.get('/api/environments', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(
      'SELECT EnvironmentId, Name, EnvironmentType, Status, CreatedAt FROM Environments ORDER BY EnvironmentId'
    );
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('Database query failed:', err.message);
    res.status(500).json({ error: 'Unable to reach the database', detail: err.message });
  }
});

app.listen(port, () => {
  console.log(`AzureOps Portal listening on port ${port}`);
});
