// app/routes/events.js
// GET /api/events — recent platform events (published via Event Grid,
// persisted by logPlatformEvent.js) for the dashboard's live feed.

const express = require('express');
const { getPool } = require('../db');

const router = express.Router();

router.get('/api/events', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT TOP 20 EventId, EventType, Subject, Payload, OccurredAt
      FROM PlatformEvents
      ORDER BY OccurredAt DESC
    `);
    res.status(200).json(result.recordset);
  } catch (err) {
    console.error('Failed to fetch events:', err.message);
    res.status(500).json({ error: 'Failed to fetch events', detail: err.message });
  }
});

module.exports = router;
