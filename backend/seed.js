require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const sampleUsers = [
  {
    email: 'admin@gmail.com',
    matkhau: '123456',
    hoten: 'Quản trị viên',
    hinhanh: '',
  },
  {
    email: 'nguyenvana@gmail.com',
    matkhau: '123456',
    hoten: 'Nguyễn Văn A',
    hinhanh: '',
  },
  {
    email: 'tranthib@gmail.com',
    matkhau: 'abc123',
    hoten: 'Trần Thị B',
    hinhanh: '',
  },
  {
    email: 'levanc@gmail.com',
    matkhau: 'pass789',
    hoten: 'Lê Văn C',
    hinhanh: '',
  },
];

async function seed() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Drop admins collection if it existed from previous setup
    const collections = await mongoose.connection.db.listCollections({ name: 'admins' }).toArray();
    if (collections.length > 0) {
      await mongoose.connection.db.dropCollection('admins');
      console.log('Dropped old admins collection');
    }

    for (const u of sampleUsers) {
      const exists = await User.findOne({ email: u.email });
      if (!exists) {
        await User.create(u);
        console.log(`Seeded user: ${u.email}`);
      } else {
        console.log(`User already exists: ${u.email}`);
      }
    }

    await mongoose.disconnect();
    console.log('Seed completed.');
    process.exit(0);
  } catch (error) {
    console.error('Seed error:', error);
    process.exit(1);
  }
}

seed();
