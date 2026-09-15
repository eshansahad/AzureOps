// functions/src/eventPublisher.js
// Shared helper: publishes internal platform events to the Event Grid
// custom topic using managed identity (no keys). Import and call this
// from remediate.js and processDeployment.js after a successful write,
// so components communicate via genuine pub/sub rather than direct calls.

const { EventGridPublisherClient } = require('@azure/eventgrid');
const { DefaultAzureCredential } = require('@azure/identity');

const TOPIC_ENDPOINT = process.env.EVENT_GRID_TOPIC_ENDPOINT; // e.g. https://eg-azureops-dev.centralus-1.eventgrid.azure.net/api/events

let client;
function getClient() {
    if (!client) {
        client = new EventGridPublisherClient(TOPIC_ENDPOINT, 'EventGrid', new DefaultAzureCredential());
    }
    return client;
}

/**
 * @param {string} eventType e.g. 'AzureOps.Incident.Resolved', 'AzureOps.Deployment.Completed'
 * @param {string} subject   e.g. 'incidents/3', 'deployments/47'
 * @param {object} data      event payload
 */
async function publishEvent(eventType, subject, data) {
    if (!TOPIC_ENDPOINT) {
        console.warn('EVENT_GRID_TOPIC_ENDPOINT not set — skipping event publish');
        return;
    }
    try {
        await getClient().send([
            {
                eventType,
                subject,
                dataVersion: '1.0',
                data
            }
        ]);
    } catch (err) {
        // A failed publish should never fail the primary operation (the SQL
        // write already succeeded) — log and move on.
        console.error(`Failed to publish event ${eventType}:`, err.message);
    }
}

module.exports = { publishEvent };
