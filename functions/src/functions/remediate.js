// =====================================================================
// AzureOps Functions — remediate
//
// Simulates the architecture's "detect an incident -> trigger automated
// remediation -> record the outcome" flow. In a full implementation
// this would be triggered by an Azure Monitor alert or Event Grid
// event; here it's exposed as an HTTP endpoint so it can be triggered
// and demonstrated directly.
//
// POST body: { "environmentId": 1, "description": "...", "severity": "Medium" }
// =====================================================================

const { app } = require('@azure/functions');
const { getPool, sql } = require('../db');

app.http('remediate', {
  methods: ['POST'],
  authLevel: 'function',
  route: 'remediate',
  handler: async (request, context) => {
    let body;
    try {
      body = await request.json();
    } catch {
      return { status: 400, jsonBody: { error: 'Request body must be valid JSON.' } };
    }

    const { environmentId = null, description, severity = 'Medium' } = body || {};

    if (!description) {
      return { status: 400, jsonBody: { error: '"description" is required.' } };
    }

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
        jsonBody: {
          message: 'Incident detected and automatically remediated.',
          incident: result.recordset[0]
        }
      };
    } catch (err) {
      context.error('Remediation function failed:', err.message);
      return {
        status: 500,
        jsonBody: { error: 'Remediation failed', detail: err.message }
      };
    }
  }
});
