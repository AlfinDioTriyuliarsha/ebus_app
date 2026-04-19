const express = require("express");
const router = express.Router();
const { Pool } = require("pg");
const axios = require("axios");

// ===============================
// DATABASE CONNECTION
// ===============================
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// ===============================
// FUNCTION: GENERATE ROUTE (OSRM)
// ===============================
async function generateRoute(start, end) {
    try {
        const url = `https://router.project-osrm.org/route/v1/driving/${start.lng},${start.lat};${end.lng},${end.lat}?overview=full&geometries=geojson`;

        const response = await axios.get(url);

        if (!response.data.routes || response.data.routes.length === 0) {
            return [];
        }

        const coords = response.data.routes[0].geometry.coordinates;

        return coords.map((c) => ({
            lat: c[1],
            lng: c[0],
        }));
    } catch (err) {
        console.error("OSRM ERROR:", err.message);
        return [];
    }
}

// ===============================
// GET ROUTES BY COMPANY
// ===============================
router.get("/", async (req, res) => {
    const { company_id } = req.query;

    try {
        const result = await pool.query(
            "SELECT * FROM routes WHERE company_id = $1 ORDER BY id DESC",
            [company_id]
        );

        res.status(200).json({
            status: "success",
            data: result.rows
        });

    } catch (err) {
        console.error("GET ROUTES ERROR:", err);
        res.status(500).json({
            status: "error",
            message: err.message
        });
    }
});

// ===============================
// CREATE ROUTE MANUAL
// ===============================
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
            status: "error",
            message: "Data tidak lengkap"
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
            status: "success",
            data: result.rows[0]
        });

    } catch (err) {
        console.error("INSERT ROUTE ERROR:", err);
        res.status(500).json({
            status: "error",
            message: err.message
        });
    }
});

// ===============================
// CREATE AUTO ROUTE (GENERATE PATH)
// ===============================
router.post("/auto-route", async (req, res) => {
    try {
        const { nama_rute, start, end } = req.body;

        if (!start || !end) {
            return res.status(400).json({
                success: false,
                error: "Start dan End wajib diisi"
            });
        }

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

// ===============================
// GET DIRECTION (UNTUK FLUTTER MAP)
// ===============================
router.get("/direction", async (req, res) => {
    try {
        const { start_lat, start_lng, end_lat, end_lng } = req.query;

        if (!start_lat || !start_lng || !end_lat || !end_lng) {
            return res.status(400).json({
                success: false,
                error: "Parameter tidak lengkap"
            });
        }

        const route = await generateRoute(
            { lat: start_lat, lng: start_lng },
            { lat: end_lat, lng: end_lng }
        );

        res.json({
            success: true,
            data: route
        });

    } catch (err) {
        console.error("DIRECTION ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

module.exports = router;