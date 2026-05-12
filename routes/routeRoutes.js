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
// API KEY
// =======================
const ORS_API_KEY = process.env.ORS_API_KEY;


// =======================
// GET ROUTES
// =======================
router.get("/", async (req, res) => {
    const { company_id } = req.query;

    try {

        let result;

        if (company_id) {
            result = await pool.query(
                "SELECT * FROM routes WHERE company_id = $1 ORDER BY id DESC",
                [company_id]
            );
        } else {
            result = await pool.query(
                "SELECT * FROM routes ORDER BY id DESC"
            );
        }

        res.json({
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
// AUTO ROUTE FULL TOL / NON TOL
// =======================
router.post("/auto-route", async (req, res) => {
    try {

        const {
            company_id,
            nama_rute,
            start,
            checkpoint_a,
            checkpoint_b,
            end,
            route_mode
        } = req.body;

        console.log("BODY:", req.body);

        // ================= VALIDASI =================
        if (!company_id || !start || !end) {
            return res.status(400).json({
                success: false,
                error: "company_id, start, end wajib"
            });
        }

        if (!ORS_API_KEY) {
            return res.status(500).json({
                success: false,
                error: "ORS API KEY tidak ada"
            });
        }

        // ================= COORDINATES =================
        const coordinates = [
            [Number(start.lng), Number(start.lat)],

            checkpoint_a
                ? [Number(checkpoint_a.lng), Number(checkpoint_a.lat)]
                : null,

            checkpoint_b
                ? [Number(checkpoint_b.lng), Number(checkpoint_b.lat)]
                : null,

            [Number(end.lng), Number(end.lat)]
        ].filter(Boolean);

        console.log("COORDINATES:", coordinates);

        // ================= REQUEST BODY =================
        let requestBody = {
            coordinates: coordinates
        };

        // ================= MODE NON TOL =================
        if (route_mode === "non_tol") {

            requestBody.options = {
                avoid_features: ["tollways"]
            };

            console.log("MODE: NON TOL");
        }

        // ================= MODE MIX =================
        else if (route_mode === "mix") {

            console.log("MODE: MIX");
        }

        // ================= MODE FULL TOL =================
        else {

            console.log("MODE: FULL TOL");
        }

        // ================= REQUEST ORS =================
        let path = [];
        let distance = 0;
        let duration = 0;

        try {

            const ors = await axios.post(
                "https://api.openrouteservice.org/v2/directions/driving-car/geojson",
                requestBody,
                {
                    headers: {
                        Authorization: ORS_API_KEY,
                        "Content-Type": "application/json"
                    }
                }
            );

            // ================= SUCCESS =================
            if (
                ors.data &&
                ors.data.features &&
                ors.data.features.length > 0
            ) {

                console.log("ORS BERHASIL");

                const feature = ors.data.features[0];

                const coords = feature.geometry.coordinates;

                path = coords.map(c => ({
                    lat: c[1],
                    lng: c[0]
                }));

                distance = feature.properties.summary.distance;
                duration = feature.properties.summary.duration;

            } else {

                console.log("ORS GAGAL → fallback");

                path = [
                    {
                        lat: start.lat,
                        lng: start.lng
                    },
                    {
                        lat: end.lat,
                        lng: end.lng
                    }
                ];
            }

        } catch (err) {

            console.log(
                "ORS ERROR:",
                err.response?.data || err.message
            );

            // ================= FALLBACK =================
            path = [
                {
                    lat: start.lat,
                    lng: start.lng
                },
                {
                    lat: end.lat,
                    lng: end.lng
                }
            ];
        }

        // ================= SIMPAN DATABASE =================
        const result = await pool.query(
            `
            INSERT INTO routes
            (
                company_id,
                nama_rute,
                titik_awal,
                titik_tujuan,
                path,
                jarak_estimasi
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *
            `,
            [
                company_id,

                nama_rute || "Auto Route",

                JSON.stringify(start),

                JSON.stringify(end),

                JSON.stringify(path),

                distance
            ]
        );

        // ================= RESPONSE =================
        res.json({
            success: true,
            data: result.rows[0],
            route_info: {
                distance_meter: distance,
                distance_km: (distance / 1000).toFixed(2),
                duration_second: duration,
                duration_minute: (duration / 60).toFixed(0),
                mode: route_mode || "tol"
            }
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
// DELETE AUTO ROUTE 
// =======================
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      "DELETE FROM routes WHERE id = $1 RETURNING *",
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Route tidak ditemukan",
      });
    }

    res.json({
      success: true,
      message: "Route berhasil dihapus",
      data: result.rows[0],
    });
  } catch (err) {
    console.error("DELETE ROUTE ERROR:", err);

    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// =======================
// UPDATE AUTO ROUTE 
// =======================
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const {
      nama_rute,
      titik_awal,
      titik_tujuan,
      path,
    } = req.body;

    const result = await pool.query(
      `
      UPDATE routes
      SET
        nama_rute = COALESCE($1, nama_rute),
        titik_awal = COALESCE($2, titik_awal),
        titik_tujuan = COALESCE($3, titik_tujuan),
        path = COALESCE($4, path),
        updated_at = NOW()
      WHERE id = $5
      RETURNING *
      `,
      [
        nama_rute,
        titik_awal,
        titik_tujuan,
        path ? JSON.stringify(path) : null,
        id,
      ]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: "Route tidak ditemukan",
      });
    }

    res.json({
      success: true,
      message: "Route berhasil diupdate",
      data: result.rows[0],
    });
  } catch (err) {
    console.error("UPDATE ROUTE ERROR:", err);

    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// =======================
// OSRM DIRECTION
// =======================
router.get("/direction", async (req, res) => {
    try {
        const { start_lat, start_lng, end_lat, end_lng } = req.query;

        const url = `http://router.project-osrm.org/route/v1/driving/`
            + `${start_lng},${start_lat};${end_lng},${end_lat}`
            + `?overview=full&geometries=geojson`;

        const response = await axios.get(url);
        const route = response.data.routes[0];

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
        console.error("OSRM ERROR:", err.message);

        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

router.get("/:id/geofence", async (req, res) => {
  try {
    const routeId = req.params.id;

    // ================= ROUTE =================
    const routeResult = await pool.query(
      `
      SELECT *
      FROM routes
      WHERE id = $1
      `,
      [routeId]
    );

    const route = routeResult.rows[0];

    if (!route) {
      return res.status(404).json({
        success: false,
        message: "Route tidak ditemukan",
      });
    }

    // ================= TERMINAL AWAL =================
    const terminalAwal = await pool.query(
      `
      SELECT *
      FROM terminals
      WHERE id = $1
      `,
      [route.start_terminal_id]
    );

    // ================= TERMINAL TUJUAN =================
    const terminalTujuan = await pool.query(
      `
      SELECT *
      FROM terminals
      WHERE id = $1
      `,
      [route.end_terminal_id]
    );

    // ================= CHECKPOINT =================
    const checkpoints = await pool.query(
      `
      SELECT
        c.id,
        c.nama,
        c.lat,
        c.lng,
        c.tipe
      FROM route_checkpoints rc
      JOIN checkpoints c
      ON rc.checkpoint_id = c.id
      WHERE rc.route_id = $1
      `,
      [routeId]
    );

    res.json({
      success: true,
      terminal_awal: terminalAwal.rows[0],
      terminal_tujuan: terminalTujuan.rows[0],
      checkpoints: checkpoints.rows,
    });

  } catch (e) {
    console.log("GEOFENCE ERROR:", e);

    res.status(500).json({
      success: false,
      message: "Server Error",
    });
  }
});

module.exports = router;