// =====================================================================
// AzureOps Functions — listIncidents
// Returns the most recent incidents, including any created by the
// remediate function. Useful for verifying the remediation flow
// end-to-end without needing the SQL Query editor.
// =====================================================================

const { app } = require('@azure/functions');
const { getPool } = require('../db');

app.http('listIncidents', {
  methods: ['GET'],
  authLevel: 'function',
  route: 'incidents',
  handler: async (request, context) => {
    try {
      const pool = await getPool();
      const result = await pool.request().query(`
        SELECT TOP 20 IncidentId, EnvironmentId, Description, Severity, Status, ActionTaken, DetectedAt, ResolvedAt
        FROM Incidents
        ORDER BY IncidentId DESC
      `);
      return { status: 200, jsonBody: result.recordset };
    } catch (err) {
      context.error('listIncidents failed:', err.message);
      return { status: 500, jsonBody: { error: 'Unable to reach the database', detail: err.message } };
    }
  }
});
