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
app.use("/api/bus", busRoutes);
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