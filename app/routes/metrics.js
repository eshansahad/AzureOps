// app/routes/metrics.js
// GET /api/metrics — proxies real Azure Monitor metrics (Requests, Http5xx)
// for the monitored App Service via managed identity, so the dashboard
// chart shows genuine platform data, not mock numbers.

const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');

const router = express.Router();
const credential = new DefaultAzureCredential();

const SUBSCRIPTION_ID = process.env.AZURE_SUBSCRIPTION_ID;
const RESOURCE_GROUP = process.env.AZURE_RESOURCE_GROUP || 'rg-azureops-dev';
const APP_SERVICE_NAME = process.env.MONITORED_APP_NAME || 'app-azureops-dev';

router.get('/api/metrics', async (req, res) => {
  if (!SUBSCRIPTION_ID) {
    return res.status(500).json({ error: 'AZURE_SUBSCRIPTION_ID environment variable is not defined.' });
  }

  try {
    const tokenResponse = await credential.getToken('https://management.azure.com/.default');
    const resourceId = `/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Web/sites/${APP_SERVICE_NAME}`;

    const end = new Date();
    const start = new Date(end.getTime() - 60 * 60 * 1000); // last hour
    const timespan = `${start.toISOString()}/${end.toISOString()}`;

    const url = `https://management.azure.com${resourceId}/providers/Microsoft.Insights/metrics` +
      `?api-version=2018-01-01&metricnames=Requests,Http5xx&timespan=${timespan}&interval=PT5M`;

    const response = await fetch(url, {
      headers: { Authorization: `Bearer ${tokenResponse.token}` }
    });

    if (!response.ok) {
      const detail = await response.text();
      return res.status(response.status).json({ error: 'Azure Monitor metrics request failed', detail });
    }

    const data = await response.json();

    // Reshape into { timestamps: [...], series: { Requests: [...], Http5xx: [...] } }
    let timestamps = [];
    const series = {};
    (data.value || []).forEach(metric => {
      const points = metric.timeseries?.[0]?.data || [];
      if (timestamps.length === 0) {
        timestamps = points.map(p => p.timeStamp);
      }
      series[metric.name.value] = points.map(p => p.total ?? p.average ?? 0);
    });

    res.status(200).json({ timestamps, series });
  } catch (err) {
    console.error('Failed to fetch metrics:', err.message);
    res.status(500).json({ error: 'Failed to fetch metrics', detail: err.message });
  }
});

module.exports = router;
