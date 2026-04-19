const express = require("express");
const router = express.Router();
const { Pool } = require("pg");

// ❌ HAPUS INI (BIKIN ERROR)
// const routeService = require("../services/routeService");

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});


// =======================
// GET ROUTES
// =======================
router.get("/", async (req, res) => {
    const { company_id } = req.query;

    try {
        const result = await pool.query(
            "SELECT * FROM routes WHERE company_id = $1 ORDER BY id DESC",
            [company_id]
        );

        res.status(200).json({
            success: true,
            data: result.rows
        });

    } catch (err) {
        console.error("GET ROUTES ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// CREATE ROUTE MANUAL
// =======================
router.post("/", async (req, res) => {
    const {
        company_id,
        nama_rute,
        titik_awal,
        titik_tujuan,
        jarak_estimasi
    } = req.body;

    if (!company_id || !nama_rute) {
        return res.status(400).json({
            success: false,
            error: "Data tidak lengkap"
        });
    }

    try {
        const result = await pool.query(
            `INSERT INTO routes 
            (company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi) 
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *`,
            [company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("CREATE ROUTE ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// AUTO ROUTE (DUMMY VERSION - NO ERROR)
// =======================
router.post("/auto-route", async (req, res) => {
    try {
        const { nama_rute, start, end } = req.body;

        if (!start || !end) {
            return res.status(400).json({
                success: false,
                error: "Start dan End wajib diisi"
            });
        }

        // 🔥 DUMMY ROUTE (biar tidak error dulu)
        const routePoints = [
            start,
            {
                lat: (start.lat + end.lat) / 2,
                lng: (start.lng + end.lng) / 2
            },
            end
        ];

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


// =======================
// DIRECTION (NONAKTIF DULU)
// =======================
router.get("/direction", async (req, res) => {
    return res.status(501).json({
        success: false,
        error: "Fitur direction belum aktif (routeService belum dibuat)"
    });
});


module.exports = router;