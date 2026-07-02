import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/console_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/snack_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/member_snack_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import '../transaction/receipt_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final ConsoleModel console;
  final TransactionModel transaction;

  const ActiveSessionScreen({
    super.key,
    required this.console,
    required this.transaction,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _elapsed;
  late TabController _tabCtrl;

  String _paymentMethod = AppConstants.paymentCash;
  int _discount = 0;
  int _pointsRedeem = 0;
  bool _isCheckingOut = false;

  final _discountCtrl = TextEditingController();
  final _cashCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.transaction.startTime);
    _tabCtrl = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(widget.transaction.startTime);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().clearCart();
      context.read<SnackProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _tabCtrl.dispose();
    _discountCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  int get _rentalCost {
    final minutes = _elapsed.inMinutes;
    final billable = (minutes / 30).ceil() * 30;
    return (billable / 60 * widget.console.pricePerHour).ceil();
  }

  int get _cartTotal => context.read<TransactionProvider>().cartTotal;

  int get _subtotal => _rentalCost + _cartTotal - _discount;

  int get _totalCost => _subtotal - (_pointsRedeem * 10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.console.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
            onPressed: _confirmCancel,
            tooltip: 'Batalkan Sesi',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(
                text: 'Sesi & Kasir',
                icon: Icon(Icons.timer_outlined, size: 18)),
            Tab(
                text: 'Checkout',
                icon: Icon(Icons.payments_outlined, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildSessionTab(),
          _buildCheckoutTab(),
        ],
      ),
    );
  }

  // ── Session Tab ───────────────────────────────────────────────────────────
  Widget _buildSessionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimerCard(),
          const SizedBox(height: 16),
          _buildCartSection(),
          const SizedBox(height: 16),
          _buildSnackGrid(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    return GZCard(
      borderColor: AppColors.statusPlaying.withOpacity(0.5),
      shadows: [
        BoxShadow(
          color: AppColors.statusPlaying.withOpacity(0.2),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DURASI BERMAIN',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.5,
                              color: AppColors.textMuted,
                            )),
                    const SizedBox(height: 8),
                    GZTimerDisplay(elapsed: _elapsed, color: AppColors.accent),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusPlaying.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.attach_money,
                        color: AppColors.statusPlaying),
                    Text(
                      CurrencyFormatter.toRupiah(_rentalCost),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const GZDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip('Mulai',
                  CurrencyFormatter.toTime(widget.transaction.startTime)),
              _infoChip('Tipe', widget.transaction.rentalType),
              if (widget.transaction.memberName != null)
                _infoChip('Member', widget.transaction.memberName!),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GZButton(
              label: 'Lanjut ke Checkout',
              icon: Icons.payments_outlined,
              onPressed: () => _tabCtrl.animateTo(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            )),
      ],
    );
  }

  Widget _buildCartSection() {
    return Consumer<TransactionProvider>(
      builder: (_, txp, __) {
        final cart = txp.cart;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GZSectionHeader(
              title: 'Pesanan Snack (${cart.length})',
              action: cart.isNotEmpty ? 'Hapus Semua' : null,
              onAction: txp.clearCart,
            ),
            if (cart.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Belum ada pesanan',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              ...cart.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GZCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(CurrencyFormatter.toRupiah(item.unitPrice),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          _qtyControl(item, txp),
                          const SizedBox(width: 12),
                          Text(
                            CurrencyFormatter.toRupiah(item.subtotal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              GZCard(
                borderColor: AppColors.accent.withOpacity(0.4),
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Snack',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      CurrencyFormatter.toRupiah(txp.cartTotal),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _qtyControl(CartItem item, TransactionProvider txp) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _qtyBtn(Icons.remove, () {
          txp.updateCartQuantity(item.itemId, item.itemType, item.quantity - 1);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('${item.quantity}',
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        _qtyBtn(Icons.add, () {
          txp.updateCartQuantity(item.itemId, item.itemType, item.quantity + 1);
        }),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildSnackGrid() {
    return Consumer<SnackProvider>(
      builder: (_, sp, __) {
        if (sp.isLoading) return const CircularProgressIndicator();
        final snacks = sp.snacks.where((s) => !s.isOutOfStock).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GZSectionHeader(title: 'Menu Snack & Minuman'),
            const SizedBox(height: 8),
            // Category filter
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: sp.categories.map((cat) {
                  final sel = sp.selectedCat == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => sp.filterByCategory(cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.surface,
                          border: Border.all(
                            color:
                                sel ? AppColors.primary : AppColors.cardBorder,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusFull),
                        ),
                        child: Center(
                          child: Text(cat,
                              style: TextStyle(
                                fontSize: 11,
                                color: sel
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400,
                              )),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: snacks.length,
              itemBuilder: (_, i) => _snackItem(snacks[i]),
            ),
          ],
        );
      },
    );
  }

  Widget _snackItem(SnackModel snack) {
    return GestureDetector(
      onTap: () => context.read<TransactionProvider>().addToCart(snack),
      child: GZCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood,
                  color: AppColors.warning, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              snack.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.toRupiah(snack.price),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
            Text(
              'Stok: ${snack.stock}',
              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── Checkout Tab ──────────────────────────────────────────────────────────
  Widget _buildCheckoutTab() {
    return Consumer<TransactionProvider>(
      builder: (_, txp, __) {
        final cart = txp.cart;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBillSummary(txp),
              const SizedBox(height: 16),
              _buildPaymentMethod(),
              const SizedBox(height: 16),
              if (_paymentMethod == AppConstants.paymentCash) _buildCashInput(),
              const SizedBox(height: 24),
              GZButton(
                label: 'Selesaikan & Bayar',
                icon: Icons.check_circle_outline,
                width: double.infinity,
                height: 52,
                isLoading: _isCheckingOut,
                onPressed: () => _checkout(txp),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillSummary(TransactionProvider txp) {
    final cash = int.tryParse(_cashCtrl.text.replaceAll('.', '')) ?? 0;
    final change = cash - _totalCost;

    return GZCard(
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Tagihan',
              style: Theme.of(context).textTheme.headlineSmall),
          const GZDivider(),
          _billRow('Biaya Rental', CurrencyFormatter.toRupiah(_rentalCost)),
          const SizedBox(height: 6),
          _billRow(
              'Snack & Minuman', CurrencyFormatter.toRupiah(txp.cartTotal)),
          if (_discount > 0) ...[
            const SizedBox(height: 6),
            _billRow('Diskon', '- ${CurrencyFormatter.toRupiah(_discount)}',
                color: AppColors.success),
          ],
          const GZDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: Theme.of(context).textTheme.titleLarge),
              GZNeonText(
                text: CurrencyFormatter.toRupiah(_totalCost),
                fontSize: 20,
              ),
            ],
          ),
          if (_paymentMethod == AppConstants.paymentCash && change > 0) ...[
            const GZDivider(),
            _billRow('Bayar', CurrencyFormatter.toRupiah(cash)),
            const SizedBox(height: 6),
            _billRow('Kembalian', CurrencyFormatter.toRupiah(change),
                color: AppColors.accent),
          ],
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            )),
      ],
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Metode Pembayaran',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: AppConstants.paymentMethods.map((method) {
            final sel = _paymentMethod == method;
            IconData icon;
            switch (method) {
              case AppConstants.paymentQris:
                icon = Icons.qr_code;
                break;
              case AppConstants.paymentTransfer:
                icon = Icons.account_balance;
                break;
              case AppConstants.paymentDebit:
                icon = Icons.credit_card;
                break;
              default:
                icon = Icons.payments;
            }
            return GestureDetector(
              onTap: () => setState(() => _paymentMethod = method),
              child: AnimatedContainer(
                duration: AppConstants.animFast,
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.primary.withOpacity(0.15)
                      : AppColors.surface,
                  border: Border.all(
                    color: sel ? AppColors.primary : AppColors.cardBorder,
                    width: sel ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon,
                        color: sel ? AppColors.primary : AppColors.textMuted,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(method,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          color:
                              sel ? AppColors.primary : AppColors.textSecondary,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCashInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jumlah Bayar', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        GZTextField(
          label: 'Nominal Tunai',
          hint: 'Masukkan jumlah uang',
          controller: _cashCtrl,
          prefixIcon: Icons.payments_outlined,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [10000, 20000, 50000, 100000].map((v) {
            return GestureDetector(
              onTap: () {
                _cashCtrl.text = CurrencyFormatter.toNumber(v);
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(CurrencyFormatter.toRupiah(v),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _checkout(TransactionProvider txp) async {
    final cashAmount = _paymentMethod == AppConstants.paymentCash
        ? (int.tryParse(
                _cashCtrl.text.replaceAll('.', '').replaceAll(',', '')) ??
            0)
        : _totalCost;

    if (_paymentMethod == AppConstants.paymentCash && cashAmount < _totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jumlah bayar kurang'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isCheckingOut = true);
    try {
      final success = await txp.completeRental(
        tx: widget.transaction,
        pricePerHour: widget.console.pricePerHour,
        paymentMethod: _paymentMethod,
        paymentAmount: cashAmount,
        discount: _discount,
      );

      if (success && mounted) {
        final tx = await txp.getById(widget.transaction.id!);
        if (tx != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ReceiptScreen(transaction: tx)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Sesi?'),
        content:
            const Text('Sesi akan dibatalkan dan konsol kembali tersedia.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tidak')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<TransactionProvider>().cancelRental(
                    widget.transaction.id!,
                    widget.console.id!,
                  );
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Ya, Batalkan',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
