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
// routes/routeRoutes.js
router.post("/", async (req, res) => {
    const { company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi } = req.body;
    
    // Validasi sederhana supaya tidak error saat query
    if (!company_id || !nama_rute) {
        return res.status(400).json({ status: "error", message: "Data tidak lengkap" });
    }

    try {
        const result = await pool.query(
            "INSERT INTO routes (company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi) VALUES ($1, $2, $3, $4, $5) RETURNING *",
            [company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi]
        );
        
        // PASTIKAN .status(201)
        res.status(201).json({ 
            status: "success", 
            data: result.rows[0] 
        });
    } catch (err) {
        console.error("DB Error:", err.message);
        res.status(500).json({ status: "error", message: err.message });
    }
});

// CREATE ROUTE OTOMATIS
router.post("/auto-route", async (req, res) => {
    try {
        const { nama_rute, start, end } = req.body;

        // start & end format:
        // { lat: -7.98, lng: 112.62 }

        const routePoints = await generateRoute(start, end);

        const result = await pool.query(
            `INSERT INTO routes (nama_rute, path)
             VALUES ($1, $2)
             RETURNING *`,
            [nama_rute, JSON.stringify(routePoints)]
        );

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("AUTO ROUTE ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

router.get("/direction", async (req, res) => {
    try {
        const { start_lat, start_lng, end_lat, end_lng } = req.query;

        if (!start_lat || !start_lng || !end_lat || !end_lng) {
            return res.status(400).json({
                success: false,
                error: "Parameter tidak lengkap",
            });
        }

        const route = await routeService.getRoute(
            { lat: start_lat, lng: start_lng },
            { lat: end_lat, lng: end_lng }
        );

        res.json({
            success: true,
            data: route,
        });

    } catch (err) {
        console.error("ROUTE ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message,
        });
    }
});

module.exports = router;