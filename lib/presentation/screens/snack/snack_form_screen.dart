import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/snack_model.dart';
import '../../providers/member_snack_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class SnackFormScreen extends StatefulWidget {
  final SnackModel? snack;
  const SnackFormScreen({super.key, this.snack});

  @override
  State<SnackFormScreen> createState() => _SnackFormScreenState();
}

class _SnackFormScreenState extends State<SnackFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _codeCtrl = TextEditingController(text: widget.snack?.code ?? '');
  late final _nameCtrl = TextEditingController(text: widget.snack?.name ?? '');
  late final _priceCtrl =
      TextEditingController(text: widget.snack?.price.toString() ?? '');
  late final _stockCtrl =
      TextEditingController(text: widget.snack?.stock.toString() ?? '0');
  late final _unitCtrl =
      TextEditingController(text: widget.snack?.unit ?? 'pcs');

  late String _selectedCategory = widget.snack?.category ?? 'snack';
  bool _isLoading = false;

  bool get isEdit => widget.snack != null;

  static const _categories = [
    'snack',
    'minuman',
    'makanan',
    'rokok',
    'lainnya',
  ];

  @override
  void initState() {
    super.initState();
    if (!isEdit) _generateCode();
  }

  Future<void> _generateCode() async {
    final code = await context.read<SnackProvider>().generateCode();
    if (mounted) setState(() => _codeCtrl.text = code);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk Baru'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: _deleteSnack,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.4)),
                    boxShadow: const [
                      BoxShadow(color: AppColors.glowPurple, blurRadius: 16)
                    ],
                  ),
                  child: const Icon(
                    Icons.fastfood_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Kode
              GZTextField(
                label: 'Kode Produk',
                controller: _codeCtrl,
                prefixIcon: Icons.qr_code_outlined,
                readOnly: true,
              ),
              const SizedBox(height: 12),

              // Nama
              GZTextField(
                label: 'Nama Produk*',
                controller: _nameCtrl,
                prefixIcon: Icons.label_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Kategori
              _buildCategoryDropdown(),
              const SizedBox(height: 12),

              // Harga & Stok
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GZTextField(
                      label: 'Harga (Rp)*',
                      controller: _priceCtrl,
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(v) == null) return 'Angka tidak valid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GZTextField(
                      label: 'Stok',
                      controller: _stockCtrl,
                      prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (int.tryParse(v) == null) return 'Angka tidak valid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Satuan
              _buildUnitSelector(),

              // Info stok jika edit
              if (isEdit) ...[
                const SizedBox(height: 20),
                _buildStockAdjustCard(),
              ],

              const SizedBox(height: 32),
              GZButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
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

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      dropdownColor: AppColors.surface,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: 'Kategori',
        prefixIcon: const Icon(Icons.category_outlined),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _categories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(
            cat[0].toUpperCase() + cat.substring(1),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedCategory = v ?? 'snack'),
    );
  }

  Widget _buildUnitSelector() {
    const units = ['pcs', 'botol', 'kaleng', 'pak', 'bungkus', 'cup', 'liter'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Satuan',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: units.map((u) {
            final isSelected = _unitCtrl.text == u;
            return GestureDetector(
              onTap: () => setState(() => _unitCtrl.text = u),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.cardBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  u,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStockAdjustCard() {
    return GZCard(
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text('Penyesuaian Stok Cepat',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const GZDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _quickStockBtn(-10, AppColors.danger),
              const SizedBox(width: 8),
              _quickStockBtn(-1, AppColors.dangerLight),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  _stockCtrl.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _quickStockBtn(1, AppColors.successLight),
              const SizedBox(width: 8),
              _quickStockBtn(10, AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickStockBtn(int delta, Color color) {
    return GestureDetector(
      onTap: () {
        final current = int.tryParse(_stockCtrl.text) ?? 0;
        final newVal = (current + delta).clamp(0, 9999);
        setState(() => _stockCtrl.text = newVal.toString());
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(
          child: Text(
            delta > 0 ? '+$delta' : '$delta',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
      final snack = SnackModel(
        id: widget.snack?.id,
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        price: int.tryParse(_priceCtrl.text.trim()) ?? 0,
        stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
        createdAt: widget.snack?.createdAt ?? now,
        updatedAt: now,
      );

      final sp = context.read<SnackProvider>();
      final ok =
          isEdit ? await sp.updateSnack(snack) : await sp.addSnack(snack);

      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEdit
                  ? 'Produk berhasil diperbarui'
                  : 'Produk berhasil ditambahkan'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan produk'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deleteSnack() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Produk "${widget.snack!.name}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<SnackProvider>()
                  .deleteSnack(widget.snack!.id!);
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
