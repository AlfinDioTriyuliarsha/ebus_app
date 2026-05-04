const express = require("express");
const router = express.Router();
const pool = require("../db");
const { broadcastLocation } = require("../websocket");

// =======================
// GET BUS
// =======================
router.get("/", async (req, res) => {
    try {
        const { company_id } = req.query;

        let query = `
            SELECT 
                b.*,
                r.nama_rute,
                r.path,
                c.company_name,
                d.driver_name
            FROM buses b
            LEFT JOIN routes r ON b.route_id = r.id
            LEFT JOIN companies c ON b.company_id = c.id
            LEFT JOIN drivers d ON b.driver_id = d.id
        `;

        const values = [];

        if (company_id) {
            query += ` WHERE b.company_id = $1`;
            values.push(company_id);
        }

        query += ` ORDER BY b.id ASC`;

        const result = await pool.query(query, values);

        const data = result.rows.map(row => {
            let routeParsed = null;

            try {
                routeParsed = row.path ? JSON.parse(row.path) : null;
            } catch (e) {
                console.log("ERROR PARSE ROUTE:", e);
            }

            return {
                ...row,
                route: routeParsed || row.path
            };
        });

        res.json({
            success: true,
            data
        });

    } catch (err) {
        console.error("GET BUS ERROR:", err);
        res.status(500).json({ success: false, error: err.message });
    }
});

// =======================
// POST BUS
// =======================
router.post("/", async (req, res) => {
    const {
        company_id,
        driver_id,
        nomor_bus,
        plat_nomor,
        mesin_id,
        route_id,
        schedule_id,
        status
    } = req.body;

    if (!company_id || !nomor_bus || !plat_nomor) {
        return res.status(400).json({
            success: false,
            error: "Company, nomor bus & plat wajib"
        });
    }

    try {
        const result = await pool.query(
            `INSERT INTO buses 
            (company_id, driver_id, nomor_bus, plat_nomor, mesin_id, route_id, schedule_id, status)
            VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
            RETURNING *`,
            [
                company_id,
                driver_id || null,
                nomor_bus,
                plat_nomor,
                mesin_id || null,
                route_id || null,
                schedule_id || null,
                status || "Aktif"
            ]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// =======================
// GET DRIVER
// =======================
router.get("/drivers", async (req, res) => {
    const { company_id } = req.query;

    try {
        const result = await pool.query(
            "SELECT * FROM drivers WHERE company_id = $1 ORDER BY id ASC",
            [company_id]
        );

        res.json({
            success: true,
            data: result.rows
        });

    } catch (err) {
        console.error("ERROR DRIVERS:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// =======================
// DELETE BUS
// =======================
router.delete("/:id", async (req, res) => {
    const { id } = req.params;

    try {
        await pool.query("DELETE FROM buses WHERE id=$1", [id]);

        res.json({
            success: true,
            message: "Bus berhasil dihapus"
        });

    } catch (err) {
        console.error("DELETE ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

// =======================
// UPDATE GPS + REALTIME (FINAL)
// =======================
router.put("/update-location/:id", async (req, res) => {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
        return res.status(400).json({
            success: false,
            error: "Latitude & Longitude wajib"
        });
    }

    try {
        const result = await pool.query(
            `UPDATE buses 
             SET latitude=$1, longitude=$2, updated_at=NOW()
             WHERE id=$3 RETURNING *`,
            [latitude, longitude, id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: "Bus tidak ditemukan"
            });
        }

        // 🔥 REALTIME DI SINI
        broadcastLocation({
            bus_id: id,
            latitude,
            longitude
        });

        console.log("📡 BROADCAST:", id, latitude, longitude);

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("GPS ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});


// =======================
// GET BUS BY DRIVER (FINAL)
// =======================
router.get("/driver/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      `SELECT 
          b.id,
          b.nomor_bus,
          b.plat_nomor,
          b.status,
          b.latitude,
          b.longitude,
          d.driver_name
       FROM buses b
       JOIN drivers d ON b.driver_id = d.id
       WHERE d.user_id = $1
       LIMIT 1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: true,
        data: null
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });

  } catch (err) {
    console.error("ERROR GET BUS DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// =======================
// TEST WEBSOCKET
// =======================
router.get("/test-ws", (req, res) => {
    console.log("🔥 TEST WS TRIGGERED");

    broadcastLocation({
        bus_id: 1,
        latitude: -7.999,
        longitude: 112.62
    });

    res.send("WS SENT");
});

// =======================
// ASSIGN DRIVER KE BUS
// =======================
router.put("/assign-driver/:id", async (req, res) => {
    const { id } = req.params; // bus_id
    const { driver_id } = req.body;

    try {
        const result = await pool.query(
            `UPDATE buses 
             SET driver_id=$1 
             WHERE id=$2 RETURNING *`,
            [driver_id, id]
        );

        res.json({
            success: true,
            data: result.rows[0]
        });

    } catch (err) {
        console.error("ASSIGN DRIVER ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});

router.get("/driver/:user_id", async (req, res) => {
  try {
    const { user_id } = req.params;

    const result = await pool.query(
      `SELECT b.id as bus_id
       FROM buses b
       JOIN drivers d ON b.driver_id = d.id
       WHERE d.user_id = $1`,
      [user_id]
    );

    if (result.rows.length === 0) {
      return res.json({
        success: true,
        data: { bus_id: 0 },
      });
    }

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error("ERROR GET BUS DRIVER:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

// ================= UPDATE BUS =================
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { company_id, nomor_bus, plat_nomor, status, driver_id, mesin_id, route_id } = req.body;

    const result = await pool.query(
      `UPDATE buses SET
        company_id = $1,
        nomor_bus = $2,
        plat_nomor = $3,
        status = $4,
        driver_id = $5,
        mesin_id = $6,
        route_id = $7
       WHERE id = $8
       RETURNING *`,
      [company_id, nomor_bus, plat_nomor, status, driver_id, mesin_id, route_id, id]
    );

    res.json({
      success: true,
      data: result.rows[0],
    });
  } catch (err) {
    console.error("ERROR UPDATE BUS:", err);
    res.status(500).json({
      success: false,
      error: err.message,
    });
  }
});

module.exports = router;