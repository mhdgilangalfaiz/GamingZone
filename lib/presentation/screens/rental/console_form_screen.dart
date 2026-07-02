import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/console_model.dart';
import '../../providers/console_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class ConsoleFormScreen extends StatefulWidget {
  final ConsoleModel? console;
  const ConsoleFormScreen({super.key, this.console});

  @override
  State<ConsoleFormScreen> createState() => _ConsoleFormScreenState();
}

class _ConsoleFormScreenState extends State<ConsoleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _codeCtrl =
      TextEditingController(text: widget.console?.code ?? '');
  late final _nameCtrl =
      TextEditingController(text: widget.console?.name ?? '');
  late final _priceCtrl = TextEditingController(
      text: widget.console?.pricePerHour.toString() ?? '');
  late final _vipCtrl =
      TextEditingController(text: widget.console?.priceVip.toString() ?? '');
  late final _descCtrl =
      TextEditingController(text: widget.console?.description ?? '');
  late String _type = widget.console?.type ?? AppConstants.consoleTypePS4;
  bool _isLoading = false;

  bool get isEdit => widget.console != null;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _vipCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'Edit Konsol' : 'Tambah Konsol')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GZTextField(
                label: 'Kode Konsol*',
                hint: 'Contoh: PS5-01',
                controller: _codeCtrl,
                prefixIcon: Icons.qr_code,
                validator: (v) => v!.isEmpty ? 'Kode wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Nama Konsol*',
                hint: 'Contoh: PlayStation 5 #1',
                controller: _nameCtrl,
                prefixIcon: Icons.sports_esports,
                validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Text('Tipe Konsol',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: AppColors.surface,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                items: AppConstants.consoleTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Harga Reguler / Jam (Rp)',
                hint: 'Isi 0 jika konsol ini khusus VIP (mis. VR/Nintendo)',
                controller: _priceCtrl,
                prefixIcon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Isi 0 jika tidak ada' : null,
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Harga VIP (Room AC) / Jam (Rp)*',
                controller: _vipCtrl,
                prefixIcon: Icons.ac_unit,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v!.isEmpty ? 'Harga VIP wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              GZTextField(
                label: 'Keterangan (Opsional)',
                controller: _descCtrl,
                prefixIcon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              GZButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Konsol',
                icon: isEdit ? Icons.save_outlined : Icons.add_circle_outline,
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
      final console = ConsoleModel(
        id: widget.console?.id,
        code: _codeCtrl.text.trim().toUpperCase(),
        name: _nameCtrl.text.trim(),
        type: _type,
        status: widget.console?.status ?? 'available',
        pricePerHour: int.tryParse(_priceCtrl.text) ?? 0,
        priceVip: int.tryParse(_vipCtrl.text) ?? 0,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        createdAt: widget.console?.createdAt ?? now,
        updatedAt: now,
      );

      final cp = context.read<ConsoleProvider>();
      final ok = isEdit
          ? await cp.updateConsole(console)
          : await cp.addConsole(console);

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit
                  ? 'Konsol berhasil diperbarui'
                  : 'Konsol berhasil ditambahkan'),
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
}
