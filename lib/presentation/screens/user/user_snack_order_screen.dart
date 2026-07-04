import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/snack_model.dart';
import '../../../data/models/snack_order_model.dart';
import '../../../data/repositories/member_snack_repository.dart';
import '../../../data/repositories/snack_order_repository.dart';
import '../../providers/auth_provider.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/common/gz_widgets.dart';

class UserSnackOrderScreen extends StatefulWidget {
  const UserSnackOrderScreen({super.key});
  @override
  State<UserSnackOrderScreen> createState() => _UserSnackOrderScreenState();
}

class _UserSnackOrderScreenState extends State<UserSnackOrderScreen> {
  List<SnackModel> _snacks = [];
  final Map<int, int> _cart = {}; // snackId → qty
  String _selectedCat = 'Semua';
  List<String> _categories = ['Semua'];
  bool _loading = true;
  bool _ordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = SnackRepository();
    _snacks = await repo.getAll();
    final cats = await repo.getCategories();
    _categories = ['Semua', ...cats];
    if (mounted) setState(() => _loading = false);
  }

  List<SnackModel> get _filtered {
    final list = _snacks.where((s) => s.isActive && !s.isOutOfStock).toList();
    if (_selectedCat == 'Semua') return list;
    return list.where((s) => s.category == _selectedCat).toList();
  }

  int get _cartTotal => _cart.entries.fold(0, (sum, e) {
        final snack = _snacks.firstWhere((s) => s.id == e.key,
            orElse: () => _snacks.first);
        return sum + snack.price * e.value;
      });

  int get _cartCount => _cart.values.fold(0, (a, b) => a + b);

  void _addItem(SnackModel s) {
    setState(() => _cart[s.id!] = (_cart[s.id!] ?? 0) + 1);
  }

  void _removeItem(SnackModel s) {
    setState(() {
      final cur = _cart[s.id!] ?? 0;
      if (cur <= 1)
        _cart.remove(s.id!);
      else
        _cart[s.id!] = cur - 1;
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;

    // Order harus punya akun juga, biar tau pesanan ini punya siapa.
    final ok = await ensureLoggedIn(context,
        message: 'Masuk atau daftar akun dulu untuk order');
    if (!ok || !mounted) return;

    setState(() => _ordering = true);
    try {
      final auth = context.read<AuthProvider>();
      final repo = SnackOrderRepository();
      final orderNo = await repo.generateOrderNo();

      final items = _cart.entries.map((e) {
        final snack = _snacks.firstWhere((s) => s.id == e.key);
        return SnackOrderItem(
          snackId: snack.id!,
          name: snack.name,
          price: snack.price,
          qty: e.value,
        );
      }).toList();

      final now = DateTime.now();
      final order = SnackOrderModel(
        orderNo: orderNo,
        userId: auth.currentUser?.id,
        memberId: auth.currentUser?.memberId,
        customerName: auth.currentUser?.fullName ?? 'User',
        items: items,
        totalCost: _cartTotal,
        createdAt: now,
        updatedAt: now,
      );

      await repo.insert(order);

      setState(() => _cart.clear());

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success, size: 56),
                const SizedBox(height: 12),
                const Text('Pesanan Terkirim!',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Pesanan #$orderNo sedang diproses kasir. Mohon tunggu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Makanan & Minuman'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        actions: [
          if (_cartCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: _showCartSheet,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _selectedCat == _categories[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCat = _categories[i]),
                  child: AnimatedContainer(
                    duration: AppConstants.animFast,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.accent : AppColors.cardBorder),
                    ),
                    child: Text(
                      _categories[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? Colors.black : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Snack grid
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? const GZEmpty(
                        message: 'Tidak ada item tersedia',
                        icon: Icons.fastfood_outlined)
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildSnackCard(_filtered[i]),
                      ),
          ),
        ],
      ),

      // Tombol Order
      bottomNavigationBar: _cartCount > 0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: GZButton(
                  label:
                      'Pesan Sekarang · ${CurrencyFormatter.toRupiah(_cartTotal)}',
                  icon: Icons.send_outlined,
                  width: double.infinity,
                  height: 52,
                  isLoading: _ordering,
                  onPressed: _ordering ? null : _placeOrder,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSnackCard(SnackModel s) {
    final qty = _cart[s.id!] ?? 0;
    return GZCard(
      padding: const EdgeInsets.all(14),
      borderColor: qty > 0 ? AppColors.accent.withOpacity(0.4) : AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              s.category == 'minuman'
                  ? Icons.local_drink_outlined
                  : s.category == 'rokok'
                      ? Icons.smoking_rooms_outlined
                      : Icons.fastfood_outlined,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(s.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Stok: ${s.stock} ${s.unit}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                CurrencyFormatter.toRupiah(s.price),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.accent),
              ),
              if (qty == 0)
                GestureDetector(
                  onTap: () => _addItem(s),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                )
              else
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _removeItem(s),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove,
                            color: AppColors.danger, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('$qty',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ),
                    GestureDetector(
                      onTap: () => _addItem(s),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.add,
                            color: AppColors.primary, size: 14),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (_, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Keranjang',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ..._cart.entries.map((e) {
                final snack =
                    _snacks.firstWhere((s) => s.id == e.key);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(snack.name,
                              style: const TextStyle(
                                  color: AppColors.textPrimary))),
                      Text('${e.value}x ',
                          style: const TextStyle(
                              color: AppColors.textMuted)),
                      Text(CurrencyFormatter.toRupiah(snack.price * e.value),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent)),
                    ],
                  ),
                );
              }),
              const GZDivider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  Text(CurrencyFormatter.toRupiah(_cartTotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 16),
              GZButton(
                label: 'Konfirmasi Pesanan',
                icon: Icons.check_circle_outline,
                width: double.infinity,
                isLoading: _ordering,
                onPressed: () async {
                  Navigator.pop(context);
                  await _placeOrder();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
