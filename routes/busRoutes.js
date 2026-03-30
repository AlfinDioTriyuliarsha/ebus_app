const express = require("express");
const router = express.Router();
const pool = require("../db");

router.get("/", async(req, res) => {
    try {
        const query = `
      SELECT 
        b.id,
        b.plate_number,
        b.status,
        b.latitude,
        b.longitude,
        b.updated_at,
        c.company_name
      FROM buses b
      LEFT JOIN companies c ON b.company_id = c.id
      ORDER BY b.id ASC
    `;
        console.log("➡️ Running query:", query);

        const result = await pool.query(query);
        console.log("✅ Query success, result:", result.rows);

        res.json({ data: result.rows });
    } catch (err) {
        console.error("❌ Error fetching buses:", err);
        res.status(500).json({
            error: err.message,
            stack: err.stack
        });
    }
});

module.exports = router;