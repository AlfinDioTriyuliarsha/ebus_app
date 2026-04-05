// routes/userRoutes.js
const express = require("express");
const router = express.Router();
const pool = require("../db");
const bcrypt = require("bcrypt");
const multer = require("multer");
const path = require("path");

const saltRounds = 10;

// =====================================================
// KONFIGURASI UPLOAD FOTO (TETAP)
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
// UPLOAD FOTO PROFIL (TETAP)
// =====================================================
router.post("/upload-profile/:id", upload.single("profile_picture"), async (req, res) => {
  const userId = Number(req.params.id);
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: "Tidak ada file yang diunggah" });
    }
    const imageUrl = `/uploads/profiles/${req.file.filename}`;
    await pool.query("UPDATE public.users SET profile_image = $1 WHERE id = $2", [imageUrl, userId]);
    res.json({ success: true, message: "Foto profil berhasil diperbarui", imageUrl: imageUrl });
  } catch (err) {
    console.error("Upload error:", err.message);
    res.status(500).json({ success: false, message: "Gagal memperbarui foto" });
  }
});

// =====================================================
// LOGIN USER (SYNC DENGAN PGADMIN)
// =====================================================
router.post("/login", async (req, res) => {
  const { email, password, device } = req.body;

  try {
    if (!email || !password || !device) {
      return res.status(400).json({ success: false, message: "Data tidak lengkap" });
    }

    // Ambil data langsung dari tabel yang Anda kelola di pgAdmin
    const result = await pool.query(
      "SELECT * FROM public.users WHERE LOWER(TRIM(email)) = LOWER(TRIM($1))", 
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: "Email tidak ditemukan di pgAdmin" });
    }

    const user = result.rows[0];

    // SOLUSI KRUSIAL: Hapus spasi kosong dari data pgAdmin
    const dbPassword = user.password ? user.password.toString().trim() : "";
    const inputPassword = password ? password.toString().trim() : "";

    // Bandingkan Teks Biasa (misal: '1234') ATAU Hash Bcrypt
    const isMatch = (inputPassword === dbPassword) || await bcrypt.compare(inputPassword, dbPassword);

    if (!isMatch) {
      return res.status(401).json({ success: false, message: "Password salah (Cek di pgAdmin)" });
    }

    const role = (user.role || "").toLowerCase().trim();
    const deviceType = (device || "").toLowerCase().trim();

    // Validasi Akses (Tetap sesuai punya Anda)
    if (deviceType === "mobile" && (role === "super_admin" || role === "admin_perusahaan")) {
      return res.status(403).json({ success: false, message: "Role ini khusus login Web" });
    }
    if (deviceType === "web" && (role === "agen" || role === "penumpang" || role === "keluarga")) {
      return res.status(403).json({ success: false, message: "Role ini khusus login Mobile" });
    }

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
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// =====================================================
// GET ALL USERS (TETAP)
// =====================================================
router.get("/", async (req, res) => {
  try {
    const result = await pool.query("SELECT id, email, role, profile_image FROM public.users");
    const users = result.rows.map((u) => ({ ...u, id: Number(u.id) }));
    res.json({ success: true, data: users });
  } catch (err) {
    console.error("Fetch users error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// =====================================================
// REGISTER USER (TETAP)
// =====================================================
router.post("/", async (req, res) => {
  const { email, password } = req.body;
  const role = (req.body.role || "penumpang").toLowerCase();

  try {
    if (!email || !password) {
      return res.status(400).json({ success: false, message: "Email dan password wajib diisi" });
    }

    const checkUser = await pool.query("SELECT * FROM public.users WHERE LOWER(TRIM(email)) = LOWER(TRIM($1))", [email]);
    if (checkUser.rows.length > 0) {
      return res.status(400).json({ success: false, message: "Email sudah terdaftar" });
    }

    const hashedPassword = await bcrypt.hash(password, saltRounds);
    await pool.query(
      "INSERT INTO public.users (email, password, role, created_at) VALUES ($1, $2, $3, NOW())",
      [email, hashedPassword, role]
    );

    res.json({ success: true, message: "User berhasil ditambahkan sebagai " + role });
  } catch (err) {
    console.error("Create user error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// =====================================================
// DELETE USER (TETAP)
// =====================================================
router.delete("/:id", async (req, res) => {
  try {
    await pool.query("DELETE FROM public.users WHERE id = $1", [Number(req.params.id)]);
    res.json({ success: true, message: "User berhasil dihapus" });
  } catch (err) {
    console.error("Delete user error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;