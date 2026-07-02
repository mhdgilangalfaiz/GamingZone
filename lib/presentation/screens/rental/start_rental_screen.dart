import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/console_model.dart';
import '../../../data/models/member_model.dart';
import '../../providers/console_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/member_snack_provider.dart';
import '../../widgets/common/gz_widgets.dart';

class StartRentalScreen extends StatefulWidget {
  final ConsoleModel console;
  const StartRentalScreen({super.key, required this.console});

  @override
  State<StartRentalScreen> createState() => _StartRentalScreenState();
}

class _StartRentalScreenState extends State<StartRentalScreen> {
  late String _rentalType = widget.console.isVipOnly
      ? AppConstants.rentalTypeVIP
      : AppConstants.rentalTypeRegular;
  MemberModel? _selectedMember;
  bool _isLoading = false;

  final _memberSearchCtrl = TextEditingController();

  @override
  void dispose() {
    _memberSearchCtrl.dispose();
    super.dispose();
  }

  int get _pricePerHour {
    if (_rentalType == AppConstants.rentalTypeVIP) {
      return widget.console.priceVip;
    }
    return widget.console.pricePerHour;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mulai Sesi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConsoleInfo(),
            const SizedBox(height: 20),
            _buildRentalTypeSection(),
            const SizedBox(height: 20),
            _buildMemberSection(),
            const SizedBox(height: 20),
            _buildPriceSummary(),
            const SizedBox(height: 32),
            _buildStartButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Console Info ──────────────────────────────────────────────────────────
  Widget _buildConsoleInfo() {
    return GZCard(
      borderColor: AppColors.statusAvailable.withOpacity(0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.statusAvailable.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.sports_esports,
                color: AppColors.statusAvailable, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.console.name,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(widget.console.type,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(widget.console.code,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    )),
              ],
            ),
          ),
          const GZBadge(label: 'Tersedia', color: AppColors.statusAvailable),
        ],
      ),
    );
  }

  // ── Rental Type ───────────────────────────────────────────────────────────
  Widget _buildRentalTypeSection() {
    final types = widget.console.isVipOnly
        ? [AppConstants.rentalTypeVIP]
        : [AppConstants.rentalTypeRegular, AppConstants.rentalTypeVIP];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (widget.console.isVipOnly)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Konsol ini hanya tersedia di Room VIP (ber-AC)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.warning),
            ),
          ),
        Row(
          children: types.map((type) {
            final selected = _rentalType == type;
            final isVip = type == AppConstants.rentalTypeVIP;
            final color = isVip ? AppColors.warning : AppColors.primary;
            final price = isVip
                ? widget.console.priceVip
                : widget.console.pricePerHour;
            final desc = isVip ? 'Room AC (Indoor)' : 'Outdoor';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _rentalType = type);
                  },
                  child: AnimatedContainer(
                    duration: AppConstants.animFast,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.15)
                          : AppColors.surface,
                      border: Border.all(
                        color: selected ? color : AppColors.cardBorder,
                        width: selected ? 1.5 : 1,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.2), blurRadius: 8),
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isVip ? Icons.ac_unit : Icons.wb_sunny_outlined,
                          color: selected ? color : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isVip ? 'VIP' : 'Reguler',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                            color: selected ? color : AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: 9,
                            color: selected
                                ? color.withOpacity(0.8)
                                : AppColors.textMuted,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.toRupiah(price),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected ? color : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Member Section ────────────────────────────────────────────────────────
  Widget _buildMemberSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Member', style: Theme.of(context).textTheme.headlineSmall),
            if (_selectedMember != null)
              TextButton.icon(
                onPressed: () => setState(() => _selectedMember = null),
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Hapus'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedMember != null)
          GZCard(
            borderColor: AppColors.accent.withOpacity(0.4),
            child: Row(
              children: [
                _memberAvatar(_selectedMember!),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_selectedMember!.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(_selectedMember!.memberCode,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.stars,
                              color: AppColors.warning, size: 14),
                          const SizedBox(width: 4),
                          Text('${_selectedMember!.points} Poin',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                GZBadge(label: _selectedMember!.tier, color: AppColors.accent),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _searchMember,
            child: GZCard(
              borderColor: AppColors.cardBorder,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_search_outlined,
                        color: AppColors.textMuted, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cari Member (Opsional)',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('Ketuk untuk mencari member',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _memberAvatar(MemberModel m) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(m.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ),
    );
  }

  // ── Price Summary ─────────────────────────────────────────────────────────
  Widget _buildPriceSummary() {
    return GZCard(
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimasi Harga',
              style: Theme.of(context).textTheme.headlineSmall),
          const GZDivider(),
          _priceRow('Kategori', _rentalType),
          const SizedBox(height: 8),
          _priceRow(
            'Harga / Jam',
            CurrencyFormatter.toRupiah(_pricePerHour),
            valueColor: AppColors.accent,
          ),
          const GZDivider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mulai Sesi', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                CurrencyFormatter.toTime(DateTime.now()),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            )),
      ],
    );
  }

  // ── Start Button ──────────────────────────────────────────────────────────
  Widget _buildStartButton() {
    return GZButton(
      label: 'Mulai Sesi Sekarang',
      icon: Icons.play_arrow_rounded,
      width: double.infinity,
      height: 52,
      isLoading: _isLoading,
      onPressed: _startRental,
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void _searchMember() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberSearchSheet(
        onSelect: (m) {
          Navigator.pop(context);
          setState(() {
            _selectedMember = m;
          });
        },
      ),
    );
  }

  Future<void> _startRental() async {
    setState(() => _isLoading = true);
    try {
      final txp = context.read<TransactionProvider>();
      final invoiceNo = await txp.startRental(
        consoleId: widget.console.id!,
        consoleName: widget.console.name,
        rentalType: _rentalType,
        pricePerHour: _pricePerHour,
        memberId: _selectedMember?.id,
        memberName: _selectedMember?.name,
      );

      if (mounted) {
        if (invoiceNo != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesi dimulai! Invoice: $invoiceNo'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memulai sesi'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Member Search Sheet ────────────────────────────────────────────────────
class _MemberSearchSheet extends StatefulWidget {
  final void Function(MemberModel) onSelect;
  const _MemberSearchSheet({required this.onSelect});

  @override
  State<_MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<_MemberSearchSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GZTextField(
              label: 'Cari Member',
              hint: 'Nama, kode, atau nomor HP',
              prefixIcon: Icons.search,
              controller: _ctrl,
              onChanged: (v) => context.read<MemberProvider>().search(v),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<MemberProvider>(
            builder: (_, mp, __) {
              final list = mp.members;
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Tidak ada member ditemukan',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final m = list[i];
                    return GZCard(
                      onTap: () => widget.onSelect(m),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(m.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text('${m.memberCode} • ${m.phone ?? "-"}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              GZBadge(label: m.tier, color: AppColors.warning),
                              const SizedBox(height: 4),
                              Text('${m.points} poin',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
