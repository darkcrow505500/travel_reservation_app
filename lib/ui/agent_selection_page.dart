import 'package:flutter/material.dart';
import 'user_storage.dart';
import 'payment_page.dart';
import 'home_page.dart';
import '../utils/price_calculator.dart';

class AgentSelectionPage extends StatefulWidget {
  final String destination;
  final String departureDate;
  final String returnDate;
  final bool canBook;
  final String? initialAgentName;

  const AgentSelectionPage({
    super.key,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    this.canBook = true,
    this.initialAgentName,
  });

  @override
  State<AgentSelectionPage> createState() => _AgentSelectionPageState();
}

class _AgentSelectionPageState extends State<AgentSelectionPage> {
  Map<String, dynamic>? _selectedAgent;
  late List<Map<String, dynamic>> _agents;

  @override
  void initState() {
    super.initState();
    _filterAgents();
    if (widget.initialAgentName != null) {
      try {
        _selectedAgent = _agents.firstWhere(
          (agent) => agent['name'] == widget.initialAgentName,
        );
      } catch (e) {
        _selectedAgent = null;
      }
    }
  }

  void _filterAgents() {
    final allAgents = SessionData.getAgents();
    final searchDest = widget.destination.toLowerCase();

    _agents = allAgents.where((agent) {
      final packages = agent['packages'] as List;
      return packages.any((pkg) {
        final location = (pkg['location'] ?? '').toString().toLowerCase();
        final name = (pkg['name'] ?? '').toString().toLowerCase();
        return location.contains(searchDest) || name.contains(searchDest);
      });
    }).toList();
  }

  bool _isInWishlist(String name) {
    final wishlist = SessionData.getWishlist();
    return wishlist.any((item) => item['name'] == name);
  }

  void _toggleWishlist(Map<String, dynamic> pkg) {
    if (!SessionData.isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to wishlist')),
      );
      return;
    }

    setState(() {
      if (_isInWishlist(pkg['name']!)) {
        final wishlist = SessionData.getWishlist();
        final index = wishlist.indexWhere(
          (item) => item['name'] == pkg['name'],
        );
        if (index != -1) {
          SessionData.removeFromWishlist(index);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pkg['name']} removed from wishlist')),
          );
        }
      } else {
        SessionData.addToWishlist({
          'name': pkg['name']!,
          'price': pkg['price']!, // Store base USD price
          'image': pkg['image']!,
          'location': pkg['location'] ?? pkg['name']!,
          'activities': pkg['activities'] ?? [],
          'priceDisplay': '/night', // Agent packages are typically per night
          'agentName': _selectedAgent?['name'] ?? 'Unknown Agent',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pkg['name']} added to wishlist!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedAgent == null ? 'Select Agent' : 'Packages'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        leading: _selectedAgent != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedAgent = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedAgent == null ? _buildAgentList() : _buildPackageList(),
      ),
    );
  }

  Widget _buildAgentList() {
    if (_agents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No agents found for "${widget.destination}"',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _agents.length + 1,
      itemBuilder: (context, index) {
        if (index == _agents.length) {
          return _buildHomeButton();
        }
        final agent = _agents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(agent['image']),
            ),
            title: Text(
              agent['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(agent['description']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedAgent = agent),
          ),
        );
      },
    );
  }

  Widget _buildPackageList() {
    final allPackages = (_selectedAgent!['packages'] as List);
    final searchDest = widget.destination.toLowerCase();
    final packages = allPackages.where((pkg) {
      final location = (pkg['location'] ?? '').toString().toLowerCase();
      final name = (pkg['name'] ?? '').toString().toLowerCase();
      return location.contains(searchDest) || name.contains(searchDest);
    }).toList();

    final days = PriceCalculator.calculateDays(
      widget.departureDate,
      widget.returnDate,
    );

    if (packages.isEmpty) {
      return Center(child: Text('No packages available for this destination.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length + 1,
      itemBuilder: (context, index) {
        if (index == packages.length) {
          return _buildHomeButton();
        }
        final pkg = packages[index];
        final basePrice = PriceCalculator.parsePrice(pkg['price']);
        final totalUsd = basePrice * days;
        final bool inWishlist = _isInWishlist(pkg['name']!);

        final List<String> activities = List<String>.from(
          pkg['activities'] ?? [],
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pkg['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        inWishlist ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _toggleWishlist(pkg),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rate: ${SessionData.formatPrice(pkg['price'])}/night',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'Duration: $days ${days == 1 ? "day" : "days"}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Activities Included:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 0,
                  children: activities
                      .map(
                        (activity) => Chip(
                          label: Text(
                            activity,
                            style: const TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.blueAccent.withValues(
                            alpha: 0.1,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total Price: ${SessionData.formatPrice(totalUsd)}',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.canBook)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handlePaymentAndBooking(pkg, totalUsd),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        SessionData.getSavedCard() != null
                            ? 'Quick Book'
                            : 'Book & Pay Now',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.home, color: Colors.blueAccent),
          label: const Text(
            'Back to Home',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.blueAccent, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  void _handlePaymentAndBooking(Map<String, dynamic> pkg, double totalUsd) {
    // Create a copy of pkg with the formatted converted price for payment
    final updatedPkg = Map<String, dynamic>.from(pkg);
    updatedPkg['price'] = SessionData.formatPrice(totalUsd);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => PaymentPopup(
        pkg: updatedPkg,
        departureDate: widget.departureDate,
        returnDate: widget.returnDate,
        agentName: _selectedAgent!['name'],
        onPaymentSuccess: (bookingCode) {
          Navigator.pop(sheetContext); // Close payment sheet
          if (mounted) {
            _showSuccessDialog(updatedPkg, bookingCode);
          }
        },
      ),
    );
  }

  void _showSuccessDialog(Map<String, dynamic> pkg, String bookingCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your booking for ${pkg['name']} is confirmed.'),
            const SizedBox(height: 12),
            Text(
              'Booking Code: #$bookingCode',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Home'),
          ),
        ],
      ),
    );
  }
}
