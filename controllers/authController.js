const pool = require("../config/db");

const login = async(req, res) => {
    const { email, password } = req.body;

    try {
        const result = await pool.query(
            "SELECT * FROM users WHERE email = $1 AND password = $2", [email, password]
        );

        if (result.rows.length > 0) {
            res.json({
                success: true,
                user: result.rows[0],
            });
        } else {
            res.json({
                success: false,
                message: "Invalid email or password",
            });
        }
    } catch (err) {
        console.error(err);
        res.status(500).send("Server error");
    }
};

module.exports = { login };