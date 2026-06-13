import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_storage.dart';
import '../utils/price_calculator.dart';
import 'dart:math';

class PaymentPopup extends StatefulWidget {
  final Map<String, dynamic> pkg;
  final String departureDate;
  final String returnDate;
  final String agentName;
  final Function(String) onPaymentSuccess;

  const PaymentPopup({
    super.key,
    required this.pkg,
    required this.departureDate,
    required this.returnDate,
    required this.agentName,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentPopup> createState() => _PaymentPopupState();
}

class _PaymentPopupState extends State<PaymentPopup> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _promoController = TextEditingController();

  bool _isQuickPay = false;
  Map<String, dynamic>? _appliedPromo;
  late double _originalPriceUsd;
  late double _currentTotalUsd;
  String? _statusMessage;
  bool _isErrorMessage = false;

  @override
  void initState() {
    super.initState();
    if (widget.pkg['priceUsd'] != null) {
      _originalPriceUsd = (widget.pkg['priceUsd'] as num).toDouble();
    } else {
      _originalPriceUsd = PriceCalculator.parsePrice(
        widget.pkg['price'].toString(),
      );
    }
    _currentTotalUsd = _originalPriceUsd;

    final savedCard = SessionData.getSavedCard();
    if (savedCard != null) {
      _cardNumberController.text = savedCard['number'] ?? '';
      _expiryController.text = savedCard['expiry'] ?? '';
      _cvvController.text = savedCard['cvv'] ?? '';
      _isQuickPay = true;
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  void _showStatus(String message, {bool isError = false}) {
    setState(() {
      _statusMessage = message;
      _isErrorMessage = isError;
    });
  }

  void _applyPromo() {
    final code = _promoController.text.trim();
    final result = PriceCalculator.applyPromoCode(code, _originalPriceUsd);

    setState(() {
      _appliedPromo = result['promo'];
      _currentTotalUsd = result['price'];
      _statusMessage = result['message'];
      _isErrorMessage = !result['success'];
    });
  }

  Future<void> _validateAndPay() async {
    if (_appliedPromo == null && _promoController.text.trim().isNotEmpty) {
      _applyPromo();
      if (_appliedPromo == null && _promoController.text.trim().isNotEmpty) {
        return;
      }
    }

    if (_cardNumberController.text.trim().isEmpty ||
        _expiryController.text.trim().isEmpty ||
        _cvvController.text.trim().isEmpty) {
      _showStatus('Please fill in all payment details', isError: true);
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showStatus('Please login to complete payment', isError: true);
      return;
    }

    if (_appliedPromo != null) {
      SessionData.usePromo(_appliedPromo!['code']);
    }

    final String bookingCode = (Random().nextInt(900000) + 100000).toString();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookings')
          .add({
            'bookingCode': bookingCode,
            'dest': widget.pkg['location'] ?? widget.pkg['name'],
            'name': widget.pkg['name'],
            'date': widget.departureDate,
            'returnDate': widget.returnDate,
            'price': PriceCalculator.formatCurrency(_currentTotalUsd),
            'priceUsd': _currentTotalUsd,
            'status': 'Confirmed',
            'agent': widget.agentName,
            'activities': widget.pkg['activities'],
            'promoCode': _appliedPromo?['code'],
            'createdAt': FieldValue.serverTimestamp(),
          });

      widget.onPaymentSuccess(bookingCode);
    } catch (e) {
      if (mounted) {
        _showStatus('Payment failed: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = PriceCalculator.calculateDays(
      widget.departureDate,
      widget.returnDate,
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isErrorMessage ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isErrorMessage ? Colors.red : Colors.green,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isErrorMessage
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: _isErrorMessage ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isErrorMessage
                              ? Colors.red[900]
                              : Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _statusMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            Icon(
              _isQuickPay ? Icons.flash_on : Icons.payment,
              size: 48,
              color: _isQuickPay ? Colors.orange : Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _isQuickPay ? 'Quick Pay' : 'Secure Payment',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            if (_isQuickPay)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  'Using your saved payment method',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Package: ${widget.pkg['name']}'),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Duration: $days ${days == 1 ? "day" : "days"}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      labelText: 'Promo Code',
                      hintText: 'Enter code',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      suffixIcon: _appliedPromo != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _applyPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_appliedPromo != null) ...[
              Text(
                'Original: ${PriceCalculator.formatCurrency(_originalPriceUsd)}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Total Amount: ${PriceCalculator.formatCurrency(_currentTotalUsd)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              readOnly: _isQuickPay,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.credit_card),
                suffixIcon: _isQuickPay
                    ? TextButton(
                        onPressed: () => setState(() => _isQuickPay = false),
                        child: const Text('Edit'),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (!_isQuickPay)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validateAndPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isQuickPay
                          ? Colors.orange
                          : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isQuickPay ? 'Confirm & Pay' : 'Pay Now',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
}
