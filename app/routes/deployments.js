// app/routes/deployments.js
// POST /api/deployments — enqueues a deployment request to Service Bus
// instead of writing to SQL directly, demonstrating reliable async
// messaging between the portal and the processing Function.
// GET /api/deployments — recent deployment history, so the dashboard can
// show a request actually moving from Queued to Completed.

const express = require('express');
const { ServiceBusClient } = require('@azure/service-bus');
const { DefaultAzureCredential } = require('@azure/identity');
const { getPool } = require('../db');

const router = express.Router();

let sender = null;

function getSender() {
  if (!sender) {
    const namespace = (process.env.SERVICE_BUS_NAMESPACE || '').trim();
    if (!namespace) {
      throw new Error('SERVICE_BUS_NAMESPACE environment variable is not defined.');
    }
    const fullyQualifiedNamespace = namespace.includes('.servicebus.windows.net')
      ? namespace
      : `${namespace}.servicebus.windows.net`;

    const credential = new DefaultAzureCredential();
    const sbClient = new ServiceBusClient(fullyQualifiedNamespace, credential);
    sender = sbClient.createSender('deployment-requests');
  }
  return sender;
}

router.post('/api/deployments', async (req, res) => {
  const { environmentId, requestedBy, description } = req.body || {};

  if (!environmentId || !requestedBy) {
    return res.status(400).json({ error: 'environmentId and requestedBy are required' });
  }

  try {
    const queueSender = getSender();
    await queueSender.sendMessages({
      body: { environmentId, requestedBy, description },
      contentType: 'application/json'
    });

    return res.status(202).json({
      status: 'queued',
      environmentId,
      requestedBy
    });
  } catch (err) {
    console.error('Failed to enqueue deployment request:', err.message);
    return res.status(500).json({
      error: 'Failed to queue deployment request',
      detail: err.message
    });
  }
});

router.get('/api/deployments', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT TOP 15
        d.DeploymentId,
        d.EnvironmentId,
        e.Name AS EnvironmentName,
        d.AppName,
        d.RequestedBy,
        d.Status,
        d.StartedAt,
        d.CompletedAt
      FROM Deployments d
      LEFT JOIN Environments e ON d.EnvironmentId = e.EnvironmentId
      ORDER BY d.StartedAt DESC
    `);
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('Failed to fetch deployments:', err.message);
    res.status(500).json({ error: 'Failed to fetch deployments', detail: err.message });
  }
});

module.exports = router;
