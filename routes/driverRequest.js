const express = require("express");
const router = express.Router();
const pool = require("../db");

// =======================
// CREATE REQUEST (DRIVER)
// =======================
router.post("/", async (req, res) => {
    const { driver_id, company_id } = req.body;

    try {
        const result = await pool.query(
            `INSERT INTO driver_requests (driver_id, company_id)
             VALUES ($1, $2) RETURNING *`,
            [driver_id, company_id]
        );

        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: err.message });
    }
});

// =======================
// GET REQUEST (ADMIN)
// =======================
router.get("/", async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT dr.*, d.driver_name
            FROM driver_requests dr
            JOIN drivers d ON dr.driver_id = d.id
            WHERE dr.status = 'pending'
        `);

        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// =======================
// APPROVE REQUEST
// =======================
router.put("/approve/:id", async (req, res) => {
    const { id } = req.params;
    const { bus_id } = req.body;

    try {
        const reqData = await pool.query(
            "SELECT * FROM driver_requests WHERE id=$1",
            [id]
        );

        const driver_id = reqData.rows[0].driver_id;

        // assign ke bus
        await pool.query(
            "UPDATE buses SET driver_id=$1 WHERE id=$2",
            [driver_id, bus_id]
        );

        // update status
        await pool.query(
            "UPDATE driver_requests SET status='approved' WHERE id=$1",
            [id]
        );

        res.json({ success: true });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;