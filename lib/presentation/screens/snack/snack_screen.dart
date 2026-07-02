import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/snack_model.dart';
import '../../providers/member_snack_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import 'snack_form_screen.dart';

class SnackScreen extends StatefulWidget {
  const SnackScreen({super.key});

  @override
  State<SnackScreen> createState() => _SnackScreenState();
}

class _SnackScreenState extends State<SnackScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SnackProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Snack & Minuman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SnackFormScreen()),
            ).then((_) => context.read<SnackProvider>().loadAll()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryRow(),
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Consumer<SnackProvider>(
      builder: (_, sp, __) {
        final snacks = sp.snacks;
        final totalItems = snacks.length;
        final lowStock = snacks.where((s) => s.isLowStock).length;
        final outOfStock = snacks.where((s) => s.isOutOfStock).length;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: AppColors.background,
          child: Row(
            children: [
              _summaryChip('$totalItems', 'Total Item', AppColors.primary),
              const SizedBox(width: 8),
              _summaryChip('$lowStock', 'Stok Menipis', AppColors.warning),
              const SizedBox(width: 8),
              _summaryChip('$outOfStock', 'Habis', AppColors.danger),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Expanded(
      child: GZCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        borderColor: color.withOpacity(0.3),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GZTextField(
        label: 'Cari Snack',
        hint: 'Nama atau kode produk',
        controller: _searchCtrl,
        prefixIcon: Icons.search,
        onChanged: (v) => context.read<SnackProvider>().search(v),
        suffix: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  context.read<SnackProvider>().search('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<SnackProvider>(
      builder: (_, sp, __) {
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sp.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = sp.categories[i];
              final isSelected = sp.selectedCat == cat;
              return GestureDetector(
                onTap: () => sp.filterByCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.cardBorder,
                    ),
                    boxShadow: isSelected
                        ? [
                            const BoxShadow(
                              color: AppColors.glowPurple,
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildList() {
    return Consumer<SnackProvider>(
      builder: (_, sp, __) {
        if (sp.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final list = sp.snacks;
        if (list.isEmpty) {
          return GZEmpty(
            message: 'Belum ada produk snack terdaftar',
            icon: Icons.fastfood_outlined,
            action: 'Tambah Snack',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SnackFormScreen()),
            ).then((_) => sp.loadAll()),
          );
        }
        return RefreshIndicator(
          onRefresh: sp.loadAll,
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _snackCard(list[i]),
          ),
        );
      },
    );
  }

  Widget _snackCard(SnackModel s) {
    Color stockColor;
    String stockLabel;
    if (s.isOutOfStock) {
      stockColor = AppColors.danger;
      stockLabel = 'Habis';
    } else if (s.isLowStock) {
      stockColor = AppColors.warning;
      stockLabel = 'Menipis';
    } else {
      stockColor = AppColors.success;
      stockLabel = 'Tersedia';
    }

    return GZCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SnackFormScreen(snack: s)),
      ).then((_) => context.read<SnackProvider>().loadAll()),
      borderColor: s.isOutOfStock
          ? AppColors.danger.withOpacity(0.3)
          : AppColors.cardBorder,
      child: Row(
        children: [
          // Icon kategori
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.fastfood_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    GZBadge(
                      label: stockLabel,
                      color: stockColor,
                      fontSize: 9,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.code} • ${s.category}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      CurrencyFormatter.toRupiah(s.price),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: stockColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${s.stock} ${s.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Quick stock buttons
          Column(
            children: [
              _stockBtn(
                icon: Icons.add,
                color: AppColors.success,
                onTap: () => _adjustStock(s, 1),
              ),
              const SizedBox(height: 4),
              _stockBtn(
                icon: Icons.remove,
                color: AppColors.danger,
                onTap: s.stock > 0 ? () => _adjustStock(s, -1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockBtn({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color:
              onTap != null ? color.withOpacity(0.15) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                onTap != null ? color.withOpacity(0.4) : AppColors.cardBorder,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: onTap != null ? color : AppColors.textHint,
        ),
      ),
    );
  }

  Future<void> _adjustStock(SnackModel s, int delta) async {
    await context.read<SnackProvider>().updateStock(s.id!, delta);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            delta > 0
                ? 'Stok ${s.name} ditambah 1'
                : 'Stok ${s.name} dikurang 1',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: delta > 0 ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }
}
