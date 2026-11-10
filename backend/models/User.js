const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      trim: true,
      lowercase: true,
    },
    matkhau: {
      type: String,
      required: [true, 'Mat khau is required'],
    },
    hoten: {
      type: String,
      required: [true, 'Ho ten is required'],
      trim: true,
    },
    hinhanh: {
      type: String,
      default: '',
    },
  },
  {
    versionKey: false,
  }
);

module.exports = mongoose.model('User', userSchema);
