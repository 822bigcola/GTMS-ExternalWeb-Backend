const {
  getArtikelService,
  insertBuchungService,
  createAccountWeb,
  loginAccountWeb,
} = require("../services/buchungdatenServices");

// GET artikel
const getArtikel = async (req, res) => {
  try {
    const data = await getArtikelService();
    res.json(data);
  } catch (err) {
    console.error(err);
    res.status(500).send("DB error");
  }
};

// POST buchung
const insertBuchung = async (req, res) => {
  try {
    const list = req.body;
    const user = req.user;

    if (!Array.isArray(list) || list.length === 0) {
      return res.status(400).json({ message: "Invalid data" });
    }

    await insertBuchungService(list, user);

    res.json({ message: "Insert success" });
  } catch (err) {
    console.error("ERROR:", err);
    res.status(500).json({ message: err.message });
  }
};

const createAccountWebExternal = async (req, res) => {
  try {
    const accountData = req.body;

    const result = await createAccountWeb(accountData);

    res.json(result);
  } catch (err) {
    console.error("ERROR:", err);
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};
const loginAccountWebExternal = async (req, res) => {
  try {
    const accountData = req.body;
    const result = await loginAccountWeb(accountData);

    res.json(result);
  } catch (err) {
    console.error("ERROR:", err);
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
};
module.exports = {
  getArtikel,
  insertBuchung,
  createAccountWebExternal,
  loginAccountWebExternal,
};
