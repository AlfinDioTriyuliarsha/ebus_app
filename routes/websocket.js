let wss;

function init(server) {
  const WebSocket = require("ws");
  const wss = new WebSocket.Server({ server, path: "/ws" });
  wss = new WebSocket.Server({ server });

  wss.on("connection", (ws) => {
    console.log("Client connected");
  });
}

function broadcastLocation(data) {
  if (!wss) return;

  const message = JSON.stringify({
    type: "bus_location",
    data
  });

  wss.clients.forEach(client => {
    if (client.readyState === 1) {
      client.send(message);
    }
  });
}

module.exports = { init, broadcastLocation };