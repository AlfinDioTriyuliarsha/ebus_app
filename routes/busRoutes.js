const express = require("express");
const router = express.Router();
const pool = require("../db");


// =======================
// GET BUS + ROUTE
// =======================
router.get("/", async (req, res) => {
    try {
        let { company_id } = req.query;

        const values = [];

        let query = `
            SELECT 
                b.*,
                r.id as route_id,
                r.nama_rute,
                route_checkpoints,
                c.company_name,
                d.driver_name,

                CASE 
                    WHEN to_regclass('public.route_checkpoints') IS NOT NULL 
                    THEN (
                        SELECT COALESCE(
                            json_agg(
                                json_build_object(
                                    'lat', l.latitude,
                                    'lng', l.longitude
                                )
                                ORDER BY rc.urutan
                            ),
                            '[]'::json
                        )
                        FROM route_checkpoints rc
                        JOIN locations l ON rc.location_id = l.id
                        WHERE rc.route_id = r.id
                    )
                    ELSE '[]'::json
                END as route

            FROM buses b
            LEFT JOIN routes r ON b.route_id = r.id
            LEFT JOIN companies c ON b.company_id = c.id
            LEFT JOIN drivers d ON b.driver_id = d.id
        `;

        if (company_id) {
            values.push(parseInt(company_id));
            query += ` WHERE b.company_id = $1`;
        }

        query += ` ORDER BY b.id ASC`;

        const result = await pool.query(query, values);

        res.json({
            success: true,
            data: result.rows
        });

    } catch (err) {
        console.error("ERROR BUS:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// POST BUS
// =======================
router.post("/", async (req, res) => {
    const {
        company_id,
        driver_id,
        nomor_bus,
        plat_nomor,
        mesin,
        route_id,
        status
    } = req.body;

    try {
        const check = await pool.query(
            "SELECT * FROM buses WHERE plat_nomor = $1 AND company_id = $2",
            [plat_nomor, company_id]
        );

        if (check.rows.length > 0) {
            return res.status(400).json({
                success: false,
                error: "Plat nomor sudah digunakan!"
            });
        }

        const result = await pool.query(
            `INSERT INTO buses 
            (company_id, driver_id, nomor_bus, plat_nomor, mesin, route_id, status) 
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            RETURNING *`,
            [
                company_id,
                driver_id,
                nomor_bus,
                plat_nomor,
                mesin,
                route_id,
                status || "Aktif"
            ]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("ERROR INSERT BUS:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// GET DRIVER
// =======================
router.get("/drivers", async (req, res) => {
    const { company_id } = req.query;

    try {
        const result = await pool.query(
            "SELECT * FROM drivers WHERE company_id = $1 ORDER BY id ASC",
            [company_id]
        );

        res.json({
            success: true,
            data: result.rows
        });

    } catch (err) {
        console.error("ERROR DRIVERS:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// UPDATE BUS (Assign Driver)
// =======================
router.put("/:id", async (req, res) => {
    const { id } = req.params;
    const { driver_id } = req.body;

    try {
        const result = await pool.query(
            "UPDATE buses SET driver_id = $1 WHERE id = $2 RETURNING *",
            [driver_id, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Bus tidak ditemukan"
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("ERROR UPDATE BUS:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// SIMULASI GERAK BUS
// =======================
router.post("/simulate", async (req, res) => {
    try {
        const buses = await pool.query(`
            SELECT b.*, r.path 
            FROM buses b
            JOIN routes r ON b.route_id = r.id
        `);

        for (let bus of buses.rows) {
            const route = bus.path;

            if (!route || route.length === 0) continue;

            let index = bus.route_index || 0;
            index = (index + 1) % route.length;

            const point = route[index];

            await pool.query(
                "UPDATE buses SET latitude=$1, longitude=$2, route_index=$3 WHERE id=$4",
                [point.lat, point.lng, index, bus.id]
            );
        }

        res.json({ success: true });

    } catch (err) {
        console.error("SIMULATION ERROR:", err);
        res.status(500).json({ error: err.message });
    }
});


// =======================
// UPDATE GPS REAL-TIME
// =======================
router.put("/update-location/:id", async (req, res) => {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    try {
        const result = await pool.query(
            `UPDATE buses 
             SET latitude = $1, longitude = $2, updated_at = NOW()
             WHERE id = $3 RETURNING *`,
            [latitude, longitude, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Bus tidak ditemukan"
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("ERROR UPDATE GPS:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

module.exports = router;