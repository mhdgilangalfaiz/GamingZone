import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/console_model.dart';
import '../../../data/repositories/console_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/common/gz_widgets.dart';

class UserBookingScreen extends StatefulWidget {
  const UserBookingScreen({super.key});
  @override
  State<UserBookingScreen> createState() => _UserBookingScreenState();
}

class _UserBookingScreenState extends State<UserBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<ConsoleModel> _consoles = [];
  bool _loading = true;
  String _selectedType = 'Semua';
  final List<String> _types = ['Semua', 'PlayStation 3', 'PlayStation 4', 'PlayStation 5', 'VR Gaming', 'Nintendo Switch'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ConsoleRepository();
    _consoles = await repo.getAll();
    if (mounted) setState(() => _loading = false);
  }

  List<ConsoleModel> get _filtered {
    if (_selectedType == 'Semua') return _consoles;
    return _consoles.where((c) => c.type == _selectedType).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'playing': return AppColors.primary;
      case 'reserved': return AppColors.warning;
      case 'maintenance': return AppColors.danger;
      default: return AppColors.success;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'playing': return 'Sedang Dipakai';
      case 'reserved': return 'Reservasi';
      case 'maintenance': return 'Maintenance';
      default: return 'Tersedia';
    }
  }

  Future<void> _onConsoleTap(ConsoleModel console) async {
    // Booking harus punya akun (biar riwayat & poin member ketauan
    // punya siapa) — kalau belum login, arahkan ke form Masuk/Daftar
    // dulu, baru lanjut ke form booking.
    final ok = await ensureLoggedIn(context,
        message: 'Masuk atau daftar akun dulu untuk booking konsol');
    if (!ok || !mounted) return;
    _showBookingDialog(console);
  }

  String _timeStr(TimeOfDay? t) => t == null
      ? '--:--'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  DateTime _toDateTime(TimeOfDay t) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, t.hour, t.minute);
  }

  int _durationMinutesOf(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return 0;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    final diff = e - s;
    return diff > 0 ? diff : diff + 1440; // lewat tengah malam
  }

  Future<TimeOfDay?> _pickTime(BuildContext ctx, TimeOfDay initial) {
    return showTimePicker(
      context: ctx,
      initialTime: initial,
      builder: (c, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
  }

  void _showBookingDialog(ConsoleModel console) {
    String selectedType = console.isVipOnly
        ? AppConstants.rentalTypeVIP
        : AppConstants.rentalTypeRegular;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final price = selectedType == AppConstants.rentalTypeVIP
              ? console.priceVip
              : console.pricePerHour;
          final durationMinutes = _durationMinutesOf(startTime, endTime);
          final total =
              durationMinutes > 0 ? (price * durationMinutes / 60).ceil() : 0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Booking ${console.name}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  const Text(
                    'Atur jam main kamu sendiri — kasir akan tahu persis kapan sesi ini mulai & selesai.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  Text('Kategori',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: (console.isVipOnly
                            ? [AppConstants.rentalTypeVIP]
                            : [
                                AppConstants.rentalTypeRegular,
                                AppConstants.rentalTypeVIP
                              ])
                        .map((type) {
                      final sel = selectedType == type;
                      final isVip = type == AppConstants.rentalTypeVIP;
                      final color =
                          isVip ? AppColors.warning : AppColors.primary;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setModal(() => selectedType = type),
                            child: AnimatedContainer(
                              duration: AppConstants.animFast,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel
                                    ? color.withOpacity(0.15)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel ? color : AppColors.cardBorder),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                      isVip
                                          ? Icons.ac_unit
                                          : Icons.wb_sunny_outlined,
                                      color:
                                          sel ? color : AppColors.textMuted,
                                      size: 18),
                                  const SizedBox(height: 4),
                                  Text(isVip ? 'VIP' : 'Reguler',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: sel
                                              ? color
                                              : AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Jam main (manual, sama seperti pengaturan waktu kasir)
                  Text('Atur Jam Main',
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _timePickerCard(
                          label: 'Jam Mulai',
                          time: startTime,
                          isStart: true,
                          onTap: () async {
                            final picked = await _pickTime(
                                ctx, startTime ?? TimeOfDay.now());
                            if (picked != null) {
                              setModal(() => startTime = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timePickerCard(
                          label: 'Jam Selesai',
                          time: endTime,
                          isStart: false,
                          onTap: () async {
                            final picked = await _pickTime(
                                ctx, endTime ?? TimeOfDay.now());
                            if (picked != null) {
                              setModal(() => endTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Ringkasan
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Kategori', selectedType),
                        const SizedBox(height: 6),
                        _summaryRow(
                            'Harga/jam', CurrencyFormatter.toRupiah(price)),
                        const SizedBox(height: 6),
                        _summaryRow(
                          'Durasi',
                          durationMinutes > 0
                              ? '${(durationMinutes / 60).toStringAsFixed(durationMinutes % 60 == 0 ? 0 : 1)} jam'
                              : '--',
                        ),
                        const GZDivider(margin: EdgeInsets.symmetric(vertical: 8)),
                        _summaryRow(
                            'Estimasi Total', CurrencyFormatter.toRupiah(total),
                            bold: true, color: AppColors.accent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  GZButton(
                    label: 'Kirim Permintaan Booking',
                    icon: Icons.calendar_today_outlined,
                    width: double.infinity,
                    onPressed: durationMinutes > 0
                        ? () async {
                            Navigator.pop(ctx);
                            await _sendBookingRequest(
                              console,
                              selectedType,
                              startTime!,
                              endTime!,
                              durationMinutes,
                              total,
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      durationMinutes > 0
                          ? '* Booking akan dikonfirmasi oleh kasir'
                          : '* Pilih jam mulai & jam selesai dulu',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _timePickerCard({
    required String label,
    required TimeOfDay? time,
    required bool isStart,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GZCard(
        borderColor: time != null
            ? AppColors.primary.withOpacity(0.4)
            : AppColors.cardBorder,
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(
              isStart ? Icons.play_circle_outline : Icons.stop_circle_outlined,
              color: time != null ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              _timeStr(time),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color:
                    time != null ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBookingRequest(
    ConsoleModel console,
    String type,
    TimeOfDay startTime,
    TimeOfDay endTime,
    int durationMinutes,
    int total,
  ) async {
    final auth = context.read<AuthProvider>();
    final repo = TransactionRepository();
    final invoiceNo = await repo.generateInvoiceNo();
    final now = DateTime.now();
    final startDt = _toDateTime(startTime);
    var endDt = _toDateTime(endTime);
    if (!endDt.isAfter(startDt)) {
      // Waktu selesai lebih kecil dari mulai → dianggap lewat tengah malam.
      endDt = endDt.add(const Duration(days: 1));
    }

    final tx = TransactionModel(
      invoiceNo: invoiceNo,
      consoleId: console.id,
      consoleName: console.name,
      memberId: auth.currentUser?.memberId,
      rentalType: type,
      startTime: startDt,
      endTime: endDt,
      durationMinutes: durationMinutes,
      rentalCost: total,
      totalCost: total,
      status: AppConstants.statusRequested,
      cashierName: auth.currentUser?.fullName ?? 'User',
      notes: 'Booking dari aplikasi user (${auth.currentUser?.fullName})',
      createdAt: now,
      updatedAt: now,
    );

    await repo.startRental(tx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Permintaan booking berhasil dikirim! Tunggu konfirmasi kasir, lalu datang & bayar sebelum jam mainmu dimulai.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Konsol'),
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter tipe konsol
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sel = _selectedType == _types[i];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = _types[i]),
                  child: AnimatedContainer(
                    duration: AppConstants.animFast,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? AppColors.primary : AppColors.cardBorder),
                    ),
                    child: Text(
                      _types[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Konsol list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: _filtered.isEmpty
                        ? const GZEmpty(
                            message: 'Tidak ada konsol tersedia',
                            icon: Icons.sports_esports_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _buildConsoleCard(_filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleCard(ConsoleModel c) {
    final available = c.isAvailable;
    final statusColor = _statusColor(c.status);

    return GZCard(
      onTap: available ? () => _onConsoleTap(c) : null,
      borderColor: available ? AppColors.success.withOpacity(0.3) : AppColors.cardBorder,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sports_esports, color: statusColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!c.isVipOnly)
                      Text('Rgl ${CurrencyFormatter.toRupiah(c.pricePerHour)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    if (!c.isVipOnly) const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                    Text('VIP ${CurrencyFormatter.toRupiah(c.priceVip)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GZBadge(label: _statusLabel(c.status), color: statusColor, fontSize: 10),
              if (available) ...[
                const SizedBox(height: 6),
                const Text('Tap untuk booking',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
