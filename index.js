// index.js
const express = require("express");
const cors = require("cors");
const path = require("path");
const helmet = require("helmet");

// Import rute
const userRoutes = require("./routes/userRoutes");
const companyRoutes = require("./routes/companyRoutes");
const busRoutes = require("./routes/busRoutes");

const app = express();

// ================= MIDDLEWARE =================
app.use(helmet({
    contentSecurityPolicy: false, 
}));

app.use(cors({
    origin: '*', 
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));

// Cukup panggil express.json satu kali saja dengan limit yang wajar
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// ================= STATIC FILE =================
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ================= ROUTES =================
app.use("/api/users", userRoutes);
app.use("/api/company", companyRoutes);
app.use("/api/buses", busRoutes);

// ================= ROOT TEST =================
app.get("/", (req, res) => {
    res.send("🚍 E-Bus API is running on Railway");
});

// ================= GLOBAL ERROR HANDLER =================
app.use((err, req, res, next) => {
    console.error("🔴 SERVER ERROR:", err.stack);
    res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada internal server",
        error: err.message // Menampilkan pesan error di response untuk debug
    });
});

// ================= SERVER LISTEN =================
const PORT = process.env.PORT || 8080; 

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 Server is running on port ${PORT}`);
});

// 1. Endpoint untuk MENGAMBIL Rute berdasarkan company_id
app.get('/api/routes', async (req, res) => {
    const { company_id } = req.query;
    try {
        const result = await pool.query(
            'SELECT * FROM routes WHERE company_id = $1 ORDER BY id DESC', 
            [company_id]
        );
        res.status(200).json({ status: 'success', data: result.rows });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// 2. Endpoint untuk MENAMBAH Rute Baru
app.post('/api/routes', async (req, res) => {
    const { company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO routes (company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi) VALUES ($1, $2, $3, $4, $5) RETURNING *',
            [company_id, nama_rute, titik_awal, titik_tujuan, jarak_estimasi]
        );
        res.status(201).json({ status: 'success', data: result.rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});