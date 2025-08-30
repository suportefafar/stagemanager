import mongoose from "mongoose";
const { Schema, model } = mongoose;

/*
 * This model describe the main object of prometheus-bot:
 * It is the link between DEMAI ticket with FAFAR ticket,
 * this is kinda a composite unique key(DEMAI_TICKET, FAFAR_TICKET),
 * and, with it in mind, we gather relevant infos, like "status" and "updated_at".
 */

const roomSchema = new Schema({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: "",
  },
  token: {
    type: String,
    default: "",
  },
  time: {
    type: Number,
    default: 3000, // 25 min in seconds
  },
  status: {
    type: String,
    default: "stop", // play, pause, stop
  },
  has_message: {
    type: Boolean,
    default: false,
  },
  message: {
    type: String,
    default: "",
  },
  updated_at: {
    type: Date,
    default: () => Date.now(),
  },
  created_at: {
    type: Date,
    default: () => Date.now(),
    immutable: true,
  },
});

// Middleware for update the 'updated_at' attr, every time the document is updated
roomSchema.pre("save", function (next) {
  this.updated_at = Date.now();

  next();
});

const Room = model("Room", roomSchema);
export default Room;
