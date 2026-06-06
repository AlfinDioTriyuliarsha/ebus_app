const admin = require("firebase-admin");

if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  const serviceAccount = JSON.parse(
    process.env.FIREBASE_SERVICE_ACCOUNT
  );

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  console.log("🔥 FIREBASE READY");
} else {
  console.log("⚠️ FIREBASE_SERVICE_ACCOUNT TIDAK DITEMUKAN");
}

module.exports = admin;