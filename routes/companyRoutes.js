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
    const { companyId } = req.params;
    try {
        const result = await pool.query(
            "SELECT * FROM agents WHERE company_id = $1", // Ubah ke company_id
            [companyId]
        );
        res.status(200).json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

router.post("/:companyId/agents", async (req, res) => {
    const { companyId } = req.params;
    const { agent_name, lokasi, kontak } = req.body;
    try {
        const result = await pool.query(
            "INSERT INTO agents (company_id, agent_name, lokasi, kontak) VALUES ($1, $2, $3, $4) RETURNING *", // Ubah ke company_id
            [companyId, agent_name, lokasi, kontak]
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// UPDATE Agent
router.put("/:companyId/agents/:agentId", async (req, res) => {
    const { agentId } = req.params;
    const { agent_name, lokasi, kontak } = req.body;
    try {
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

// DELETE Agent
router.delete("/:companyId/agents/:agentId", async (req, res) => {
    const { agentId } = req.params; // Ambil agentId dari URL
    try {
        // Ganti 'id' dengan nama kolom primary key yang sebenarnya di database kamu
        const result = await pool.query("DELETE FROM agents WHERE id = $1 RETURNING *", [agentId]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: "Agent tidak ditemukan" });
        }
        res.json({ success: true, message: "Agent berhasil dihapus" });
    } catch (err) {
        console.error(err.message);
        res.status(500).json({ success: false, message: err.message });
    }
});

// 2. MANAJEMEN ARMADA per Perusahaan
router.get("/:company_Id/buses", async (req, res) => {
    const { companyId } = req.params;
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

// Ambil Driver yang belum punya batangan bus
router.get("/:companyId/available-drivers", async (req, res) => {
    const { companyId } = req.params;
    try {
        const result = await pool.query(
            `SELECT id, driver_name FROM drivers 
             WHERE company_id = $1 
             AND id NOT IN (SELECT driver_id FROM buses WHERE driver_id IS NOT NULL)`,
            [companyId]
        );
        res.json({ success: true, data: result.rows });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
});

// CRUD BUSES
router.get("/:companyId/buses", async (req, res) => {
    const { companyId } = req.params; // Pastikan menggunakan companyId tanpa underscore
    try {
        const result = await pool.query(
            `SELECT b.*, d.driver_name 
             FROM buses b 
             LEFT JOIN drivers d ON b.driver_id = d.id 
             WHERE b.company_id = $1 ORDER BY b.id DESC`, 
            [companyId]
        );
        res.json({ success: true, data: result.rows });
    } catch (err) { 
        res.status(500).json({ success: false, message: err.message }); 
    }
});

router.post("/:companyId/buses", async (req, res) => {
    const { companyId } = req.params;
    const { driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status } = req.body;
    try {
        const result = await pool.query(
            `INSERT INTO buses (company_id, driver_id, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status) 
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
            [companyId, driver_id || null, nomor_bus, plat_nomor, mesin, rute_berangkat, rute_tujuan, status || 'Aktif']
        );
        res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) { 
        res.status(500).json({ success: false, message: err.message }); 
    }
});

router.delete("/:companyId/buses/:id", async (req, res) => {
    try {
        await pool.query("DELETE FROM buses WHERE id = $1", [req.params.id]);
        res.json({ success: true, message: "Bus berhasil dihapus" });
    } catch (err) {
        res.status(500).json({ success: false, message: err.message });
    }
})

module.exports = router;