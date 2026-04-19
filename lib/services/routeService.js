const axios = require("axios");

// OSRM PUBLIC (gratis)
const OSRM_URL = "https://router.project-osrm.org/route/v1/driving";

async function getRoute(start, end) {
    try {
        const url = `${OSRM_URL}/${start.lng},${start.lat};${end.lng},${end.lat}?overview=full&geometries=geojson`;

        const response = await axios.get(url);

        if (!response.data.routes || response.data.routes.length === 0) {
            return [];
        }

        const coordinates = response.data.routes[0].geometry.coordinates;

        // convert ke format flutter_map (lat, lng)
        return coordinates.map((c) => ({
            lat: c[1],
            lng: c[0],
        }));
    } catch (error) {
        console.error("ROUTE SERVICE ERROR:", error.message);
        return [];
    }
}

module.exports = {
    getRoute,
};