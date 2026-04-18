const express = require('express');
const router = express.Router();

const driverController = require('../controllers/driverController');

// GET DRIVER BERDASARKAN COMPANY
router.get('/drivers', driverController.getDrivers);

// TAMBAH DRIVER
router.post('/drivers', driverController.createDriver);

module.exports = router;