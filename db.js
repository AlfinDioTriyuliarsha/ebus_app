const { Pool } = require('pg');

// Gunakan DATABASE_URL dari Railway Environment Variables
const pool = new Pool({
  // Ganti URL_DATABASE_NEON_ANDA dengan link koneksi Neon Anda
  connectionString: "URL_DATABASE_NEON_ANDA",
  ssl: {
    rejectUnauthorized: false, 
  },
});

// Tambahkan parameter sslmode di sini untuk memastikan laptop tidak error
pool.on('connect', () => {
  console.log("Memulai jabat tangan SSL...");
});

pool.connect((err, client, release) => {
  if (err) {
    return console.error("❌ GAGAL SAMBUNG DATABASE:", err.message);
  }
  console.log("✅ DATABASE TERHUBUNG!");
  release();
});
// ===================================================================
// TAMBAHAN: Fungsi Helper untuk Social Login (Google & Facebook)
// ===================================================================
pool.upsertSocialUser = async (email, name, provider, social_id) => {
    try {
        // Cek apakah user sudah ada berdasarkan email
        let result = await pool.query("SELECT * FROM public.users WHERE email = $1", [email]);
        
        if (result.rows.length === 0) {
            // Jika belum ada, insert (Gunakan skema public agar lebih aman)
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