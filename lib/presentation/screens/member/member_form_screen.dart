import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/member_model.dart';
import '../../providers/member_snack_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class MemberFormScreen extends StatefulWidget {
  final MemberModel? member;
  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _codeCtrl =
      TextEditingController(text: widget.member?.memberCode ?? '');
  late final _nameCtrl = TextEditingController(text: widget.member?.name ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.member?.phone ?? '');
  late final _emailCtrl =
      TextEditingController(text: widget.member?.email ?? '');
  bool _isLoading = false;
  bool get isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();
    if (!isEdit) _generateCode();
  }

  Future<void> _generateCode() async {
    final code = await context.read<MemberProvider>().generateCode();
    if (mounted) _codeCtrl.text = code;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Member' : 'Daftar Member Baru'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _deleteMember,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Avatar Preview
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _nameCtrl.text.isEmpty
                          ? 'M'
                          : _nameCtrl.text
                              .trim()
                              .split(' ')
                              .map((p) => p[0])
                              .take(2)
                              .join()
                              .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              GZTextField(
                label: 'Kode Member',
                controller: _codeCtrl,
                prefixIcon: Icons.badge_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Nama Lengkap*',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Nomor HP',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Email (Opsional)',
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              if (isEdit) ...[
                const SizedBox(height: 20),
                GZCard(
                  borderColor: AppColors.warning.withOpacity(0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Info Member',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const GZDivider(),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text('${widget.member!.points}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.warning,
                                    )),
                                const Text('Poin',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppColors.cardBorder),
                          Expanded(
                            child: Column(
                              children: [
                                Text(widget.member!.tier,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    )),
                                const Text('Tier',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              GZButton(
                label: isEdit ? 'Simpan Perubahan' : 'Daftarkan Member',
                icon: isEdit ? Icons.save_outlined : Icons.person_add_outlined,
                width: double.infinity,
                height: 52,
                isLoading: _isLoading,
                onPressed: _save,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final member = MemberModel(
        id: widget.member?.id,
        memberCode: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        points: widget.member?.points ?? 0,
        totalSpend: widget.member?.totalSpend ?? 0,
        createdAt: widget.member?.createdAt ?? now,
        updatedAt: now,
      );

      final mp = context.read<MemberProvider>();
      final ok =
          isEdit ? await mp.updateMember(member) : await mp.addMember(member);

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit
                  ? 'Member berhasil diperbarui'
                  : 'Member berhasil didaftarkan'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Gagal menyimpan'),
                backgroundColor: AppColors.danger),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteMember() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Member?'),
        content: Text('Member ${widget.member!.name} akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<MemberProvider>()
                  .deleteMember(widget.member!.id!);
              if (ok && mounted) Navigator.pop(context);
            },
            child:
                const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
