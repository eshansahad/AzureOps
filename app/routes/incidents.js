const express = require('express');
const { getPool } = require('../db');

const router = express.Router();

router.get('/api/incidents', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT 
        i.IncidentId,
        i.Description,
        i.Severity,
        i.Status,
        i.ActionTaken,
        i.DetectedAt,
        i.ResolvedAt,
        e.Name as EnvironmentName,
        d.AppName as DeploymentAppName
      FROM Incidents i
      LEFT JOIN Environments e ON i.EnvironmentId = e.EnvironmentId
      LEFT JOIN Deployments d ON i.DeploymentId = d.DeploymentId
      ORDER BY i.DetectedAt DESC
    `);
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('Failed to fetch incidents:', err.message);
    res.status(500).json({ error: 'Failed to fetch incidents', detail: err.message });
  }
});

module.exports = router;
