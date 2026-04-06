const { sql } = require("../db");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");

// GET artikel
const getArtikelService = async () => {
  const pool = await sql.connect();
  const result = await pool.request().execute("sp_GetArtikeltoGoodsReceipts");

  return result.recordset.map((row) => ({
    Artikel: row.Artikel,
    Condition: row.Artikelzustand,
    Lagerort: row.Lagerort,
    Kostengruppe: row.Kostengruppe,
  }));
};

// POST buchung
const insertBuchungService = async (list, user) => {
  let transaction;
  try {
    const pool = await sql.connect();

    transaction = new sql.Transaction(pool);
    await transaction.begin();

    for (const item of list) {
      if (!item.Article || !item.Quantity) {
        throw new Error("Missing Article or Quantity");
      }

      const request = new sql.Request(transaction);

      await request
        .input("Artikel", sql.VarChar(50), String(item.Article).trim())
        .input("Menge", sql.Float, Number(item.Quantity))
        .input("Lagerort", sql.VarChar(50), item.Lagerort || "")
        .input("Benutzer", sql.VarChar(50), user.alias || "")
        .input("ArtikelzustandTemp", sql.VarChar(50), item.Condition || "")
        .input("Kostentraeger1", sql.VarChar(50), item.Line || "")
        .execute("sp_InsertBuchung");
    }

    await transaction.commit();
  } catch (err) {
    if (transaction) {
      await transaction.rollback();
    }
    throw err;
  }
};

const createAccountWeb = async (accountData) => {
  const { username, password, alias } = accountData;

  try {
    const pool = await sql.connect();

    // 1. Validate
    if (!username || !password) {
      return {
        success: false,
        message: "Thiếu username hoặc password",
      };
    }

    // 2. Check user tồn tại
    const checkUser = await pool
      .request()
      .input("Username", sql.NVarChar(50), username).query(`
        SELECT * FROM tblAccountExternalWeb 
        WHERE Username = @Username
      `);

    if (checkUser.recordset.length > 0) {
      return {
        success: false,
        message: "Username đã tồn tại",
      };
    }

    // 3. Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 4. Insert DB
    await pool
      .request()
      .input("Username", sql.NVarChar(50), username)
      .input("Alias", sql.NVarChar(50), alias || "")
      .input("PasswordHash", sql.NVarChar(255), hashedPassword).query(`
        INSERT INTO tblAccountExternalWeb (Username, PasswordHash,Alias)
        VALUES (@Username, @PasswordHash,@Alias)
      `);

    return {
      success: true,
      message: "Tạo tài khoản thành công",
    };
  } catch (err) {
    console.error("createAccountWeb error:", err);
    throw err;
  }
};
const loginAccountWeb = async (accountData) => {
  const { username, password } = accountData;
  try {
    const pool = await sql.connect();

    // 1. Validate
    if (!username || !password) {
      return {
        success: false,
        message: "Thiếu username hoặc password",
      };
    }
    // 2. Check user tồn tại
    const checkUser = await pool
      .request()
      .input("Username", sql.NVarChar(50), username).query(`
        SELECT * FROM tblAccountExternalWeb 
        WHERE Username = @Username
      `);

    if (checkUser.recordset.length === 0) {
      return {
        success: false,
        message: "Username không tồn tại",
      };
    }

    // 3. Verify password
    const isMatch = await bcrypt.compare(
      password,
      checkUser.recordset[0].PasswordHash,
    );
    if (!isMatch) {
      return {
        success: false,
        message: "Sai password",
      };
    }
    const token = jwt.sign(
      {
        alias: checkUser.recordset[0].Alias,
        username: username,
      },
      process.env.SECRET_KEY,
      { expiresIn: "1h" },
    );

    return {
      success: true,
      message: "Đăng nhập thành công",
      alias: checkUser.recordset[0].Alias,
      token: token,
    };
  } catch (err) {
    console.error("loginAccountWeb error:", err);
    throw err;
  }
};
module.exports = {
  getArtikelService,
  insertBuchungService,
  createAccountWeb,
  loginAccountWeb,
};
