import 'package:flutter/material.dart';
import 'user_storage.dart';

class CurrencyExchangePage extends StatefulWidget {
  const CurrencyExchangePage({super.key});

  @override
  State<CurrencyExchangePage> createState() => _CurrencyExchangePageState();
}

class _CurrencyExchangePageState extends State<CurrencyExchangePage> {
  late String _appCurrency;

  @override
  void initState() {
    super.initState();
    _appCurrency = SessionData.getSelectedCurrency();
  }

  void _updateAppCurrency(String? newCurrency) {
    if (newCurrency != null) {
      setState(() {
        _appCurrency = newCurrency;
      });
      SessionData.setSelectedCurrency(newCurrency);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('App currency updated to $newCurrency'),
          backgroundColor: Colors.blueAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rates = SessionData.exchangeRates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Settings'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferred Currency',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Choose the currency you want to see for all travel packages and bookings.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _appCurrency,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.blueAccent,
                  ),
                  items: rates.keys.map((String currency) {
                    return DropdownMenuItem<String>(
                      value: currency,
                      child: Text(
                        '$currency - ${_getCurrencyName(currency)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: _updateAppCurrency,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orangeAccent),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All package prices will be automatically converted and displayed in your chosen currency.',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                'Rates are updated periodically based on market data.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getCurrencyName(String code) {
    switch (code) {
      case 'USD':
        return 'US Dollar';
      case 'MYR':
        return 'Malaysian Ringgit';
      case 'CNY':
        return 'Chinese Yuan';
      case 'SGD':
        return 'Singapore Dollar';
      default:
        return '';
    }
  }
}
