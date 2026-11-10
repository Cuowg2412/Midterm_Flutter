import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme_controller.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import 'login_screen.dart';
import 'user_detail_screen.dart';

enum UserSortOption { newest, nameAsc, nameDesc, emailAsc }

enum ImageFilterOption { all, withImage, withoutImage }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  UserSortOption _sortOption = UserSortOption.newest;
  ImageFilterOption _imageFilter = ImageFilterOption.all;

  // Phân trang
  int _currentPage = 1;
  int _pageSize = 6;

  // Chọn nhiều để xóa hàng loạt
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  // Ẩn/hiện mật khẩu từng dòng trên bảng Web
  final Set<String> _visiblePasswordIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await UserService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _selectedIds.removeWhere(
          (id) => !_users.any((u) => u.id == id),
        );
        _applyFilterAndSort(resetPage: false);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyFilterAndSort({bool resetPage = true}) {
    _filteredUsers = _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          user.hoten.toLowerCase().contains(_searchQuery) ||
          user.email.toLowerCase().contains(_searchQuery);

      final matchesImage = switch (_imageFilter) {
        ImageFilterOption.all => true,
        ImageFilterOption.withImage => user.hinhanh.isNotEmpty,
        ImageFilterOption.withoutImage => user.hinhanh.isEmpty,
      };

      return matchesSearch && matchesImage;
    }).toList();

    switch (_sortOption) {
      case UserSortOption.newest:
        break;
      case UserSortOption.nameAsc:
        _filteredUsers.sort((a, b) =>
            a.hoten.toLowerCase().compareTo(b.hoten.toLowerCase()));
        break;
      case UserSortOption.nameDesc:
        _filteredUsers.sort((a, b) =>
            b.hoten.toLowerCase().compareTo(a.hoten.toLowerCase()));
        break;
      case UserSortOption.emailAsc:
        _filteredUsers.sort((a, b) =>
            a.email.toLowerCase().compareTo(b.email.toLowerCase()));
        break;
    }

    if (resetPage) {
      _currentPage = 1;
    } else {
      final totalPages = _totalPages;
      if (_currentPage > totalPages) {
        _currentPage = totalPages;
      }
    }
  }

  int get _totalPages =>
      _filteredUsers.isEmpty ? 1 : (_filteredUsers.length / _pageSize).ceil();

  List<UserModel> get _pagedUsers {
    if (_filteredUsers.isEmpty) return [];
    final start = (_currentPage - 1) * _pageSize;
    final end = math.min(start + _pageSize, _filteredUsers.length);
    if (start >= _filteredUsers.length) return [];
    return _filteredUsers.sublist(start, end);
  }

  Future<void> _exportJsonDialog() async {
    try {
      final jsonText = await UserService.exportUsersJson();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.code, color: Colors.blue),
              SizedBox(width: 8),
              Text('Dữ liệu MongoDB (JSON)'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép JSON vào clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Sao chép JSON'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất JSON: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${user.hoten}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await UserService.deleteUser(user.id!);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa người dùng thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedUsers() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hàng loạt'),
        content:
            Text('Bạn có chắc chắn muốn xóa $count người dùng đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Xóa ($count)'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final deleted =
            await UserService.deleteUsersBatch(_selectedIds.toList());
        setState(() {
          _selectedIds.clear();
          _selectionMode = false;
        });
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa $deleted người dùng thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;
    final withImageCount = _users.where((u) => u.hinhanh.isNotEmpty).length;
    final withoutImageCount = _users.length - withImageCount;
    final imagePercent =
        _users.isEmpty ? 0.0 : withImageCount / _users.length;
    final paged = _pagedUsers;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản Lý Người Dùng'),
            if (AuthService.currentUserEmail != null)
              Text(
                'Admin: ${AuthService.currentUserEmail}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_selectionMode
                ? Icons.check_box
                : Icons.check_box_outlined),
            tooltip: _selectionMode ? 'Thoát chọn nhiều' : 'Chọn nhiều để xóa',
            onPressed: () {
              setState(() {
                _selectionMode = !_selectionMode;
                if (!_selectionMode) _selectedIds.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(
              ThemeController.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: 'Đổi giao diện Sáng / Tối',
            onPressed: () => ThemeController.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Xem / Xuất JSON CSDL',
            onPressed: _exportJsonDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh lọc nhanh + tỷ lệ có ảnh
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildFilterChip(
                      label: 'Tất cả (${_users.length})',
                      icon: Icons.people,
                      option: ImageFilterOption.all,
                      color: Colors.blue,
                    ),
                    _buildFilterChip(
                      label: 'Có ảnh ($withImageCount)',
                      icon: Icons.image,
                      option: ImageFilterOption.withImage,
                      color: Colors.green,
                    ),
                    _buildFilterChip(
                      label: 'Chưa có ảnh ($withoutImageCount)',
                      icon: Icons.hide_image_outlined,
                      option: ImageFilterOption.withoutImage,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: imagePercent,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(imagePercent * 100).round()}% có ảnh',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Thanh tìm kiếm và sắp xếp
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên hoặc email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _applyFilterAndSort();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<UserSortOption>(
                  tooltip: 'Sắp xếp',
                  icon: const Icon(Icons.sort, color: Colors.blue),
                  onSelected: (option) {
                    setState(() {
                      _sortOption = option;
                      _applyFilterAndSort();
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: UserSortOption.newest,
                      child: Text('Mới nhất'),
                    ),
                    PopupMenuItem(
                      value: UserSortOption.nameAsc,
                      child: Text('Tên (A → Z)'),
                    ),
                    PopupMenuItem(
                      value: UserSortOption.nameDesc,
                      child: Text('Tên (Z → A)'),
                    ),
                    PopupMenuItem(
                      value: UserSortOption.emailAsc,
                      child: Text('Email (A → Z)'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Thanh thao tác khi bật chế độ chọn nhiều
          if (_selectionMode)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: paged.isNotEmpty &&
                        paged.every((u) => _selectedIds.contains(u.id)),
                    onChanged: (checked) {
                      setState(() {
                        for (final u in paged) {
                          if (u.id == null) continue;
                          if (checked == true) {
                            _selectedIds.add(u.id!);
                          } else {
                            _selectedIds.remove(u.id!);
                          }
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Đã chọn ${_selectedIds.length} người dùng',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed:
                        _selectedIds.isEmpty ? null : _deleteSelectedUsers,
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Xóa đã chọn'),
                  ),
                ],
              ),
            ),

          // Danh sách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Không tìm thấy người dùng nào',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: isWide
                            ? _buildDataTable(paged)
                            : _buildListView(paged),
                      ),
          ),

          // Thanh phân trang
          if (!_isLoading && _filteredUsers.isNotEmpty)
            _buildPaginationBar(isWide),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
          if (result == true) _loadUsers();
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm người dùng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required ImageFilterOption option,
    required Color color,
  }) {
    final selected = _imageFilter == option;
    return FilterChip(
      selected: selected,
      label: Text(label),
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
      selectedColor: color,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _imageFilter = option;
          _applyFilterAndSort();
        });
      },
    );
  }

  Widget _buildPaginationBar(bool isWide) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 4, isWide ? 225 : 16, isWide ? 12 : 84),
      child: Row(
        children: [
          DropdownButton<int>(
            value: _pageSize,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: 6, child: Text('6 / trang')),
              DropdownMenuItem(value: 10, child: Text('10 / trang')),
              DropdownMenuItem(value: 20, child: Text('20 / trang')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _pageSize = value;
                  _currentPage = 1;
                });
              }
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => setState(() => _currentPage--)
                : null,
          ),
          Text(
            'Trang $_currentPage / $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<UserModel> users) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            Colors.blue.withValues(alpha: 0.12),
          ),
          columns: [
            if (_selectionMode)
              const DataColumn(
                label: Text('Chọn',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            const DataColumn(
                label: Text('Hình ảnh',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Họ tên',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Email',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Mật khẩu',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(
                label: Text('Thao tác',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) {
            final uid = user.id ?? '';
            final showPwd = _visiblePasswordIds.contains(uid);
            return DataRow(
              selected: _selectionMode && _selectedIds.contains(uid),
              cells: [
                if (_selectionMode)
                  DataCell(
                    Checkbox(
                      value: _selectedIds.contains(uid),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selectedIds.add(uid);
                          } else {
                            _selectedIds.remove(uid);
                          }
                        });
                      },
                    ),
                  ),
                DataCell(
                  UserAvatar(
                    imagePath: user.hinhanh,
                    radius: 22,
                    enableZoomPreview: user.hinhanh.isNotEmpty,
                    heroTitle: user.hoten,
                    onTap: user.hinhanh.isEmpty
                        ? () => _navigateToDetail(user)
                        : null,
                  ),
                ),
                DataCell(Text(user.hoten)),
                DataCell(Text(user.email)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(showPwd ? user.matkhau : '••••••••'),
                      IconButton(
                        icon: Icon(
                          showPwd ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        tooltip: showPwd ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                        onPressed: () {
                          setState(() {
                            if (showPwd) {
                              _visiblePasswordIds.remove(uid);
                            } else {
                              _visiblePasswordIds.add(uid);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        tooltip: 'Xem chi tiết',
                        onPressed: () => _navigateToDetail(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: 'Sửa',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditUserScreen(user: user),
                            ),
                          );
                          if (result == true) _loadUsers();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Xóa',
                        onPressed: () => _deleteUser(user),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView(List<UserModel> users) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final uid = user.id ?? '';
        final isSelected = _selectedIds.contains(uid);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: _selectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedIds.add(uid);
                        } else {
                          _selectedIds.remove(uid);
                        }
                      });
                    },
                  )
                : UserAvatar(
                    imagePath: user.hinhanh,
                    radius: 26,
                    enableZoomPreview: user.hinhanh.isNotEmpty,
                    heroTitle: user.hoten,
                  ),
            title: Text(
              user.hoten,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user.email),
            trailing: _selectionMode
                ? UserAvatar(imagePath: user.hinhanh, radius: 20)
                : PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'view':
                          _navigateToDetail(user);
                          break;
                        case 'edit':
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditUserScreen(user: user),
                            ),
                          );
                          if (result == true) _loadUsers();
                          break;
                        case 'delete':
                          _deleteUser(user);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility, color: Colors.blue),
                          title: Text('Xem chi tiết'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.orange),
                          title: Text('Sửa'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Xóa'),
                        ),
                      ),
                    ],
                  ),
            onTap: _selectionMode
                ? () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(uid);
                      } else {
                        _selectedIds.add(uid);
                      }
                    });
                  }
                : () => _navigateToDetail(user),
          ),
        );
      },
    );
  }

  Future<void> _navigateToDetail(UserModel user) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    );
    if (changed == true) _loadUsers();
  }
}
