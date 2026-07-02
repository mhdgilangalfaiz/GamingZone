import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/transaction_model.dart';
import '../../widgets/common/gz_widgets.dart';
import '../main_navigation.dart';

class ReceiptScreen extends StatelessWidget {
  final TransactionModel transaction;
  const ReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Struk Pembayaran'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => _goHome(context),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Beranda'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSuccessBanner(context),
            const SizedBox(height: 20),
            _buildReceipt(context),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GZButton(
                    label: 'Cetak Struk',
                    icon: Icons.print_outlined,
                    isOutlined: true,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GZButton(
                    label: 'Selesai',
                    icon: Icons.check_circle_outline,
                    onPressed: () => _goHome(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBanner(BuildContext context) {
    return GZCard(
      borderColor: AppColors.success.withOpacity(0.4),
      shadows: const [BoxShadow(color: AppColors.glowSuccess, blurRadius: 20)],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 12),
          Text('Pembayaran Berhasil!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.success,
                  )),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.toRupiah(transaction.totalCost),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceipt(BuildContext context) {
    return GZCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Text('GAMING ZONE',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.primary,
                        )),
                Text('Struk Pembayaran',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  CurrencyFormatter.toReceiptDate(transaction.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const GZDivider(),

          // Invoice
          _receiptRow(context, 'No. Invoice', transaction.invoiceNo),
          _receiptRow(context, 'Konsol', transaction.consoleName ?? '-'),
          _receiptRow(context, 'Tipe', transaction.rentalType),
          if (transaction.memberName != null)
            _receiptRow(context, 'Member', transaction.memberName!),
          _receiptRow(context, 'Mulai',
              CurrencyFormatter.toTime(transaction.startTime)),
          if (transaction.endTime != null)
            _receiptRow(context, 'Selesai',
                CurrencyFormatter.toTime(transaction.endTime!)),
          if (transaction.durationMinutes != null)
            _receiptRow(
                context,
                'Durasi',
                CurrencyFormatter.minutesToString(
                    transaction.durationMinutes!)),
          const GZDivider(),

          // Items
          if (transaction.items.isNotEmpty) ...[
            Text('Item Pesanan',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...transaction.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('${item.itemName} x${item.quantity}',
                              style: Theme.of(context).textTheme.bodyMedium)),
                      Text(CurrencyFormatter.toRupiah(item.subtotal),
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )),
            const GZDivider(),
          ],

          // Cost breakdown
          _receiptRow(context, 'Biaya Rental',
              CurrencyFormatter.toRupiah(transaction.rentalCost)),
          if (transaction.snackCost > 0)
            _receiptRow(context, 'Snack & Minuman',
                CurrencyFormatter.toRupiah(transaction.snackCost)),
          if (transaction.discount > 0)
            _receiptRow(context, 'Diskon',
                '- ${CurrencyFormatter.toRupiah(transaction.discount)}',
                valueColor: AppColors.success),
          if (transaction.tax > 0)
            _receiptRow(
                context, 'Pajak', CurrencyFormatter.toRupiah(transaction.tax)),
          const GZDivider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL', style: Theme.of(context).textTheme.titleLarge),
              GZNeonText(
                text: CurrencyFormatter.toRupiah(transaction.totalCost),
                fontSize: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _receiptRow(context, 'Metode Bayar', transaction.paymentMethod),
          if (transaction.paymentAmount > 0)
            _receiptRow(context, 'Dibayar',
                CurrencyFormatter.toRupiah(transaction.paymentAmount)),
          if (transaction.changeAmount > 0)
            _receiptRow(context, 'Kembalian',
                CurrencyFormatter.toRupiah(transaction.changeAmount),
                valueColor: AppColors.accent),

          if (transaction.pointsEarned > 0) ...[
            const GZDivider(),
            _receiptRow(
                context, 'Poin Didapat', '+${transaction.pointsEarned} poin',
                valueColor: AppColors.warning),
          ],

          const GZDivider(),
          Center(
            child: Text(
              'Terima kasih telah bermain di Gaming Zone!\nSampai jumpa lagi 🎮',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Kasir: ${transaction.cashierName}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
  }
}
