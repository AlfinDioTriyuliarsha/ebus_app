// index.js
const express = require("express");
const cors = require("cors");
const path = require("path");
const helmet = require("helmet");
const { Pool } = require("pg");

// Import routes
const userRoutes = require("./routes/userRoutes");
const companyRoutes = require("./routes/companyRoutes");
const busRoutes = require("./routes/busRoutes");
const routeRoutes = require("./routes/routeRoutes");
const scheduleRoutes = require("./routes/scheduleRoutes");
const mesinRoutes = require("./routes/mesinRoutes");
const driverRoutes = require("./routes/driverRoutes");
const locationRoutes = require("./routes/location");
const driverRequestRoutes = require("./routes/driverRequest");

const app = express();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false }
});

// ================= MIDDLEWARE =================
app.use(helmet({
    contentSecurityPolicy: false, 
}));

app.use(cors({
    origin: [
        "https://ebusapp.vercel.app",
        "http://localhost:3000",
        "http://localhost:5173"
    ],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
}));

// Cukup panggil express.json satu kali saja dengan limit yang wajar
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// ================= STATIC FILE =================
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ================= ROUTES =================
app.use("/api/users", userRoutes);
app.use("/api/company", companyRoutes);
app.use("/api/companies", companyRoutes);
// app.use("/api/buses", busRoutes);
app.use("/api", busRoutes);
app.use("/api/routes", routeRoutes);
app.use("/api/schedules", scheduleRoutes);
app.use("/api/mesin", mesinRoutes);
app.use("/api/drivers", driverRoutes);
app.use("/api/location", locationRoutes);
app.use("/api/driver-request", driverRequestRoutes);


app.get('/api/schedules', async (req, res) => {
  const { company_id } = req.query;
  
  if (!company_id) {
    return res.status(400).json({ error: 'company_id is required' });
  }

  try {
    const result = await pool.query(`
      SELECT 
        s.*, 
        b.plat_nomor AS bus_name, 
        r.nama_rute AS route_name 
      FROM schedules s
      LEFT JOIN buses b ON s.bus_id = b.id
      LEFT JOIN routes r ON s.route_id = r.id
      WHERE s.company_id = $1
      ORDER BY s.tanggal_berangkat ASC, s.jam_berangkat ASC
    `, [company_id]);

    res.status(200).json({
      status: 'success',
      data: result.rows
    });
  } catch (err) {
    console.error("DETAIL ERROR DATABASE:", err);
    res.status(500).json({ error: "Database error: " + err.message });
  }
});

// ================= ROOT TEST =================
app.get("/", (req, res) => {
    res.send("🚍 E-Bus API is running on Railway");
});

// ================= GLOBAL ERROR HANDLER =================
app.use((err, req, res, next) => {
    console.error("🔴 SERVER ERROR:", err.stack);
    res.status(500).json({
        success: false,
        message: "Internal server error",
        error: err.message
    });
});

// ================= SERVER LISTEN =================
const http = require("http");
const server = http.createServer(app);

const { init } = require("./websocket");
init(server);

const PORT = process.env.PORT || 8080;

server.listen(PORT, "0.0.0.0", () => {
  console.log(`🚀 Server running on port ${PORT}`);
});