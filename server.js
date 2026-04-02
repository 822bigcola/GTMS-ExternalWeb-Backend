const express = require("express");
const cors = require("cors");
require("dotenv").config();

const { connectDB } = require("./db");
const buchungRoutes = require("./routes/buchungdatenRoutes");

const app = express();

app.use(cors());
app.use(express.json());

// connect DB
connectDB();

// routes
app.use("/api", buchungRoutes);

// test
app.get("/", (req, res) => {
  res.send("Backend running...");
});

app.listen(process.env.PORT, "0.0.0.0", () => {
  console.log(`🚀 Server: http://localhost:${process.env.PORT}`);
});
