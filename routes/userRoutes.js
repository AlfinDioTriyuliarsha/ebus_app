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
    destination: (req, file, cb) => cb(null, "uploads/profiles/"),
    filename: (req, file, cb) => cb(null, "profile-" + Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage: storage, limits: { fileSize: 2 * 1024 * 1024 } });

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
    // 1. Cari user di pgAdmin (abaikan spasi dan huruf kapital)
    const result = await pool.query(
      "SELECT * FROM public.users WHERE LOWER(TRIM(email)) = LOWER(TRIM($1))", 
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: "Email tidak ditemukan" });
    }

    const user = result.rows[0];

    // 2. Bersihkan data password dari database pgAdmin
    const dbPassword = user.password ? user.password.toString().trim() : "";
    const inputPassword = password ? password.toString().trim() : "";

    // 3. LOGIKA VALIDASI GANDA (SANGAT PENTING):
    let isMatch = false;

    // Cek A: Apakah ini password polos? (Untuk user '1234' tadi)
    if (inputPassword === dbPassword) {
      isMatch = true;
    } 
    // Cek B: Jika tidak cocok polos, apakah ini password Hash? (Untuk user lama Anda)
    else if (dbPassword.startsWith("$2")) { 
      // Kita hanya panggil bcrypt jika dbPassword terlihat seperti format Hash ($2b$...)
      isMatch = await bcrypt.compare(inputPassword, dbPassword);
    }

    if (!isMatch) {
      return res.status(401).json({ success: false, message: "Password salah" });
    }

    // 4. NORMALISASI ROLE & DEVICE
    const role = (user.role || "").toLowerCase().trim();
    const deviceType = (device || "").toLowerCase().trim();

    // Pembatasan Akses (Tetap sesuai logika Anda)
    if (deviceType === "mobile" && (role === "super_admin" || role === "admin_perusahaan")) {
      return res.status(403).json({ success: false, message: "Role ini hanya untuk Web" });
    }
    if (deviceType === "web" && (role === "agen" || role === "penumpang" || role === "keluarga")) {
      return res.status(403).json({ success: false, message: "Role ini hanya untuk Mobile" });
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
    // Menambahkan ORDER BY agar urutan rapi sesuai ID di pgAdmin
    const result = await pool.query("SELECT id, email, role, profile_image FROM public.users ORDER BY id ASC");
    
    const users = result.rows.map((u) => ({ ...u, id: Number(u.id) }));
    
    // LOG INI SANGAT PENTING: Cek di Railway Logs nanti
    console.log(`[DATABASE CHECK] Berhasil menarik ${users.length} user dari pgAdmin.`);
    
    res.json({ success: true, data: users });
  } catch (err) {
    console.error("Fetch users error:", err.message);
    res.status(500).json({ success: false, message: "Gagal memuat data dari pgAdmin" });
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

// =====================================================
// GET USER BY ID
// =====================================================
router.get("/:id", async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT id, email, role, profile_image FROM public.users WHERE id = $1",
      [Number(req.params.id)]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: "User tidak ditemukan" });
    }

    const user = result.rows[0];
    // Pastikan mengembalikan success: true agar Flutter tidak masuk ke blok Catch/Error
    res.json({ 
      success: true, 
      data: {
        id: Number(user.id),
        email: user.email,
        role: user.role,
        profile_image: user.profile_image
      }
    });
  } catch (err) {
    console.error("Fetch user by ID error:", err.message);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// =====================================================
// UPDATE USER (SIMPAN PROFIL & FOTO)
// =====================================================
router.put("/:id", upload.single("profile_image"), async (req, res) => {
  const userId = Number(req.params.id);
  const { email, role, password } = req.body; // Ambil role juga dari body

  try {
    let updateFields = ["email = $1", "role = $2"];
    let params = [email, role];

    // Jika ada password baru, tambahkan ke query
    if (password && password.trim() !== "") {
      const hashedPassword = await bcrypt.hash(password, 10);
      updateFields.push(`password = $${params.length + 1}`);
      params.push(hashedPassword);
    }

    // Jika ada foto baru
    if (req.file) {
      const imageUrl = req.file.filename;
      updateFields.push(`profile_image = $${params.length + 1}`);
      params.push(imageUrl);
    }

    params.push(userId);
    // Gunakan RETURNING agar kita dapat data yang baru saja diupdate
    const query = `UPDATE public.users SET ${updateFields.join(", ")} WHERE id = $${params.length} RETURNING *`;
    
    const result = await pool.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: "User tidak ditemukan" });
    }

    const updatedUser = result.rows[0]; // Ini pengganti variabel 'user' yang bikin error kemarin

    res.json({
      success: true,
      message: "Update berhasil",
      data: {
        id: Number(updatedUser.id),
        email: updatedUser.email,
        role: updatedUser.role,
        profile_image: updatedUser.profile_image,
      },
    });
  } catch (err) {
    console.error("Update user error:", err.message);
    res.status(500).json({ success: false, message: "Server error: " + err.message });
  }
});

module.exports = router;