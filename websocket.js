const WebSocket = require("ws");

let wss; // ✅ HARUS let, bukan const

function init(server) {
  wss = new WebSocket.Server({ server });

  wss.on("connection", (ws) => {
    console.log("🟢 Client connected");

    ws.on("close", () => {
      console.log("🔴 Client disconnected");
    });
  });
}

function broadcastLocation(data) {
  if (!wss) return;

  const message = JSON.stringify({
    type: "bus_location",
    data,
  });

  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

module.exports = {
  init,
  broadcastLocation,
};