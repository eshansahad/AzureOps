// functions/src/functions/processDeployment.js
// Service Bus triggered function: consumes deployment-request messages
// enqueued by the portal and writes the corresponding Deployments record.
// Decouples the portal's write path from the database write via async
// reliable messaging (Service Bus queue: deployment-requests).

const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');

app.serviceBusQueue('processDeployment', {
    connection: 'ServiceBusConnection',
    queueName: 'deployment-requests',
    handler: async (message, context) => {
        context.log('Received deployment request:', JSON.stringify(message));

        const { environmentId, requestedBy, appName, description } = message || {};

        if (!environmentId || !requestedBy) {
            context.error('Invalid deployment message: missing environmentId or requestedBy');
            return;
        }

        try {
            const pool = await getPool();
            await pool.request()
                .input('EnvironmentId', sql.Int, environmentId)
                .input('AppName', sql.NVarChar(100), appName || 'AzureOps Portal')
                .input('RequestedBy', sql.NVarChar(100), requestedBy)
                .input('Status', sql.NVarChar(50), 'Completed')
                .query(`
                    INSERT INTO Deployments (EnvironmentId, AppName, RequestedBy, Status, StartedAt, CompletedAt)
                    VALUES (@EnvironmentId, @AppName, @RequestedBy, @Status, SYSUTCDATETIME(), SYSUTCDATETIME())
                `);

            context.log(`Deployment recorded for environment ${environmentId}`);
        } catch (err) {
            context.error('Failed to record deployment from Service Bus message:', err.message);
            throw err;
        }
    }
});