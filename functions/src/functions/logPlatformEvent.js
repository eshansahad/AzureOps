// functions/src/functions/logPlatformEvent.js
// Event Grid triggered function: subscribes to internal platform events
// (AzureOps.Incident.Resolved, AzureOps.Deployment.Completed, ...) and
// logs them. Fully decoupled from remediate.js and processDeployment.js —
// it has no idea who published the event, only that it happened.

const { app } = require('@azure/functions');

app.eventGrid('logPlatformEvent', {
    handler: async (event, context) => {
        context.log(`Platform event received: ${event.eventType}`);
        context.log(`Subject: ${event.subject}`);
        context.log('Data:', JSON.stringify(event.data));

        // Placeholder for future subscribers (e.g. notifications, audit
        // trail table) — for now, App Insights traces are the record.
    }
});
