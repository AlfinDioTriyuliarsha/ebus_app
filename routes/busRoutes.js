const express = require("express");
const router = express.Router();
const pool = require("../db");

// GET BUS + ROUTE
router.get("/", async (req, res) => {
    try {
        const { company_id } = req.query;

        let query = `
            SELECT 
                b.*,
                r.id as route_id,
                r.nama_rute,
                c.company_name
            FROM buses b
            LEFT JOIN routes r ON b.route_id = r.id
            LEFT JOIN companies c ON b.company_id = c.id
        `;
        const values = [];

        if (company_id) {
            query += " WHERE b.company_id = $1";
            values.push(company_id);
        }

        query += " ORDER BY b.id ASC";

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

// POST BUS
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
            [company_id, driver_id, nomor_bus, plat_nomor, mesin, route_id, status || 'Aktif']
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

// routes/driverRoutes.js
router.get("/", async (req, res) => {
    const { company_id } = req.query;

    try {
        const result = await pool.query(
            "SELECT * FROM drivers WHERE company_id = $1 ORDER BY id ASC",
            [company_id]
        );

        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// UPDATE BUS (Assign Driver)
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

module.exports = router;