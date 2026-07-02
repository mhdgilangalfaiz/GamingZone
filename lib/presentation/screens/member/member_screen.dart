import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/member_model.dart';
import '../../providers/member_snack_provider.dart';
import '../../widgets/common/gz_widgets.dart';
import 'member_form_screen.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MemberProvider>().loadAll();
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
        title: const Text('Data Member'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberFormScreen()),
            ).then((_) => context.read<MemberProvider>().loadAll()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryRow(),
          _buildSearchBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Consumer<MemberProvider>(
      builder: (_, mp, __) {
        final s = mp.summary;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          color: AppColors.background,
          child: Row(
            children: [
              _summaryChip(
                '${s['total'] ?? 0}',
                'Total Member',
                AppColors.primary,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                CurrencyFormatter.toRupiahCompact(s['total_spend'] ?? 0),
                'Total Belanja',
                AppColors.success,
              ),
              const SizedBox(width: 8),
              _summaryChip(
                '${s['total_points'] ?? 0}',
                'Total Poin',
                AppColors.warning,
              ),
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
            Text(value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GZTextField(
        label: 'Cari Member',
        hint: 'Nama, kode, atau nomor HP',
        controller: _searchCtrl,
        prefixIcon: Icons.search,
        onChanged: (v) => context.read<MemberProvider>().search(v),
        suffix: _searchCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  context.read<MemberProvider>().search('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildList() {
    return Consumer<MemberProvider>(
      builder: (_, mp, __) {
        if (mp.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final list = mp.members;
        if (list.isEmpty) {
          return GZEmpty(
            message: 'Belum ada member terdaftar',
            icon: Icons.people_outline,
            action: 'Tambah Member',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemberFormScreen()),
            ).then((_) => mp.loadAll()),
          );
        }
        return RefreshIndicator(
          onRefresh: mp.loadAll,
          color: AppColors.primary,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _memberCard(list[i]),
          ),
        );
      },
    );
  }

  Widget _memberCard(MemberModel m) {
    Color tierColor;
    switch (m.tier) {
      case 'Diamond':
        tierColor = Colors.cyanAccent;
        break;
      case 'Gold':
        tierColor = AppColors.warning;
        break;
      case 'Silver':
        tierColor = AppColors.textSecondary;
        break;
      default:
        tierColor = const Color(0xFFCD7F32);
    }

    return GZCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MemberFormScreen(member: m)),
      ).then((_) => context.read<MemberProvider>().loadAll()),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: AppColors.glowPurple, blurRadius: 8)
              ],
            ),
            child: Center(
              child: Text(m.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  )),
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
                      child: Text(m.name,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    GZBadge(label: m.tier, color: tierColor, fontSize: 9),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${m.memberCode} • ${m.phone ?? "No HP"}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.stars, color: AppColors.warning, size: 12),
                    const SizedBox(width: 4),
                    Text('${m.points} poin',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 12),
                    const Icon(Icons.payments_outlined,
                        color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.toRupiahCompact(m.totalSpend),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
