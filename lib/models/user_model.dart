class UserModel {
  String? id;
  String email;
  String matkhau;
  String hoten;
  String hinhanh;

  UserModel({
    this.id,
    required this.email,
    required this.matkhau,
    required this.hoten,
    this.hinhanh = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      matkhau: json['matkhau'] ?? '',
      hoten: json['hoten'] ?? '',
      hinhanh: json['hinhanh'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'matkhau': matkhau,
      'hoten': hoten,
      'hinhanh': hinhanh,
    };
  }
}
