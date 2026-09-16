const express = require('express');
const { getPool } = require('../db');

const router = express.Router();

router.post('/api/remediate', async (req, res) => {
  const { incidentId, actionTaken } = req.body || {};

  if (!incidentId) {
    return res.status(400).json({ error: 'incidentId is required' });
  }

  try {
    const pool = await getPool();
    const result = await pool.request()
      .input('incidentId', incidentId)
      .input('actionTaken', actionTaken || 'Remediated via portal')
      .query(`
        UPDATE Incidents
        SET 
          Status = 'Resolved',
          ActionTaken = @actionTaken,
          ResolvedAt = SYSUTCDATETIME()
        OUTPUT INSERTED.*
        WHERE IncidentId = @incidentId
      `);

    if (result.rowsAffected[0] === 0) {
      return res.status(404).json({ error: 'Incident not found' });
    }

    res.status(200).json(result.recordset[0]);
  } catch (err) {
    console.error('Failed to remediate incident:', err.message);
    res.status(500).json({ error: 'Failed to remediate incident', detail: err.message });
  }
});

module.exports = router;
