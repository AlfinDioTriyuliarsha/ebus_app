const express = require("express");
const router = express.Router();
const { Pool } = require("pg");

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// ==============================
// ✅ GET SCHEDULE
// ==============================
router.get("/", async (req, res) => {
    const { company_id } = req.query;

    if (!company_id) {
        return res.status(400).json({ message: "company_id wajib diisi" });
    }

    try {
        const result = await pool.query(
            `SELECT 
                s.*, 
                r.nama_rute, 
                b.plat_nomor 
             FROM schedules s
             LEFT JOIN routes r ON s.route_id = r.id
             LEFT JOIN buses b ON s.bus_id = b.id
             WHERE s.company_id = $1
             ORDER BY s.tanggal_berangkat DESC`,
            [company_id]
        );

        res.status(200).json({
            status: "success",
            data: result.rows
        });

    } catch (err) {
        console.error("❌ ERROR GET SCHEDULE:", err);
        res.status(500).json({
            status: "error",
            message: err.message
        });
    }
});

// ==============================
// ✅ POST SCHEDULE (FIX)
// ==============================
router.post("/", async (req, res) => {
    const {
        company_id,
        bus_id,
        tanggal_berangkat,
        jam_berangkat,
        harga_tiket
    } = req.body;

    if (!company_id || !bus_id || !tanggal_berangkat || !jam_berangkat || !harga_tiket) {
        return res.status(400).json({ message: "Semua field wajib diisi" });
    }

    try {
        // 🔥 AMBIL route_id DARI BUS
        const busResult = await pool.query(
            `SELECT route_id FROM buses WHERE id = $1`,
            [bus_id]
        );

        if (busResult.rows.length === 0) {
            return res.status(404).json({ message: "Bus tidak ditemukan" });
        }

        const route_id = busResult.rows[0].route_id;

        const result = await pool.query(
            `INSERT INTO schedules 
            (company_id, bus_id, route_id, tanggal_berangkat, jam_berangkat, harga_tiket) 
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *`,
            [company_id, bus_id, route_id, tanggal_berangkat, jam_berangkat, harga_tiket]
        );

        res.status(201).json({
            status: "success",
            data: result.rows[0]
        });

    } catch (err) {
        console.error("❌ ERROR INSERT SCHEDULE:", err);
        res.status(500).json({
            status: "error",
            message: err.message
        });
    }
});

// ==============================
// ✏️ UPDATE SCHEDULE
// ==============================
router.put("/:id", async (req, res) => {
    const { id } = req.params;
    const {
        bus_id,
        tanggal_berangkat,
        jam_berangkat,
        harga_tiket
    } = req.body;

    try {
        // ambil route_id dari bus
        const busResult = await pool.query(
            `SELECT route_id FROM buses WHERE id = $1`,
            [bus_id]
        );

        if (busResult.rows.length === 0) {
            return res.status(404).json({ message: "Bus tidak ditemukan" });
        }

        const route_id = busResult.rows[0].route_id;

        const result = await pool.query(
            `UPDATE schedules SET
                bus_id = $1,
                route_id = $2,
                tanggal_berangkat = $3,
                jam_berangkat = $4,
                harga_tiket = $5
            WHERE id = $6
            RETURNING *`,
            [bus_id, route_id, tanggal_berangkat, jam_berangkat, harga_tiket, id]
        );

        res.status(200).json({
            status: "success",
            data: result.rows[0]
        });

    } catch (err) {
        console.error("❌ ERROR UPDATE:", err);
        res.status(500).json({
            status: "error",
            message: err.message
        });
    }
});

// ==============================
// 🗑️ DELETE SCHEDULE
// ==============================
router.delete("/:id", async (req, res) => {
    const { id } = req.params;

    try {
        await pool.query(`DELETE FROM schedules WHERE id = $1`, [id]);

        res.status(200).json({
            status: "success",
            message: "Jadwal berhasil dihapus"
        });

    } catch (err) {
        console.error("❌ ERROR DELETE:", err);
        res.status(500).json({
            status: "error",
            message: err.message
        });
    }
});

module.exports = router;