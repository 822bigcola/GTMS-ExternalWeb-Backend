const jwt = require("jsonwebtoken");

const SECRET_KEY = process.env.SECRET_KEY || "secret_key";

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      success: false,
      message: "Chưa đăng nhập",
    });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, SECRET_KEY);

    req.user = decoded; // 👈 gắn user vào request

    next();
  } catch (err) {
    return res.status(403).json({
      success: false,
      message: "Token không hợp lệ",
    });
  }
};

module.exports = authMiddleware;
