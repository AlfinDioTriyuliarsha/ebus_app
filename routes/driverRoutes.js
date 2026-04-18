const express = require("express");
const router = express.Router();
const pool = require("../db");


// ================= GET DRIVERS =================
router.get("/", async (req, res) => {
  try {
    const { company_id } = req.query;

    const result = await pool.query(
      "SELECT * FROM drivers WHERE company_id = $1 ORDER BY id ASC",
      [company_id]
    );

    res.json({
      success: true,
      data: result.rows,
    });
  } catch (err) {
    console.error("ERROR DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ================= CREATE DRIVER =================
router.post("/", async (req, res) => {
  try {
    const { company_id, driver_name, kontak } = req.body;

    const result = await pool.query(
      `INSERT INTO drivers (company_id, driver_name, kontak)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [company_id, driver_name, kontak]
    );

    res.status(201).json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error("ERROR CREATE DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ================= UPDATE DRIVER =================
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { driver_name, kontak } = req.body;

    const result = await pool.query(
      `UPDATE drivers 
       SET driver_name = $1, kontak = $2 
       WHERE id = $3 
       RETURNING *`,
      [driver_name, kontak, id]
    );

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error("ERROR UPDATE DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ================= DELETE DRIVER =================
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    await pool.query("DELETE FROM drivers WHERE id = $1", [id]);

    res.json({
      success: true,
      message: "Driver berhasil dihapus",
    });
  } catch (err) {
    console.error("ERROR DELETE DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

module.exports = router;