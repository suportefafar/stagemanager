import "dotenv/config";
import mongoose from "mongoose";
import express from "express";
import cors from "cors";

const app = express();
const port = 3000;
// Use middleware to parse JSON request bodies
app.use(express.json());
app.use(cors());

import {
  readAllRooms,
  readRoomByToken,
  readRoomByID,
  createRoom,
  updateRoom,
  updateStatusTimerRoom,
  deleteRoom,
  increaseTimerRoom,
  decreaseTimerRoom,
} from "./controllers/Room.js";
import config from "./config.js";

try {
  mongoose.connect(config.mongoDbUri + "?retryWrites=true&w=majority");
} catch (error) {
  LOGGER.error("Could not connect to DB");
}

async function countDown(room) {
  const room_db = await readRoomByID(room.id);

  if (room_db.status !== "play") {
    return false;
  }

  room_db.time--;

  console.log(room_db);

  await updateRoom(room_db.id, room_db);

  setTimeout(() => countDown(room).then(() => {}), 1000);
}

async function timerManager(id) {
  const room = await readRoomByID(id);
  if (!room) return false;
  setTimeout(() => countDown(room).then(() => {}), 1000);
}

// GET all rooms
// GET /api/v1/rooms
app.get("/api/v1/rooms", async (req, res) => {
  try {
    const rooms = await readAllRooms();
    res.status(200).json(rooms);
  } catch (error) {
    res.status(500).json({ message: "Failed to retrieve rooms." });
  }
});

// GET a single room by ID
// GET /api/v1/rooms/:id
app.get("/api/v1/rooms/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const room = await readRoomByID(id);
    if (!room) {
      return res.status(404).json({ message: "Room not found." });
    }
    res.status(200).json(room);
  } catch (error) {
    res.status(500).json({ message: "Failed to retrieve room." });
  }
});

// GET a single room by token
// GET /api/v1/rooms/token/:token
app.get("/api/v1/rooms/token/:token", async (req, res) => {
  try {
    const { token } = req.params;
    const room = await readRoomByToken(token);
    if (!room) {
      return res.status(404).json({ message: "Room not found." });
    }
    res.status(200).json(room);
  } catch (error) {
    res.status(500).json({ message: "Failed to retrieve room." });
  }
});

// POST a new room
// POST /api/v1/rooms
app.post("/api/v1/rooms", async (req, res) => {
  try {
    const aux = req.body;

    const newRoom = await createRoom(req.body);
    res.status(201).json(newRoom);
  } catch (error) {
    res.status(500).json({ message: "Failed to create room." });
  }
});

// PUT to update an existing room
// PUT /api/v1/rooms/:id
app.put("/api/v1/rooms/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const updatedRoom = await updateRoom(id, req.body);
    await timerManager(id);
    if (!updatedRoom) {
      return res.status(404).json({ message: "Room not found." });
    }
    res.status(200).json(updatedRoom);
  } catch (error) {
    res.status(500).json({ message: "Failed to update room." });
  }
});

app.put("/api/v1/rooms/:id/timer/status", async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const updatedRoom = await updateStatusTimerRoom(id, status);
    await timerManager(id);
    if (!updatedRoom) {
      return res.status(404).json({ message: "Room not found." });
    }
    res.status(200).json(updatedRoom);
  } catch (error) {
    res.status(500).json({ message: "Failed to update room." });
  }
});

app.put("/api/v1/rooms/:id/timer/increase", async (req, res) => {
  try {
    const { id } = req.params;
    const { amount } = req.body;
    const updatedRoom = await increaseTimerRoom(id, amount);

    if (!updatedRoom) {
      return res.status(404).json({ message: "Room not found." });
    }

    res.status(200).json(updatedRoom);
  } catch (error) {
    res.status(500).json({ message: "Failed to update room." });
  }
});

app.put("/api/v1/rooms/:id/timer/decrease", async (req, res) => {
  try {
    const { id } = req.params;
    const { amount } = req.body;
    const updatedRoom = await decreaseTimerRoom(id, amount);

    if (!updatedRoom) {
      return res.status(404).json({ message: "Room not found." });
    }

    res.status(200).json(updatedRoom);
  } catch (error) {
    res.status(500).json({ message: "Failed to update room." });
  }
});

// DELETE a room
// DELETE /api/v1/rooms/:id
app.delete("/api/v1/rooms/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const deletedRoom = await deleteRoom(id);
    if (!deletedRoom) {
      return res.status(404).json({ message: "Room not found." });
    }
    res.status(200).json({ message: "Room deleted successfully." });
  } catch (error) {
    res.status(500).json({ message: "Failed to delete room." });
  }
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`);
});
