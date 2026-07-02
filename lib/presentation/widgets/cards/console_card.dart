import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/console_model.dart';
import '../common/gz_widgets.dart';

class ConsoleCard extends StatelessWidget {
  final ConsoleModel console;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isOvertime;

  const ConsoleCard({
    super.key,
    required this.console,
    this.onTap,
    this.onLongPress,
    this.isOvertime = false,
  });

  Color get _statusColor {
    switch (console.status) {
      case AppConstants.statusAvailable:
        return AppColors.statusAvailable;
      case AppConstants.statusPlaying:
        return AppColors.statusPlaying;
      case AppConstants.statusReserved:
        return AppColors.statusReserved;
      case AppConstants.statusMaintain:
        return AppColors.statusMaintain;
      default:
        return AppColors.textMuted;
    }
  }

  String get _statusLabel {
    switch (console.status) {
      case AppConstants.statusAvailable:
        return 'Tersedia';
      case AppConstants.statusPlaying:
        return 'Bermain';
      case AppConstants.statusReserved:
        return 'Reservasi';
      case AppConstants.statusMaintain:
        return 'Maintenance';
      default:
        return console.status;
    }
  }

  IconData get _consoleIcon {
    switch (console.type) {
      case AppConstants.consoleTypePS3:
      case AppConstants.consoleTypePS4:
      case AppConstants.consoleTypePS5:
        return Icons.sports_esports;
      case AppConstants.consoleTypePC:
        return Icons.computer;
      case AppConstants.consoleTypeXbox:
        return Icons.videogame_asset;
      case AppConstants.consoleTypeVR:
        return Icons.view_in_ar;
      case AppConstants.consoleTypeNintendo:
        return Icons.videogame_asset_outlined;
      default:
        return Icons.gamepad;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = console.isPlaying;
    final c = isOvertime ? AppColors.danger : _statusColor;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: AppConstants.animNormal,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          gradient: AppColors.cardGradient,
          border: Border.all(
            color: (isPlaying || isOvertime)
                ? c.withOpacity(0.6)
                : AppColors.cardBorder,
            width: (isPlaying || isOvertime) ? (isOvertime ? 2 : 1.5) : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  c.withOpacity(isOvertime ? 0.4 : (isPlaying ? 0.25 : 0.05)),
              blurRadius: isOvertime ? 24 : (isPlaying ? 20 : 8),
              spreadRadius: isOvertime ? 3 : (isPlaying ? 2 : 0),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background glow when playing or overtime
            if (isPlaying || isOvertime)
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.withOpacity(isOvertime ? 0.15 : 0.08),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_consoleIcon, color: c, size: 20),
                      ),
                      GZBadge(
                        label: isOvertime ? 'OVERTIME' : _statusLabel,
                        color: c,
                        fontSize: 10,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Console Code (big)
                  Text(
                    console.code,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    console.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Price
                  const GZDivider(margin: EdgeInsets.symmetric(vertical: 8)),
                  if (console.isVipOnly)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Room VIP',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          CurrencyFormatter.toRupiah(console.priceVip),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reguler',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              CurrencyFormatter.toRupiah(console.pricePerHour),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'VIP',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              CurrencyFormatter.toRupiah(console.priceVip),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Playing/Overtime pulse indicator
            if (isPlaying || isOvertime)
              Positioned(
                top: 12,
                right: 12,
                child: _PulsingDot(color: c),
              ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(_anim.value),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_anim.value * 0.6),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
