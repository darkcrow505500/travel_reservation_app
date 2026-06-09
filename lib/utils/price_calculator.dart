import 'package:intl/intl.dart';
import '../ui/user_storage.dart';

class PriceCalculator {
  static int calculateDays(String departureDate, String returnDate) {
    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final DateTime start = formatter.parse(departureDate);
      final DateTime end = formatter.parse(returnDate);

      final int difference = end.difference(start).inDays;
      // Ensure at least 1 day for calculation if dates are same
      return difference <= 0 ? 1 : difference;
    } catch (e) {
      return 1;
    }
  }

  static double parsePrice(String priceString) {
    // Remove currency symbols and /night suffix, commas etc.
    final String cleaned = priceString
        .replaceAll(RegExp(r'[^\d.]'), '')
        .split('/')
        .first;
    return double.tryParse(cleaned) ?? 0.0;
  }

  static String formatCurrency(double amount) {
    // Use SessionData to get the converted and formatted currency string
    return SessionData.formatPrice(amount);
  }

  static double calculateTotal(String basePriceStr, int days) {
    final double basePrice = parsePrice(basePriceStr);
    return basePrice * days;
  }

  static double calculateDiscountedPrice(
    double originalPrice,
    Map<String, dynamic> promo,
  ) {
    if (promo['type'] == 'percent') {
      double percent = (promo['discountPercent'] as num).toDouble();
      return originalPrice * (1 - (percent / 100));
    } else if (promo['type'] == 'flat') {
      double amount = (promo['discountAmount'] as num).toDouble();
      return (originalPrice - amount).clamp(0.0, double.infinity);
    }
    return originalPrice;
  }
}
