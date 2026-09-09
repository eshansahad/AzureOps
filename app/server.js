// =====================================================================
// AzureOps Portal — Minimal Express server
// Serves a placeholder dashboard + health check endpoint.
// Will be extended with API routes (environments, deployments,
// incidents) and Entra ID authentication in later phases.
// =====================================================================

const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 8080;

app.use(express.static(path.join(__dirname, 'public')));

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
      'Azure App Service'
    ]
  });
});

app.listen(port, () => {
  console.log(`AzureOps Portal listening on port ${port}`);
});
