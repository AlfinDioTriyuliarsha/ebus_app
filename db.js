// db.js
const { Pool } = require('pg');
require("dotenv").config();

// Hanya panggil dotenv jika tidak di production
if (process.env.NODE_ENV !== 'production') {
  require("dotenv").config();
}

// Konfigurasi Pool Koneksi
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false, // Wajib untuk Neon/Railway agar tidak kena Error Self-Signed Certificate
  },
  // Tambahkan limit koneksi agar tidak melebihi kuota Neon Free Tier
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Cek Koneksi saat Startup
pool.connect((err, client, release) => {
  if (err) {
    return console.error("❌ GAGAL SAMBUNG DATABASE NEON:", err.stack);
  }
  console.log("✅ DATABASE NEON TERHUBUNG!");
  release();
});

// Helper untuk Social Login (Google & Facebook)
pool.upsertSocialUser = async (email, name, provider, social_id) => {
    try {
        // Gunakan query yang lebih aman dengan pengecekan baris
        const checkUser = await pool.query("SELECT * FROM public.users WHERE email = $1", [email]);
        
        if (checkUser.rows.length === 0) {
            // Gunakan ON CONFLICT untuk mencegah double insert jika email sudah ada
            const insertQuery = `
                INSERT INTO public.users (email, name, role, provider, social_id, created_at) 
                VALUES ($1, $2, $3, $4, $5, NOW()) 
                ON CONFLICT (email) DO UPDATE 
                SET name = EXCLUDED.name, provider = EXCLUDED.provider, social_id = EXCLUDED.social_id
                RETURNING *`;
            
            const newUser = await pool.query(insertQuery, [email, name, 'penumpang', provider, social_id]);
            return newUser.rows[0];
        }
        
        return checkUser.rows[0];
    } catch (err) {
        console.error("🔴 Error di db.js (upsertSocialUser):", err.message);
        throw err;
    }
};

module.exports = pool;