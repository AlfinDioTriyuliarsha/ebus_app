const express = require("express");
const router = express.Router();
const pool = require("../db");

// ==================
// GET PROVINCES
// ==================
router.get("/provinces", async (req, res) => {
  const result = await pool.query("SELECT * FROM provinces ORDER BY name");
  res.json(result.rows);
});

// ==================
// GET CITIES
// ==================
router.get("/cities/:province_id", async (req, res) => {
  const result = await pool.query(
    "SELECT * FROM cities WHERE province_id=$1",
    [req.params.province_id]
  );
  res.json(result.rows);
});

// ==================
// GET TERMINALS
// ==================
router.get("/terminals/:city_id", async (req, res) => {
  const result = await pool.query(
    "SELECT * FROM terminals WHERE city_id=$1",
    [req.params.city_id]
  );
  res.json(result.rows);
});

// ==================
// GET CHECKPOINTS
// ==================
router.get("/checkpoints/:city_id", async (req, res) => {
  const result = await pool.query(
    "SELECT * FROM checkpoints WHERE city_id=$1",
    [req.params.city_id]
  );
  res.json(result.rows);
});

module.exports = router;