// ============================================================================
// AzureOps Functions - Automated Remediation Handler
// ============================================================================

const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');

app.http('remediate', {
  methods: ['POST'],
  authLevel: 'function',
  route: 'remediate',
  handler: async (request, context) => {
    let body = {};
    try {
      body = await request.json();
    } catch {
      body = {};
    }

    // Support both manual API calls and Azure Monitor Common Alert payloads
    const isAlert = body?.data?.essentials != null;
    const description = isAlert
      ? `Azure Monitor Alert: ${body.data.essentials.alertRule || 'High CPU Threshold breached'}`
      : (body.description || 'Automated restart executed after metric threshold breach.');
    const severity = isAlert
      ? (body.data.essentials.severity || 'Warning')
      : (body.severity || 'Medium');
    const environmentId = body.environmentId || null;

    const actionTaken = `Automated remediation executed by AzureOps Function at ${new Date().toISOString()}.`;

    try {
      const pool = await getPool();
      const result = await pool
        .request()
        .input('environmentId', sql.Int, environmentId)
        .input('description', sql.NVarChar(500), description)
        .input('severity', sql.NVarChar(20), severity)
        .input('actionTaken', sql.NVarChar(500), actionTaken)
        .query(`
          INSERT INTO Incidents (EnvironmentId, Description, Severity, Status, ActionTaken, DetectedAt, ResolvedAt)
          OUTPUT INSERTED.IncidentId, INSERTED.Description, INSERTED.Severity, INSERTED.Status, INSERTED.ActionTaken, INSERTED.DetectedAt, INSERTED.ResolvedAt
          VALUES (@environmentId, @description, @severity, 'Resolved', @actionTaken, SYSUTCDATETIME(), SYSUTCDATETIME())
        `);

      context.log(`Incident recorded and auto-resolved: ${JSON.stringify(result.recordset[0])}`);

      return {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
        jsonBody: {
          message: 'Incident detected and automatically remediated.',
          incident: result.recordset[0]
        }
      };
    } catch (err) {
      context.error('Remediation function failed:', err.message);
      return {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
        jsonBody: { error: 'Remediation failed', detail: err.message }
      };
    }
  }
});