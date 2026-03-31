// routes/userRoutes.js
const express = require("express");
const router = express.Router();
const pool = require("../db");
const bcrypt = require("bcrypt");
const multer = require("multer");
const path = require("path");

const saltRounds = 10;

// =====================================================
// KONFIGURASI UPLOAD FOTO
// =====================================================

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, "uploads/profiles/");
  },
  filename: function (req, file, cb) {
    cb(null, "profile-" + Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 2 * 1024 * 1024 },
});

// =====================================================
// UPLOAD FOTO PROFIL
// =====================================================

router.post(
  "/upload-profile/:id",
  upload.single("profile_picture"),
  async (req, res) => {
    const userId = Number(req.params.id);

    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Tidak ada file yang diunggah",
        });
      }

      const imageUrl = `/uploads/profiles/${req.file.filename}`;

      await pool.query(
        "UPDATE users SET profile_image = $1 WHERE id = $2",
        [imageUrl, userId]
      );

      res.json({
        success: true,
        message: "Foto profil berhasil diperbarui",
        imageUrl: imageUrl,
      });
    } catch (err) {
      console.error("Upload error:", err.message);
      res.status(500).json({
        success: false,
        message: "Gagal memperbarui foto",
      });
    }
  }
);

// =====================================================
// LOGIN USER (FINAL SECURE VERSION)
// =====================================================

router.post("/login", async (req, res) => {
  const { email, password, device } = req.body;

  try {
    if (!email || !password || !device) {
      return res.status(400).json({
        success: false,
        message: "Email, password, dan device wajib diisi",
      });
    }

    const result = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: "Email atau password salah",
      });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: "Email atau password salah",
      });
    }

    // Normalisasi role & device
    const role = user.role.toLowerCase().trim();
    const deviceType = device.toLowerCase().trim();

    // Debug log (biar kelihatan di console backend)
    console.log("ROLE LOGIN:", role);
    console.log("DEVICE LOGIN:", deviceType);

    // =====================================================
    // PEMBATASAN ROLE SESUAI DATABASE
    // =====================================================

    // Role yang hanya boleh Web
    if (
    deviceType === "mobile" &&
    (role === "super_admin" || role === "admin_perusahaan")
    ) {
    return res.status(403).json({
        success: false,
        message: "Role ini hanya bisa login melalui Web",
    });
    }

    // Role yang hanya boleh Mobile
    if (
    deviceType === "web" &&
    (role === "agen" ||
        role === "penumpang" ||
        role === "keluarga")
    ) {
    return res.status(403).json({
        success: false,
        message: "Role ini hanya bisa login melalui Mobile",
    });
    }

    // =====================================================
    // LOGIN BERHASIL
    // =====================================================

    res.json({
      success: true,
      message: "Login berhasil",
      data: {
        id: Number(user.id),
        email: user.email,
        role: user.role,
        profile_image: user.profile_image,
      },
    });
  } catch (err) {
    console.error("Login error:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

// =====================================================
// GET ALL USERS
// =====================================================

router.get("/", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, email, role, profile_image FROM public.users"
    );

    const users = result.rows.map((u) => ({
      ...u,
      id: Number(u.id),
    }));

    res.json({ success: true, data: users });
  } catch (err) {
    console.error("Fetch users error:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

// =====================================================
// REGISTER USER
// =====================================================

router.post("/", async (req, res) => {
  const { email, password } = req.body;
  const role = (req.body.role || "penumpang").toLowerCase();

  try {
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email dan password wajib diisi",
      });
    }

    const checkUser = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email]
    );

    if (checkUser.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Email sudah terdaftar",
      });
    }

    const hashedPassword = await bcrypt.hash(password, saltRounds);

    await pool.query(
      "INSERT INTO users (email, password, role, created_at) VALUES ($1, $2, $3, NOW())",
      [email, hashedPassword, role]
    );

    res.json({
      success: true,
      message: "User berhasil ditambahkan sebagai " + role,
    });
  } catch (err) {
    console.error("Create user error:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

// =====================================================
// DELETE USER
// =====================================================

router.delete("/:id", async (req, res) => {
  try {
    await pool.query("DELETE FROM users WHERE id = $1", [
      Number(req.params.id),
    ]);
    res.json({
      success: true,
      message: "User berhasil dihapus",
    });
  } catch (err) {
    console.error("Delete user error:", err.message);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

module.exports = router;
