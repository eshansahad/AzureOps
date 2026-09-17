// app/routes/alerts.js
// GET /api/alerts — currently fired/recent Azure Monitor alerts for the
// resource group, via the AlertsManagement API and managed identity.

const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');

const router = express.Router();
const credential = new DefaultAzureCredential();

const SUBSCRIPTION_ID = process.env.AZURE_SUBSCRIPTION_ID;
const RESOURCE_GROUP = process.env.AZURE_RESOURCE_GROUP || 'rg-azureops-dev';

router.get('/api/alerts', async (req, res) => {
  if (!SUBSCRIPTION_ID) {
    return res.status(500).json({ error: 'AZURE_SUBSCRIPTION_ID environment variable is not defined.' });
  }

  try {
    const tokenResponse = await credential.getToken('https://management.azure.com/.default');
    const url = `https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/providers/Microsoft.AlertsManagement/alerts` +
      `?api-version=2019-05-05-preview&targetResourceGroup=${RESOURCE_GROUP}`;

    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${tokenResponse.token}` }
    });

    if (!response.ok) {
      const detail = await response.text();
      return res.status(response.status).json({ error: 'Azure Monitor alerts request failed', detail });
    }

    const data = await response.json();
    const alerts = (data.value || []).map(a => ({
      id: a.name,
      name: a.properties?.essentials?.alertRule,
      severity: a.properties?.essentials?.severity,
      state: a.properties?.essentials?.alertState,
      monitorCondition: a.properties?.essentials?.monitorCondition,
      firedAt: a.properties?.essentials?.startDateTime
    }));

    res.status(200).json(alerts);
  } catch (err) {
    console.error('Failed to fetch alerts:', err.message);
    res.status(500).json({ error: 'Failed to fetch alerts', detail: err.message });
  }
});

module.exports = router;
