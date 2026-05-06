const express = require("express");
const router = express.Router();
const pool = require("../db");

// ==================
// PROVINCES
// ==================
router.get("/provinces", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM provinces");

    res.json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error("PROVINCES ERROR:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==================
// CITIES
// ==================
router.get("/cities/:provinceId", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM cities WHERE province_id = $1",
      [req.params.provinceId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error("CITIES ERROR:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==================
// TERMINALS
// ==================
router.get("/terminals/:cityId", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM terminals WHERE city_id = $1",
      [req.params.cityId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (err) {
    console.error("TERMINALS ERROR:", err);
    res.status(500).json({ success: false, error: err.message });
  }
});

// ==================
// CHECKPOINTS
// ==================
router.get("/checkpoints/:cityId", async (req, res) => {
  const result = await pool.query(
    "SELECT * FROM checkpoints"
  );

  res.json({
    success: true,
    data: result.rows
  });
});

module.exports = router;