import Room from "../models/Room.js";

export async function createRoom(roomInputs) {
  if (!roomInputs?.title) {
    console.log("Room must include a title");
    throw new Error("Room must include a title");
  }

  const room = await Room.create(roomInputs);

  return room;
}

export async function readAllRooms() {
  return await Room.find({});
}

export async function readRoomByID(id, attributes = null) {
  if (!id) {
    throw new Error("id must be passed");
  }

  if (typeof id !== "string") {
    throw new Error("id must be type of string");
  }

  let room = await Room.findById(id).exec();
  if (attributes) room = await Room.findById(id, attributes).exec();

  return room;
}

export async function readRoomByToken(token) {
  if (!token) {
    throw new Error("token must be passed");
  }

  if (typeof token !== "string") {
    throw new Error("token must be type of string");
  }

  let room = await Room.find({
    token,
  }).exec();

  return room;
}

export async function updateRoom(id, roomInput) {
  if (!id && !roomInput) {
    throw new Error("ID or Room info missing");
  }

  if (typeof id !== "string") {
    throw new Error("ID must be type of string");
  }

  const updatingRoom = await readRoomByID(id);

  updatingRoom.title = roomInput.title;
  updatingRoom.description = roomInput.description;
  updatingRoom.token = roomInput.token;
  updatingRoom.time = roomInput.time;
  updatingRoom.status = roomInput.status;
  updatingRoom.has_message = roomInput.has_message;
  updatingRoom.message = roomInput.message;

  await updatingRoom.save();

  return updatingRoom;
}

export async function updateStatusTimerRoom(id, status) {
  if (!id && !status) {
    throw new Error("ID or Room info missing");
  }

  if (typeof id !== "string" || typeof status !== "string") {
    throw new Error("ID ans must be type of string");
  }

  const updatingRoom = await readRoomByID(id);

  if (status === "stop") updatingRoom.time = 3000;

  updatingRoom.status = status;

  await updatingRoom.save();

  return updatingRoom;
}

export async function increaseTimerRoom(id, amount) {
  if (!id && !amount) {
    throw new Error("ID or Room info missing");
  }

  if (typeof id !== "string" || typeof amount !== "number") {
    throw new Error("ID must be type of string and amount must be number");
  }

  const updatingRoom = await readRoomByID(id);

  updatingRoom.time += amount;

  await updatingRoom.save();

  return updatingRoom;
}

export async function decreaseTimerRoom(id, amount) {
  if (!id && !amount) {
    throw new Error("ID or Room info missing");
  }

  if (typeof id !== "string" || typeof amount !== "number") {
    throw new Error("ID must be type of string and amount must be number");
  }

  const updatingRoom = await readRoomByID(id);

  updatingRoom.time -= amount;

  await updatingRoom.save();

  return updatingRoom;
}

export async function deleteRoom(id) {
  const deletedRoom = await Room.deleteOne({ _id: id });

  console.log(deletedRoom);

  return deletedRoom;
}
