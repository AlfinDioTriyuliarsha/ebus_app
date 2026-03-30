const pool = require("../config/db");

const findUserByEmailPassword = async(email, password) => {
    const result = await pool.query(
        "SELECT * FROM users WHERE email = $1 AND password = $2", [email, password]
    );
    return result.rows[0];
};

module.exports = { findUserByEmailPassword };