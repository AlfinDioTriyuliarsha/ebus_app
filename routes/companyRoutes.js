const express = require("express");
const router = express.Router();
const pool = require("../db");

// ==========================================
// KELOLA DATA PERUSAHAAN (Untuk Super Admin)
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
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Perusahaan tidak ditemukan" });
        }
        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// POST tambah perusahaan
router.post("/", async (req, res) => {
    try {
        const { company_name, alamat, email, status, user_id } = req.body;
        if (!company_name) {
            return res.status(400).json({ success: false, message: "Nama perusahaan wajib diisi" });
        }
        const result = await pool.query(
            `INSERT INTO companies (company_name, alamat, email, status, user_id) 
             VALUES ($1, $2, $3, $4, $5) RETURNING *`, 
            [company_name, alamat || null, email || null, status || "Aktif", user_id || null]
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT update perusahaan
router.put("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { company_name, alamat, email, status, user_id } = req.body;
        const result = await pool.query(
            `UPDATE companies 
             SET company_name = $1, alamat = $2, email = $3, status = $4, user_id = $5 
             WHERE id = $6 RETURNING *`, 
            [company_name, alamat, email, status, user_id, id]
        );
        if (result.rows.length === 0) return res.status(404).json({ success: false, message: "Data tidak ditemukan" });
        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// DELETE perusahaan
router.delete("/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const result = await pool.query("DELETE FROM companies WHERE id = $1 RETURNING *", [id]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, message: "Data tidak ditemukan" });
        res.json({ success: true, message: "Perusahaan berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ==========================================
// FITUR KHUSUS ADMIN PERUSAHAAN (Sub-Modul)
// ==========================================

// 1. MANAJEMEN AGENT per Perusahaan
router.get("/:companyId/agents", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM agents WHERE company_id = $1", [req.params.companyId]);
        res.json({ success: true, data: result.rows });
    } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// 2. MANAJEMEN ARMADA per Perusahaan
router.get("/:companyId/buses", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM buses WHERE company_id = $1", [req.params.companyId]);
        res.json({ success: true, data: result.rows });
    } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// 3. MANAJEMEN DRIVER per Perusahaan
router.get("/:companyId/drivers", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM drivers WHERE company_id = $1", [req.params.companyId]);
        res.json({ success: true, data: result.rows });
    } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;