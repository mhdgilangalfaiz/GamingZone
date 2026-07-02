import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_hasher.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../widgets/common/gz_widgets.dart';

/// Layar khusus Admin untuk membuat & mengelola akun login (role Admin/User).
/// Password baru langsung di-hash lewat [UserRepository] / [PasswordHasher],
/// tidak pernah disimpan sebagai teks biasa.
class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final UserRepository _repo = UserRepository();
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final users = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  void _openAccountForm({UserModel? existing}) {
    final usernameCtrl = TextEditingController(text: existing?.username);
    final fullNameCtrl = TextEditingController(text: existing?.fullName);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final passwordCtrl = TextEditingController();
    String role = existing?.role ?? AppConstants.roleUser;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing == null ? 'Tambah Akun' : 'Edit Akun',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GZTextField(
                    label: 'Username',
                    controller: usernameCtrl,
                    prefixIcon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  GZTextField(
                    label: 'Nama Lengkap',
                    controller: fullNameCtrl,
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  GZTextField(
                    label: 'No. HP (opsional)',
                    controller: phoneCtrl,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  GZTextField(
                    label: existing == null
                        ? 'Password'
                        : 'Password Baru (kosongkan jika tidak diubah)',
                    controller: passwordCtrl,
                    prefixIcon: Icons.lock_outline,
                    obscure: true,
                    validator: (v) {
                      if (existing == null &&
                          (v == null || v.length < 6)) {
                        return 'Min. 6 karakter';
                      }
                      if (existing != null &&
                          v != null &&
                          v.isNotEmpty &&
                          v.length < 6) {
                        return 'Min. 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: role,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                          value: AppConstants.roleAdmin, child: Text('Admin')),
                      DropdownMenuItem(
                          value: AppConstants.roleUser, child: Text('User')),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => role = v ?? AppConstants.roleUser),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      final username = usernameCtrl.text.trim().toLowerCase();
                      final exists = await _repo.usernameExists(
                        username,
                        excludeId: existing?.id,
                      );
                      if (exists) {
                        if (dialogCtx.mounted) {
                          ScaffoldMessenger.of(dialogCtx).showSnackBar(
                            const SnackBar(
                              content: Text('Username sudah dipakai'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      final now = DateTime.now();

                      if (existing == null) {
                        await _repo.insert(UserModel(
                          username: username,
                          passwordHash: PasswordHasher.hash(passwordCtrl.text),
                          role: role,
                          fullName: fullNameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          createdAt: now,
                          updatedAt: now,
                        ));
                      } else {
                        await _repo.update(existing.copyWith(
                          username: username,
                          role: role,
                          fullName: fullNameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim().isEmpty
                              ? null
                              : phoneCtrl.text.trim(),
                          updatedAt: now,
                        ));
                        if (passwordCtrl.text.isNotEmpty) {
                          await _repo.updatePassword(
                              existing.id!, passwordCtrl.text);
                        }
                      }

                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      await _load();
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan',
                      style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(UserModel user) async {
    await _repo.toggleActive(user.id!, !user.isActive);
    await _load();
  }

  Future<void> _confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Yakin ingin menghapus akun "${user.username}"? Tindakan ini tidak bisa dibatalkan.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.delete(user.id!);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Akun'),
        backgroundColor: AppColors.background,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openAccountForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _users.isEmpty
              ? const GZEmpty(
                  icon: Icons.people_outline,
                  message: 'Belum ada akun.\nTambah akun Kasir/User lewat tombol +',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.paddingLG),
                  itemCount: _users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppConstants.paddingSM),
                  itemBuilder: (_, i) {
                    final user = _users[i];
                    return GZCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@${user.username}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          GZBadge(
                            label: user.roleLabel,
                            color: user.isAdmin
                                ? AppColors.primary
                                : AppColors.accent,
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            color: AppColors.surface,
                            icon: const Icon(Icons.more_vert,
                                color: AppColors.textMuted),
                            onSelected: (v) {
                              if (v == 'edit') {
                                _openAccountForm(existing: user);
                              } else if (v == 'toggle') {
                                _toggleActive(user);
                              } else if (v == 'delete') {
                                _confirmDelete(user);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                    user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus',
                                    style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
