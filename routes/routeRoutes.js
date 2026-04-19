const express = require("express");
const router = express.Router();
const { Pool } = require("pg");
const axios = require("axios");

// =======================
// DATABASE
// =======================
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// =======================
// API KEY (WAJIB ADA DI ENV)
// =======================
const ORS_API_KEY = process.env.ORS_API_KEY;


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
// AUTO ROUTE (REAL ROAD)
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

        // 🔥 PANGGIL OPENROUTESERVICE
        const response = await axios.post(
            "https://api.openrouteservice.org/v2/directions/driving-car",
            {
                coordinates: [
                    [start.lng, start.lat],
                    [end.lng, end.lat]
                ]
            },
            {
                headers: {
                    Authorization: ORS_API_KEY,
                    "Content-Type": "application/json"
                }
            }
        );

        const coords = response.data.features[0].geometry.coordinates;

        const routePoints = coords.map(c => ({
            lat: c[1],
            lng: c[0]
        }));

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
        console.error("AUTO ROUTE ERROR:", err.response?.data || err.message);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// DIRECTION (REAL GOOGLE MAP STYLE)
// =======================
router.get("/direction", async (req, res) => {
    try {
        const { start_lat, start_lng, end_lat, end_lng } = req.query;

        const url = `http://router.project-osrm.org/route/v1/driving/`
            + `${start_lng},${start_lat};${end_lng},${end_lat}`
            + `?overview=full&geometries=geojson`;

        const response = await fetch(url);
        const data = await response.json();

        const route = data.routes[0];

        const points = route.geometry.coordinates.map(c => ({
            lat: c[1],
            lng: c[0]
        }));

        res.json({
            success: true,
            data: points,
            distance: route.distance,
            duration: route.duration
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


module.exports = router;