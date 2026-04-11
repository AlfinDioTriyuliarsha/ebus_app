const express = require("express");
const router = express.Router();
const { Pool } = require("pg");

// Hubungkan ke database (Gunakan pool yang sama)
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// Ambil semua rute berdasarkan company_id
router.get("/", async (req, res) => {
    const { company_id } = req.query;
    try {
        const result = await pool.query(
            "SELECT * FROM routes WHERE company_id = $1 ORDER BY id DESC", 
            [company_id]
        );
        res.status(200).json({ status: "success", data: result.rows });
    } catch (err) {
        res.status(500).json({ status: "error", message: err.message });
    }
});

// Tambah rute baru
router.post("/", async (req, res) => {
    const { company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi } = req.body;
    try {
        const result = await pool.query(
            "INSERT INTO routes (company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi) VALUES ($1, $2, $3, $4, $5) RETURNING *",
            [company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi]
        );
        res.status(201).json({ status: "success", data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ status: "error", message: err.message });
    }
});

module.exports = router;