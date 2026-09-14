const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');

app.serviceBusQueue('processDeployment', {
    connection: 'ServiceBusConnection',
    queueName: 'deployment-requests',
    handler: async (message, context) => {
        context.log('Received raw message:', JSON.stringify(message));

        let payload = message;
        if (typeof message === 'string') {
            try {
                payload = JSON.parse(message);
            } catch {
                payload = { description: message };
            }
        }

        const environmentId = Number(payload?.environmentId) || 1;
        const requestedBy = String(payload?.requestedBy || 'eshan');
        const appName = String(payload?.appName || 'AzureOps Portal');

        context.log(`Attempting SQL insert for EnvironmentId: ${environmentId}, AppName: ${appName}, RequestedBy: ${requestedBy}`);

        try {
            const pool = await getPool();
            await pool.request()
                .input('EnvironmentId', sql.Int, environmentId)
                .input('AppName', sql.NVarChar(100), appName)
                .input('Status', sql.NVarChar(50), 'Completed')
                .input('RequestedBy', sql.NVarChar(100), requestedBy)
                .query(`
                    INSERT INTO dbo.Deployments (EnvironmentId, AppName, Status, RequestedBy, StartedAt, CompletedAt)
                    VALUES (@EnvironmentId, @AppName, @Status, @RequestedBy, SYSUTCDATETIME(), SYSUTCDATETIME())
                `);

            context.log(`Successfully recorded deployment for environment ${environmentId}`);
        } catch (err) {
            context.log(`Database write error: ${err.message}`);
            throw err;
        }
    }
});