const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');
const { publishEvent } = require('../eventPublisher');
const { uploadDeploymentReport } = require('../reportStorage');

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
        const description = String(payload?.description || '');

        context.log(`Attempting SQL insert for EnvironmentId: ${environmentId}, AppName: ${appName}, RequestedBy: ${requestedBy}`);

        try {
            const pool = await getPool();
            const result = await pool.request()
                .input('EnvironmentId', sql.Int, environmentId)
                .input('AppName', sql.NVarChar(100), appName)
                .input('Status', sql.NVarChar(50), 'Completed')
                .input('RequestedBy', sql.NVarChar(100), requestedBy)
                .query(`
                    INSERT INTO dbo.Deployments (EnvironmentId, AppName, Status, RequestedBy, StartedAt, CompletedAt)
                    OUTPUT INSERTED.DeploymentId
                    VALUES (@EnvironmentId, @AppName, @Status, @RequestedBy, SYSUTCDATETIME(), SYSUTCDATETIME())
                `);

            const deploymentId = result.recordset[0].DeploymentId;

            await publishEvent('AzureOps.Deployment.Completed', `deployments/${environmentId}`, { environmentId, appName, requestedBy });

            await uploadDeploymentReport(deploymentId, {
                environmentId,
                requestedBy,
                description: `Automated deployment for ${appName}`,
                status: 'Completed'
            });

            context.log(`Successfully recorded deployment for environment ${environmentId}`);
        } catch (err) {
            context.log(`Database write error: ${err.message}`);
            throw err;
        }
    }
});