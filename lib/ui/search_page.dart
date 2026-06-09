import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'agent_selection_page.dart';
import 'user_storage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _planController = TextEditingController();
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _returnController = TextEditingController();

  final List<String> _suggestions = ['KL', 'Dubai', 'Morocco', 'Tokyo'];

  late List<Map<String, dynamic>> _featuredPackages;
  List<String> _wishlistPackageNames = [];

  @override
  void initState() {
    super.initState();
    _featuredPackages = SessionData.getFeaturedPackages();
    _listenToWishlist();
  }

  void _listenToWishlist() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('wishlist')
          .snapshots()
          .listen((snapshot) {
            if (mounted) {
              setState(() {
                _wishlistPackageNames = snapshot.docs
                    .map((doc) => doc['name'] as String)
                    .toList();
              });
            }
          });
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  bool _isInWishlist(String name) {
    return _wishlistPackageNames.contains(name);
  }

  Future<void> _toggleWishlist(Map<String, dynamic> pkg) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add to wishlist')),
      );
      return;
    }

    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');

    if (_isInWishlist(pkg['name']!)) {
      final snapshot = await collection
          .where('name', isEqualTo: pkg['name'])
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pkg['name']} removed from wishlist')),
        );
      }
    } else {
      await collection.add({
        'name': pkg['name']!,
        'price': pkg['price']!, // Store base USD price
        'image': pkg['image']!,
        'location': pkg['location'] ?? pkg['name']!,
        'activities': pkg['activities'] ?? [],
        'priceDisplay': pkg['priceDisplay'] ?? '/night',
        'agentName': pkg['agentName'],
        'addedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pkg['name']} added to wishlist!')),
        );
      }
    }
  }

  void _showActivities(BuildContext context, Map<String, dynamic> pkg) {
    final dynamic activitiesData = pkg['activities'];
    final List<String> activities = activitiesData != null
        ? (activitiesData as List).map((a) => a.toString()).toList()
        : [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activities for ${pkg['name']}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              if (activities.isEmpty)
                const Text('No activities listed for this package.')
              else
                ...activities.map(
                  (activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_border,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(activity, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPopularSuggestions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Destination',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _planController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Where do you want to go?',
                  prefixIcon: const Icon(
                    Icons.map_outlined,
                    color: Colors.blueAccent,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.blueAccent,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => Navigator.pop(context),
                onChanged: (val) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Popular Suggestions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 12.0,
                children: _suggestions.map((city) {
                  return ActionChip(
                    label: Text(city),
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.05),
                    labelStyle: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                    ),
                    side: BorderSide(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () {
                      setState(() {
                        _planController.text = city;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan Your Trip',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your destination and dates to get started.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _buildInputField(
            label: 'Destination',
            controller: _planController,
            hint: 'Where do you want to go?',
            icon: Icons.map_outlined,
            readOnly: true,
            onTap: _showPopularSuggestions,
          ),
          const SizedBox(height: 32),
          const Text(
            'Featured Packages',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredPackages.length,
              itemBuilder: (context, index) {
                final pkg = _featuredPackages[index];
                return _buildPackageCard(pkg);
              },
            ),
          ),
          const SizedBox(height: 32),
          _buildInputField(
            label: 'Departure Date',
            controller: _departureController,
            hint: 'Select Date',
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _selectDate(context, _departureController),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            label: 'Return Date',
            controller: _returnController,
            hint: 'Select Date',
            icon: Icons.calendar_month_outlined,
            readOnly: true,
            onTap: () => _selectDate(context, _returnController),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final plan = _planController.text;
                final dep = _departureController.text;
                final ret = _returnController.text;
                if (plan.isEmpty || dep.isEmpty || ret.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill in destination, departure, and return dates',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentSelectionPage(
                      destination: plan,
                      departureDate: dep,
                      returnDate: ret,
                      canBook: true, // User input plans can be booked
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Search Your Packages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final bool inWishlist = _isInWishlist(pkg['name']!);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Stack(
          children: [
            InkWell(
              onTap: () {
                String destination = pkg['location'] ?? pkg['name']!;
                String dep = _departureController.text;
                String ret = _returnController.text;

                // If dates are empty, provide defaults (tomorrow and 4 days later)
                if (dep.isEmpty || ret.isEmpty) {
                  final now = DateTime.now();
                  final tomorrow = now.add(const Duration(days: 1));
                  final fourDaysLater = now.add(const Duration(days: 4));

                  if (dep.isEmpty) {
                    dep =
                        "${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}";
                  }
                  if (ret.isEmpty) {
                    ret =
                        "${fourDaysLater.year}-${fourDaysLater.month.toString().padLeft(2, '0')}-${fourDaysLater.day.toString().padLeft(2, '0')}";
                  }
                }

                setState(() {
                  _planController.text = destination;
                  _departureController.text = dep;
                  _returnController.text = ret;
                });

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AgentSelectionPage(
                      destination: destination,
                      departureDate: dep,
                      returnDate: ret,
                      canBook: true,
                      initialAgentName: pkg['agentName'],
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    pkg['image']!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${SessionData.formatPrice(pkg['price'])}${pkg['priceDisplay'] ?? '/night'}",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                radius: 18,
                child: IconButton(
                  icon: Icon(
                    inWishlist ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _toggleWishlist(pkg),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.8),
                radius: 18,
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () => _showActivities(context, pkg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blueAccent),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
