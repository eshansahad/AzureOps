// app/routes/deployments.js
// POST /api/deployments — enqueues a deployment request to Service Bus
// instead of writing to SQL directly, demonstrating reliable async
// messaging between the portal and the processing Function.

// app/routes/deployments.js
const express = require('express');
const { ServiceBusClient } = require('@azure/service-bus');
const { DefaultAzureCredential } = require('@azure/identity');

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

module.exports = router;