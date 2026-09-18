// app/routes/environments.js
// GET  /api/environments             — list all environments (any status)
// POST /api/environments             — create a new environment
// POST /api/environments/:id/decommission — soft-delete: marks Decommissioned,
//                                      preserving Deployments/Incidents history

const express = require('express');
const router = express.Router();
const { getPool } = require('../db');
const { publishEvent } = require('../eventPublisher');

// Fetch all environments
router.get('/api/environments', async (req, res) => {
    try {
        const pool = await getPool();
        const result = await pool.request().query(
            'SELECT EnvironmentId, Name, EnvironmentType, Status, CreatedAt, DecommissionedAt FROM Environments ORDER BY EnvironmentId'
        );
        res.status(200).json(result.recordset);
    } catch (err) {
        res.status(500).json({ error: 'Database query failed', detail: err.message });
    }
});

// Create new environment
router.post('/api/environments', async (req, res) => {
    const { name, type } = req.body;
    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('name', name)
            .input('type', type)
            .query(`
                INSERT INTO Environments (Name, EnvironmentType, Status, CreatedAt)
                OUTPUT INSERTED.EnvironmentId
                VALUES (@name, @type, 'Active', GETUTCDATE())
            `);
        
        const envId = result.recordset[0].EnvironmentId;
        await publishEvent('AzureOps.Environment.Created', `environments/${envId}`, { name, type });
        
        res.status(201).json({ EnvironmentId: envId, message: 'Environment created' });
    } catch (err) {
        res.status(500).json({ error: 'Failed to create environment' });
    }
});

// Decommission (Soft Delete)
router.put('/api/environments/:id/decommission', async (req, res) => {
    const { id } = req.params;
    try {
        const pool = await getPool();
        const result = await pool.request()
            .input('id', id)
            .query(`
                UPDATE Environments
                SET Status = 'Decommissioned', DecommissionedAt = GETUTCDATE()
                OUTPUT INSERTED.Name
                WHERE EnvironmentId = @id AND Status = 'Active'
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(404).json({ error: 'Environment not found or already decommissioned.' });
        }

        const envName = result.recordset[0].Name;
        await publishEvent('AzureOps.Environment.Decommissioned', `environments/${id}`, { name: envName });

        res.status(200).json({ message: 'Environment successfully decommissioned' });
    } catch (err) {
        res.status(500).json({ error: 'Failed to decommission environment' });
    }
});

module.exports = router;