const express = require("express");
const router = express.Router();
const pool = require("../db");


router.get("/user/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      "SELECT * FROM drivers WHERE user_id = $1 LIMIT 1",
      [user_id]
    );

    res.json({
      success: true,
      data: result.rows[0] || null,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

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
    const { company_id, driver_name, kontak, user_id } = req.body;

    const result = await pool.query(
      `INSERT INTO drivers (company_id, driver_name, kontak, user_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [company_id, driver_name, kontak, user_id]
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


// ================= AUTO CREATE DRIVER (LOGIN) =================
router.post("/auto-create", async (req, res) => {
  try {
    const { user_id, email } = req.body;

    // cek apakah driver sudah ada
    const check = await pool.query(
      "SELECT * FROM drivers WHERE user_id = $1",
      [user_id]
    );

    if (check.rows.length > 0) {
      return res.json({
        success: true,
        data: check.rows[0],
        message: "Driver sudah ada",
      });
    }

    // kalau belum → buat otomatis
    const insert = await pool.query(
      `INSERT INTO drivers (user_id, driver_name, kontak, company_id)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [
        user_id,
        email, // pakai email jadi nama default
        "-",
        1 // sementara default company (nanti bisa diubah)
      ]
    );

    res.json({
      success: true,
      data: insert.rows[0],
      message: "Driver berhasil dibuat otomatis",
    });

  } catch (err) {
    console.error("ERROR AUTO CREATE DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});


// ================= GET DRIVER BY USER =================
router.get("/by-user/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      "SELECT * FROM drivers WHERE user_id = $1",
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: false,
        message: "Driver tidak ditemukan",
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error("ERROR GET DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ================= REGISTER DRIVER (DARI MOBILE) =================
router.post("/register", async (req, res) => {
  try {
    const { user_id, email, company_id } = req.body;

    // cek apakah sudah ada
    const check = await pool.query(
      "SELECT * FROM drivers WHERE user_id = $1",
      [user_id]
    );

    if (check.rows.length > 0) {
      return res.json({
        success: false,
        message: "Driver sudah terdaftar",
      });
    }

    const result = await pool.query(
      `INSERT INTO drivers (user_id, company_id, driver_name, kontak)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [user_id, company_id, email, email]
    );

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error("REGISTER DRIVER ERROR:", err);
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