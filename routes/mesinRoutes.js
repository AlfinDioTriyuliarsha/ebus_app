const express = require("express");
const router = express.Router();
const { Pool } = require("pg");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

// GET semua mesin
router.get("/", async (req, res) => {
  const { company_id } = req.query;
  try {
    const result = await pool.query(
      "SELECT * FROM mesin WHERE company_id = $1 ORDER BY id DESC",
      [company_id]
    );
    res.json({ status: "success", data: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST mesin
router.post("/", async (req, res) => {
  const { company_id, nama_mesin } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO mesin (company_id, nama_mesin) VALUES ($1, $2) RETURNING *",
      [company_id, nama_mesin]
    );
    res.status(201).json({ status: "success", data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE mesin
router.delete("/:id", async (req, res) => {
  try {
    await pool.query("DELETE FROM mesin WHERE id = $1", [req.params.id]);
    res.json({ status: "success" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;