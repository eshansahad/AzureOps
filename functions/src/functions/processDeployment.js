const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');

app.serviceBusQueue('processDeployment', {
    connection: 'ServiceBusConnection',
    queueName: 'deployment-requests',
    handler: async (message, context) => {
        context.log('Raw incoming message:', message);

        let data = message;
        if (typeof message === 'string') {
            try {
                data = JSON.parse(message);
            } catch {
                data = { description: message };
            }
        }

        const environmentId = Number(data?.environmentId) || 1;
        const requestedBy = String(data?.requestedBy || 'eshan');
        const appName = String(data?.appName || 'AzureOps Portal');

        context.log(`Processing deployment for env: ${environmentId}, user: ${requestedBy}`);

        try {
            const pool = await getPool();
            const request = pool.request();
            
            request.input('EnvironmentId', sql.Int, environmentId);
            request.input('AppName', sql.NVarChar(100), appName);
            request.input('Status', sql.NVarChar(50), 'Completed');
            request.input('RequestedBy', sql.NVarChar(100), requestedBy);

            await request.query(`
                INSERT INTO Deployments (EnvironmentId, AppName, Status, RequestedBy, StartedAt, CompletedAt)
                VALUES (@EnvironmentId, @AppName, @Status, @RequestedBy, SYSUTCDATETIME(), SYSUTCDATETIME())
            `);

            context.log(`Successfully recorded deployment for environment ${environmentId}`);
        } catch (err) {
            context.error('SQL Execution Error:', err.message);
            throw err;
        }
    }
});