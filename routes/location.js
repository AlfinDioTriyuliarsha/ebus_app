const express = require("express");
const router = express.Router();
const pool = require("../db");

// ==================
// GET PROVINCES
// ==================
router.get("/provinces", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name FROM provinces ORDER BY name"
    );
    res.json(result.rows);
  } catch (err) {
    console.error("PROVINCES ERROR:", err);
    res.status(500).json({ error: "Failed to fetch provinces" });
  }
});

// ==================
// GET CITIES
// ==================
router.get("/cities/:province_id", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name FROM cities WHERE province_id=$1",
      [req.params.province_id]
    );

    console.log("CITIES:", result.rows);

    res.json(result.rows);
  } catch (err) {
    console.error("CITIES ERROR:", err);
    res.status(500).json({ error: "Failed to fetch cities" });
  }
});

// ==================
// GET TERMINALS (FIX)
// ==================
router.get("/terminals/:city_id", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, latitude, longitude FROM terminals WHERE city_id=$1",
      [req.params.city_id]
    );

    console.log("TERMINALS:", result.rows);

    res.json(result.rows);
  } catch (err) {
    console.error("TERMINALS ERROR:", err);
    res.status(500).json({ error: "Failed to fetch terminals" });
  }
});

// ==================
// GET CHECKPOINTS (FIX)
// ==================
router.get("/checkpoints/:city_id", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, name, latitude, longitude FROM checkpoints WHERE city_id=$1",
      [req.params.city_id]
    );

    console.log("CHECKPOINTS:", result.rows);

    res.json(result.rows);
  } catch (err) {
    console.error("CHECKPOINTS ERROR:", err);
    res.status(500).json({ error: "Failed to fetch checkpoints" });
  }
});

module.exports = router;