// index.js
const express = require("express");
const cors = require("cors");
const path = require("path");
const helmet = require("helmet");

const userRoutes = require("./routes/userRoutes");
const companyRoutes = require("./routes/companyRoutes");
const busRoutes = require("./routes/busRoutes");

const app = express();

// ================= MIDDLEWARE =================
app.use(helmet({
    contentSecurityPolicy: false, // Tambahkan ini agar tidak bentrok dengan Vercel
}));

app.use(cors({
    origin: "https://ebusapp.vercel.app", 
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"], // Tambahkan OPTIONS
    allowedHeaders: ["Content-Type", "Authorization"]
}));

app.use(express.json({ limit: "10kb" }));

// ================= STATIC FILE =================
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ================= ROUTES =================
app.use("/api/users", userRoutes);
app.use("/api/companies", companyRoutes);
app.use("/api/buses", busRoutes);

// ================= ROOT TEST =================
app.get("/", (req, res) => {
    res.send("🚍 E-Bus API running");
});

// ================= GLOBAL ERROR HANDLER =================
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: "Terjadi kesalahan pada internal server"
    });
});

// ================= SERVER LISTEN =================
// Railway memberikan port melalui process.env.PORT
const PORT = process.env.PORT || 8080; 

app.listen(PORT, "0.0.0.0", () => {
    console.log(`🚀 Server is running on port ${PORT}`);
})