const { Pool } = require('pg');
require("dotenv").config();

// Konfigurasi Pool Koneksi
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false, // Wajib untuk Neon/Railway
  },
});

// Cek Koneksi saat Startup
pool.connect((err, client, release) => {
  if (err) {
    return console.error("❌ GAGAL SAMBUNG DATABASE NEON:", err.message);
  }
  console.log("✅ DATABASE NEON TERHUBUNG!");
  release();
});

// Helper untuk Social Login (Google & Facebook)
pool.upsertSocialUser = async (email, name, provider, social_id) => {
    try {
        // Gunakan skema public.users secara eksplisit
        let result = await pool.query("SELECT * FROM public.users WHERE email = $1", [email]);
        
        if (result.rows.length === 0) {
            // Jika user baru, buat akun dengan role default 'penumpang'
            result = await pool.query(
                "INSERT INTO public.users (email, name, role, provider, social_id, created_at) VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *",
                [email, name, 'penumpang', provider, social_id]
            );
        }
        return result.rows[0];
    } catch (err) {
        console.error("Error di db.js (upsertSocialUser):", err.message);
        throw err;
    }
};

module.exports = pool;