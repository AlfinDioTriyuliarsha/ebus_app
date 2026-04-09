const express = require("express");
const router = express.Router();
const pool = require("../db");

// ==========================================
// KELOLA DATA PERUSAHAAN (Super Admin)
// ==========================================

// GET semua perusahaan
router.get("/", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM companies ORDER BY id ASC");
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// GET perusahaan by ID
router.get("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query("SELECT * FROM companies WHERE id = $1", [id]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, message: "Perusahaan tidak ditemukan" });
        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST tambah perusahaan
router.post("/", async (req, res) => {
    try {
        const { company_name, alamat, email, status, user_id } = req.body;
        const result = await pool.query(
            "INSERT INTO companies (company_name, alamat, email, status, user_id) VALUES ($1, $2, $3, $4, $5) RETURNING *", 
            [company_name, alamat || null, email || null, status || "Aktif", user_id || null]
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ==========================================
// MANAJEMEN AGENT
// ==========================================

router.get("/:companyId/agents", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM agents WHERE company_id = $1", [req.params.companyId]);
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

router.post("/:companyId/agents", async (req, res) => {
    try {
        const { agent_name, lokasi, kontak } = req.body;
        const result = await pool.query(
            "INSERT INTO agents (company_id, agent_name, lokasi, kontak) VALUES ($1, $2, $3, $4) RETURNING *",
            [req.params.companyId, agent_name, lokasi, kontak]
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ==========================================
// MANAJEMEN ARMADA (BUSES)
// ==========================================

// GET Semua Bus Perusahaan
router.get("/:companyId/buses", async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT b.*, d.driver_name 
             FROM buses b 
             LEFT JOIN drivers d ON b.driver_id = d.id 
             WHERE b.company_id = $1 ORDER BY b.id DESC`, 
            [req.params.companyId]
        );
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// POST Tambah Bus
router.post("/:companyId/buses", async (req, res) => {
    try {
        const { companyId } = req.params;
        const { driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status } = req.body;

        const result = await pool.query(
            `INSERT INTO buses 
            (company_id, driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status) 
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
            [companyId, driver_id || null, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status || 'Aktif']
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// DELETE Bus
router.delete("/:companyId/buses/:id", async (req, res) => {
    try {
        await pool.query("DELETE FROM buses WHERE id = $1", [req.params.id]);
        res.json({ success: true, message: "Bus berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ==========================================
// MANAJEMEN DRIVER
// ==========================================

// Ambil Driver yang tersedia (belum narik bus)
router.get("/:companyId/available-drivers", async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT id, driver_name FROM drivers 
             WHERE company_id = $1 
             AND id NOT IN (SELECT driver_id FROM buses WHERE driver_id IS NOT NULL)`,
            [req.params.companyId]
        );
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

module.exports = router;