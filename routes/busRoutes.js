const express = require("express");
const router = express.Router();
const pool = require("../db");


// =======================
// GET BUS
// =======================
router.get("/", async (req, res) => {
    try {
        const { company_id } = req.query;

        let query = `
            SELECT 
                b.*,
                r.nama_rute,
                r.path,
                c.company_name,
                d.driver_name
            FROM buses b
            LEFT JOIN routes r ON b.route_id = r.id
            LEFT JOIN companies c ON b.company_id = c.id
            LEFT JOIN drivers d ON b.driver_id = d.id
        `;

        const values = [];

        if (company_id) {
            query += ` WHERE b.company_id = $1`;
            values.push(company_id);
        }

        query += ` ORDER BY b.id ASC`;

        const result = await pool.query(query, values);

        const data = result.rows.map(row => {
            console.log("ROUTE DB:", row.route); // ✅ benar

            let routeParsed = null;

            try {
                routeParsed = row.route ? JSON.parse(row.route) : null;
            } catch (e) {
                console.log("ERROR PARSE ROUTE:", e);
            }

            return {
                ...row,
                route: routeParsed || row.path // fallback
            };
        });

        res.json({
            success: true,
            data
        });

    } catch (err) {
        console.error("GET BUS ERROR:", err);
        res.status(500).json({ success: false, error: err.message });
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
        mesin_id,
        route_id,
        schedule_id,
        status
    } = req.body;

    if (!company_id || !nomor_bus || !plat_nomor) {
        return res.status(400).json({
            success: false,
            error: "Company, nomor bus & plat wajib"
        });
    }

    try {
        const result = await pool.query(
            `INSERT INTO buses 
            (company_id, driver_id, nomor_bus, plat_nomor, mesin_id, route_id, schedule_id, status)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *`,
            [
                company_id,
                driver_id || null,
                nomor_bus,
                plat_nomor,
                mesin_id || null,
                route_id || null,
                schedule_id || null,
                status || "Aktif"
            ]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
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
// UPDATE BUS
// =======================
router.put("/:id", async (req, res) => {
    const { id } = req.params;

    const {
        driver_id,
        nomor_bus,
        plat_nomor,
        mesin_id,
        route_id,
        schedule_id,
        status
    } = req.body;

    try {
        const result = await pool.query(
            `UPDATE buses SET
                driver_id=$1,
                nomor_bus=$2,
                plat_nomor=$3,
                mesin_id=$4,
                route_id=$5,
                schedule_id=$6,
                status=$7,
                updated_at=NOW()
            WHERE id=$8
            RETURNING *`,
            [
                driver_id || null,
                nomor_bus,
                plat_nomor,
                mesin_id || null,
                route_id || null,
                schedule_id || null,
                status || "Aktif",
                id
            ]
        );

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("UPDATE ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// DELETE BUS
// =======================
router.delete("/:id", async (req, res) => {
    const { id } = req.params;

    try {
        await pool.query("DELETE FROM buses WHERE id=$1", [id]);

        res.json({
            success: true,
            message: "Bus berhasil dihapus"
        });

    } catch (err) {
        console.error("DELETE ERROR:", err);
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
// UPDATE GPS (FIX DUPLIKAT)
// =======================
router.put("/update-location/:id", async (req, res) => {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
        return res.status(400).json({
            success: false,
            error: "Latitude & Longitude wajib"
        });
    }

    try {
        const result = await pool.query(
            `UPDATE buses 
             SET latitude=$1, longitude=$2, updated_at=NOW()
             WHERE id=$3 RETURNING *`,
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
        console.error("GPS ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// GET BUS BY DRIVER
// =======================
router.get("/driver/:driver_id", async (req, res) => {
    const { driver_id } = req.params;

    try {
        const result = await pool.query(
            "SELECT id as bus_id FROM buses WHERE driver_id = $1",
            [driver_id]
        );

        if (result.rows.length === 0) {
            return res.json({
                success: false,
                message: "Driver belum punya bus"
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

module.exports = router;