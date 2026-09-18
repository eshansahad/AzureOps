// app/eventPublisher.js
// Publishes internal platform events to Event Grid using managed identity —
// the App Service side of the same pattern already used in
// functions/src/eventPublisher.js. Having both sides of the platform able
// to publish (not just Functions) shows the pub/sub model is genuinely
// shared infrastructure, not one component's private plumbing.

const { EventGridPublisherClient } = require("@azure/eventgrid");
const { DefaultAzureCredential } = require("@azure/identity");

const endpoint = process.env.EVENT_GRID_TOPIC_ENDPOINT;
let client;

if (endpoint) {
    client = new EventGridPublisherClient(endpoint, "EventGrid", new DefaultAzureCredential());
}

async function publishEvent(eventType, subject, data) {
    if (!client) {
        console.warn("EVENT_GRID_TOPIC_ENDPOINT not set. Skipping event publish.");
        return;
    }
    try {
        await client.send([{
            eventType: eventType,
            subject: subject,
            dataVersion: "1.0",
            data: data,
            eventTime: new Date()
        }]);
        console.log(`Successfully published event: ${eventType}`);
    } catch (error) {
        console.error("Error publishing event:", error.message);
    }
}

module.exports = { publishEvent };