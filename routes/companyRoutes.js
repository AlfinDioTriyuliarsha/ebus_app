const express = require("express");
const router = express.Router();
const pool = require("../db");

// ==========================================
// 1. KELOLA DATA PERUSAHAAN (Untuk Super Admin)
// ==========================================

// GET semua perusahaan - INI YANG DIPANGGIL HALAMAN MANAJEMEN PERUSAHAAN
router.get("/", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM companies ORDER BY id ASC");
        res.json({ success: true, data: result.rows });
    } catch (err) {
        console.error("Error Get Companies:", err.message);
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
// 2. MANAJEMEN AGENT (Admin Perusahaan)
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

router.put("/:companyId/agents/:agentId", async (req, res) => {
    try {
        const { agentId } = req.params;
        const { agent_name, lokasi, kontak } = req.body;
        const result = await pool.query(
            "UPDATE agents SET agent_name = $1, lokasi = $2, kontak = $3 WHERE id = $4 RETURNING *",
            [agent_name, lokasi, kontak, agentId]
        );
        if (result.rows.length === 0) return res.status(404).json({ success: false, message: "Agent tidak ditemukan" });
        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

router.delete("/:companyId/agents/:agentId", async (req, res) => {
    try {
        const { agentId } = req.params;
        const result = await pool.query("DELETE FROM agents WHERE id = $1 RETURNING *", [agentId]);
        if (result.rows.length === 0) return res.status(404).json({ success: false, message: "Agent tidak ditemukan" });
        res.json({ success: true, message: "Agent berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// ==========================================
// 3. MANAJEMEN ARMADA/BUS (Admin Perusahaan)
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
        res.status(500).json({ success: false, message: err.message });
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
        res.status(500).json({ success: false, message: err.message });
    }
});

// PUT Update Bus
router.put("/:companyId/buses/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status } = req.body;
        const result = await pool.query(
            `UPDATE buses 
             SET driver_id=$1, nomor_bus=$2, plat_nomor=$3, mesin=$4, rute_berangkat=$5, rute_tujuan=$6, status=$7 
             WHERE id=$8 RETURNING *`,
            [driver_id || null, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status, id]
        );
        if (result.rows.length === 0) return res.status(404).json({ success: false, message: "Bus tidak ditemukan" });
        res.json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
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
// 4. MANAJEMEN DRIVER (Admin Perusahaan)
// ==========================================

// GET Semua Driver Perusahaan
router.get("/:companyId/drivers", async (req, res) => {
    try {
        const result = await pool.query("SELECT * FROM drivers WHERE company_id = $1", [req.params.companyId]);
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// Ambil Driver yang belum punya batangan bus
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
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;