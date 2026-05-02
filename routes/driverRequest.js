const express = require("express");
const router = express.Router();
const pool = require("../db");

// CREATE REQUEST
router.post("/", async (req, res) => {
  const { user_id, company_id } = req.body;

  try {
    await pool.query(
      "INSERT INTO driver_requests (user_id, company_id) VALUES ($1,$2)",
      [user_id, company_id]
    );

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET REQUEST
router.get("/", async (req, res) => {
  const result = await pool.query(`
    SELECT dr.*, u.email
    FROM driver_requests dr
    JOIN users u ON dr.user_id = u.id
    WHERE dr.status = 'pending'
  `);

  res.json({ success: true, data: result.rows });
});

// APPROVE
router.put("/approve/:id", async (req, res) => {
  const { id } = req.params;

  const reqData = await pool.query(
    "SELECT * FROM driver_requests WHERE id=$1",
    [id]
  );

  const r = reqData.rows[0];

  // MASUKKAN KE TABLE DRIVERS
  await pool.query(
    "INSERT INTO drivers (company_id, driver_name) VALUES ($1,$2)",
    [r.company_id, "Driver Baru"]
  );

  await pool.query(
    "UPDATE driver_requests SET status='approved' WHERE id=$1",
    [id]
  );

  res.json({ success: true });
});

module.exports = router;