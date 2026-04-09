const express = require("express");
const router = express.Router();
const pool = require("../db");

// GET: Ambil daftar bus
router.get("/", async (req, res) => {
    try {
        const query = `
            SELECT b.*, c.company_name 
            FROM buses b
            LEFT JOIN companies c ON b.company_id = c.id
            ORDER BY b.id ASC
        `;
        const result = await pool.query(query);
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// POST: Tambah bus baru (Dipanggil oleh Flutter)
router.post("/", async (req, res) => {
    const { company_id, driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO buses 
            (company_id, driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
            [company_id, driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status || 'Aktif']
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

module.exports = router;