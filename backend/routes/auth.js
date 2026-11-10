const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const router = express.Router();

// POST /api/auth/register - Dang ky tai khoan (luu vao collection users)
router.post('/register', async (req, res) => {
  try {
    const { email, password, matkhau, hoten } = req.body;
    const rawPassword = matkhau || password;

    if (!email || !rawPassword) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ email và mật khẩu.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(400).json({ message: 'Email đã tồn tại trong hệ thống.' });
    }

    const user = new User({
      email: normalizedEmail,
      matkhau: rawPassword,
      hoten: (hoten && hoten.trim()) || normalizedEmail.split('@')[0],
      hinhanh: '',
    });
    await user.save();

    res.status(201).json({ message: 'Đăng ký thành công.', user });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi đăng ký.' });
  }
});

// POST /api/auth/login - Dang nhap voi email + matkhau
router.post('/login', async (req, res) => {
  try {
    const { email, password, matkhau } = req.body;
    const rawPassword = matkhau || password;

    if (!email || !rawPassword) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || user.matkhau !== rawPassword) {
      return res.status(401).json({ message: 'Email hoặc mật khẩu không đúng.' });
    }

    const token = jwt.sign(
      { id: user._id, email: user.email, hoten: user.hoten },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Đăng nhập thành công.',
      token,
      user: {
        _id: user._id,
        email: user.email,
        hoten: user.hoten,
        hinhanh: user.hinhanh,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi đăng nhập.' });
  }
});

module.exports = router;
