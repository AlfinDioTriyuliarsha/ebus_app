const axios = require("axios");

const ORS_API_KEY = process.env.ORS_API_KEY; // simpan di .env

async function generateRoute(start, end) {
    try {
        const response = await axios.post(
            "https://api.openrouteservice.org/v2/directions/driving-car/geojson",
            {
                coordinates: [
                    [start.lng, start.lat],
                    [end.lng, end.lat]
                ]
            },
            {
                headers: {
                    Authorization: ORS_API_KEY,
                    "Content-Type": "application/json"
                }
            }
        );

        const coords =
            response.data.features[0].geometry.coordinates;

        // 🔥 convert ke format kamu (lat, lng)
        return coords.map(c => ({
            lat: c[1],
            lng: c[0]
        }));

    } catch (error) {
        console.error("ORS ERROR:", error.response?.data || error.message);
        throw error;
    }
}

module.exports = { generateRoute };