import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  static final DateFormat _dateShort = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateLong = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final DateFormat _time = DateFormat('HH:mm', 'id_ID');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy HH:mm', 'id_ID');
  static final DateFormat _receipt = DateFormat('dd/MM/yyyy HH:mm:ss', 'id_ID');

  /// Format angka ke Rupiah. Contoh: 25000 → "Rp 25.000"
  static String toRupiah(num amount) => _idr.format(amount);

  /// Format angka ke Rupiah kompak. Contoh: 1500000 → "Rp 1,5 jt"
  static String toRupiahCompact(num amount) => _compact.format(amount);

  /// Format raw angka dengan titik pemisah ribuan
  static String toNumber(num amount) =>
      NumberFormat('#,###', 'id_ID').format(amount);

  /// Parse string Rupiah ke double
  static double parseRupiah(String text) {
    final cleaned = text
        .replaceAll('Rp', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }

  // ── Date Formatters ───────────────────────────────────────────────────────

  static String toDateShort(DateTime dt) => _dateShort.format(dt);
  static String toDateLong(DateTime dt) => _dateLong.format(dt);
  static String toTime(DateTime dt) => _time.format(dt);
  static String toDateTime(DateTime dt) => _dateTime.format(dt);
  static String toReceiptDate(DateTime dt) => _receipt.format(dt);

  /// Hitung durasi dari waktu mulai hingga sekarang / waktu selesai
  static String durationString(DateTime start, {DateTime? end}) {
    final diff = (end ?? DateTime.now()).difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }

  /// Menit → string durasi. Contoh: 90 → "1j 30m"
  static String minutesToString(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}j ${m}m';
    if (h > 0) return '${h} jam';
    return '$m menit';
  }
}
