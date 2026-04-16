const express = require("express");
const router = express.Router();
const pool = require("../db");

// ================= GET =================
router.get("/", async (req, res) => {
  const { company_id } = req.query;

  try {
    const result = await pool.query(
      "SELECT * FROM mesin WHERE company_id = $1 ORDER BY id DESC",
      [company_id]
    );

    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= CREATE =================
router.post("/", async (req, res) => {
  const { company_id, nama_mesin } = req.body;

  try {
    const result = await pool.query(
      "INSERT INTO mesin (company_id, nama_mesin) VALUES ($1, $2) RETURNING *",
      [company_id, nama_mesin]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= UPDATE =================
router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { nama_mesin } = req.body;

  try {
    const result = await pool.query(
      "UPDATE mesin SET nama_mesin = $1 WHERE id = $2 RETURNING *",
      [nama_mesin, id]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ================= DELETE =================
router.delete("/:id", async (req, res) => {
  const { id } = req.params;

  try {
    await pool.query("DELETE FROM mesin WHERE id = $1", [id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;