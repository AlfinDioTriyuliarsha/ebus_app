// db.js
const { Pool } = require('pg');

const pool = new Pool({
    user: 'postgres', 
    host: 'localhost',
    database: 'ebusdb', 
    password: '1234', 
    port: 5432,
});

// ===================================================================
// TAMBAHAN: Fungsi Helper untuk Social Login (Google & Facebook)
// ===================================================================
pool.upsertSocialUser = async (email, name, provider, social_id) => {
    try {
        // Cek apakah user sudah ada berdasarkan email
        let result = await pool.query("SELECT * FROM users WHERE email = $1", [email]);
        
        if (result.rows.length === 0) {
            // Jika belum ada, insert sesuai kolom yang ada di pgAdmin Anda
            result = await pool.query(
                "INSERT INTO users (email, name, role, provider, social_id, created_at) VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *",
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