// functions/src/functions/logPlatformEvent.js
// Event Grid triggered function: subscribes to internal platform events
// (AzureOps.Incident.Resolved, AzureOps.Deployment.Completed, ...) and now
// persists them to SQL so the portal dashboard has a genuine, queryable
// live event feed instead of events only living in App Insights traces.

const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');

app.eventGrid('logPlatformEvent', {
    handler: async (event, context) => {
        context.log(`Platform event received: ${event.eventType}`);
        context.log(`Subject: ${event.subject}`);
        context.log('Data:', JSON.stringify(event.data));

        try {
            const pool = await getPool();
            await pool.request()
                .input('eventType', sql.NVarChar(200), event.eventType)
                .input('subject', sql.NVarChar(400), event.subject || null)
                .input('payload', sql.NVarChar(sql.MAX), JSON.stringify(event.data || {}))
                .query(`
                    INSERT INTO PlatformEvents (EventType, Subject, Payload)
                    VALUES (@eventType, @subject, @payload)
                `);
        } catch (err) {
            // A failed write here should never fail event processing itself —
            // the event was already handled; this is just the audit trail.
            context.log.error('Failed to persist platform event:', err.message);
        }
    }
});
