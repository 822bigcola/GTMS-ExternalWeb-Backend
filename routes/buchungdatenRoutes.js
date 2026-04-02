const express = require("express");
const router = express.Router();
const auth = require("../middleware/authyMiddleware");

const {
  getArtikel,
  insertBuchung,
  createAccountWebExternal,
  loginAccountWebExternal,
} = require("../controllers/buchungdatenControllers");

// GET
router.get("/artikel", getArtikel);

// POST
router.post("/buchung", auth, insertBuchung);

router.post("/create-account", createAccountWebExternal);
router.post("/login", loginAccountWebExternal);

module.exports = router;
