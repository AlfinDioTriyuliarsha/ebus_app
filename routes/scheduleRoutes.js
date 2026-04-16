const express = require("express");
const router = express.Router();
const { Pool } = require("pg");

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});


// ===============================
// ✅ GET SCHEDULE
// ===============================
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

        res.json({
            status: "success",
            data: result.rows
        });

    } catch (err) {
        console.error("❌ GET ERROR:", err);
        res.status(500).json({ status: "error", message: err.message });
    }
});


// ===============================
// ✅ POST SCHEDULE
// ===============================
router.post("/", async (req, res) => {
    const {
        company_id,
        bus_id,
        route_id,
        tanggal_berangkat,
        jam_berangkat,
        harga_tiket
    } = req.body;

    if (!company_id || !bus_id || !route_id) {
        return res.status(400).json({
            message: "company_id, bus_id, route_id wajib diisi"
        });
    }

    try {
        const result = await pool.query(
            `INSERT INTO schedules 
            (company_id, bus_id, route_id, tanggal_berangkat, jam_berangkat, harga_tiket) 
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING *`,
            [
                company_id,
                bus_id,
                route_id,
                tanggal_berangkat,
                jam_berangkat,
                harga_tiket
            ]
        );

        res.status(201).json({
            status: "success",
            data: result.rows[0]
        });

    } catch (err) {
        console.error("❌ INSERT ERROR:", err);
        res.status(500).json({ status: "error", message: err.message });
    }
});


// ===============================
// ✅ UPDATE SCHEDULE
// ===============================
router.put("/:id", async (req, res) => {
    const { id } = req.params;

    const {
        bus_id,
        route_id,
        tanggal_berangkat,
        jam_berangkat,
        harga_tiket,
        status
    } = req.body;

    try {
        const result = await pool.query(
            `UPDATE schedules SET
                bus_id = $1,
                route_id = $2,
                tanggal_berangkat = $3,
                jam_berangkat = $4,
                harga_tiket = $5,
                status = $6
            WHERE id = $7
            RETURNING *`,
            [
                bus_id,
                route_id,
                tanggal_berangkat,
                jam_berangkat,
                harga_tiket,
                status,
                id
            ]
        );

        res.json({
            status: "success",
            data: result.rows[0]
        });

    } catch (err) {
        console.error("❌ UPDATE ERROR:", err);
        res.status(500).json({ status: "error", message: err.message });
    }
});


// ===============================
// ✅ DELETE SCHEDULE
// ===============================
router.delete("/:id", async (req, res) => {
    const { id } = req.params;

    try {
        await pool.query(
            `DELETE FROM schedules WHERE id = $1`,
            [id]
        );

        res.json({
            status: "success",
            message: "Jadwal berhasil dihapus"
        });

    } catch (err) {
        console.error("❌ DELETE ERROR:", err);
        res.status(500).json({ status: "error", message: err.message });
    }
});


module.exports = router;