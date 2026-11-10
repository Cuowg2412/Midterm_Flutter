const express = require('express');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');

const router = express.Router();

function deleteLocalImageIfExists(imagePathValue) {
  if (imagePathValue && imagePathValue.startsWith('/uploads/')) {
    const fullPath = path.join(__dirname, '..', imagePathValue);
    if (fs.existsSync(fullPath)) {
      fs.unlinkSync(fullPath);
    }
  }
}

// GET /api/users - Lay danh sach nguoi dung (co bao ve JWT)
router.get('/', authMiddleware, async (req, res) => {
  try {
    const users = await User.find().sort({ _id: -1 });
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi tải danh sách người dùng.' });
  }
});

// GET /api/users/export - Xuat du lieu JSON chi gom 4 truong email, matkhau, hoten, hinhanh
router.get('/export', authMiddleware, async (req, res) => {
  try {
    const users = await User.find({}, { _id: 0, email: 1, matkhau: 1, hoten: 1, hinhanh: 1 }).lean();
    res.json(users);
  } catch (error) {
    console.error('Export users error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi xuất dữ liệu.' });
  }
});

// POST /api/users - Them nguoi dung
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { email, matkhau, hoten, hinhanh } = req.body;

    if (!email || !matkhau || !hoten) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ email, mật khẩu và họ tên.' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(400).json({ message: 'Email đã tồn tại trong hệ thống.' });
    }

    const user = new User({
      email: normalizedEmail,
      matkhau: matkhau.trim(),
      hoten: hoten.trim(),
      hinhanh: hinhanh || '',
    });
    await user.save();

    res.status(201).json(user);
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi thêm người dùng.' });
  }
});

// POST /api/users/batch-delete - Xoa nhieu nguoi dung cung luc
router.post('/batch-delete', authMiddleware, async (req, res) => {
  try {
    const { ids } = req.body;
    if (!Array.isArray(ids) || ids.length === 0) {
      return res.status(400).json({ message: 'Danh sách ID cần xóa không hợp lệ.' });
    }

    const usersToDelete = await User.find({ _id: { $in: ids } });
    for (const user of usersToDelete) {
      deleteLocalImageIfExists(user.hinhanh);
    }

    const result = await User.deleteMany({ _id: { $in: ids } });
    res.json({
      message: `Đã xóa ${result.deletedCount} người dùng thành công.`,
      deletedCount: result.deletedCount,
    });
  } catch (error) {
    console.error('Batch delete error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi xóa hàng loạt.' });
  }
});

// PUT /api/users/:id - Cap nhat nguoi dung
router.put('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;
    const { email, matkhau, hoten, hinhanh } = req.body;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
    }

    if (email) {
      const normalizedEmail = email.trim().toLowerCase();
      if (normalizedEmail !== user.email) {
        const duplicate = await User.findOne({ email: normalizedEmail });
        if (duplicate) {
          return res.status(400).json({ message: 'Email mới đã được sử dụng.' });
        }
      }
      user.email = normalizedEmail;
    }

    if (hinhanh !== undefined && hinhanh !== user.hinhanh) {
      deleteLocalImageIfExists(user.hinhanh);
    }

    if (matkhau) user.matkhau = matkhau.trim();
    if (hoten) user.hoten = hoten.trim();
    if (hinhanh !== undefined) user.hinhanh = hinhanh;

    await user.save();
    res.json(user);
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi cập nhật người dùng.' });
  }
});

// DELETE /api/users/:id - Xoa nguoi dung
router.delete('/:id', authMiddleware, async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng.' });
    }

    deleteLocalImageIfExists(user.hinhanh);

    await User.findByIdAndDelete(id);
    res.json({ message: 'Đã xóa người dùng thành công.' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Lỗi máy chủ khi xóa người dùng.' });
  }
});

module.exports = router;
