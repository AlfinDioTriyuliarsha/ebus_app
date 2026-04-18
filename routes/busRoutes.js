const express = require("express");
const router = express.Router();
const pool = require("../db");

// ================= GET BUS + AUTO ROUTE =================
router.get("/", async (req, res) => {
    try {
        const query = `
            SELECT 
                b.*,
                c.company_name,
                r.id as route_id,
                r.nama_rute
            FROM buses b
            LEFT JOIN companies c ON b.company_id = c.id
            LEFT JOIN routes r 
                ON LOWER(r.asal) = LOWER(b.rute_berangkat)
                AND LOWER(r.tujuan) = LOWER(b.rute_tujuan)
            ORDER BY b.id ASC
        `;

        const result = await pool.query(query);

        res.json({
            success: true,
            data: result.rows
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// ================= POST BUS =================
router.post("/", async (req, res) => {
    const {
        company_id,
        driver_id,
        nomor_bus,
        plat_nomor,
        mesin,
        rute_berangkat,
        rute_tujuan,
        status
    } = req.body;

    try {
        // CEK DUPLIKAT
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

        // INSERT
        const result = await pool.query(
            `INSERT INTO buses 
            (company_id, driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status) 
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8) 
            RETURNING *`,
            [
                company_id,
                driver_id,
                nomor_bus,
                plat_nomor,
                mesin,
                rute_berangkat,
                rute_tujuan,
                status || 'Aktif'
            ]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

module.exports = router;