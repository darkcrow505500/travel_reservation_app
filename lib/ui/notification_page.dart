import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_storage.dart';
import 'promotion_page.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool notificationsEnabled = SessionData.areNotificationsEnabled();
    final user = FirebaseAuth.instance.currentUser;

    if (!notificationsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: _buildDisabledState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: user == null
          ? _buildLoginRequiredState()
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('bookings')
                  .where('status', isEqualTo: 'Confirmed')
                  .snapshots(),
              builder: (context, snapshot) {
                final promotions = SessionData.getPromotions();
                List<Map<String, dynamic>> incomingBookings = [];

                if (snapshot.hasData) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final formatter = DateFormat('yyyy-MM-dd');

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    try {
                      final depDate = formatter.parse(data['date']);
                      // Only include bookings that are today or in the future
                      if (depDate.isAfter(today) ||
                          depDate.isAtSameMomentAs(today)) {
                        incomingBookings.add(data);
                      }
                    } catch (e) {
                      // Skip invalid dates
                    }
                  }
                  // Sort by departure date ascending
                  incomingBookings.sort(
                    (a, b) => a['date'].compareTo(b['date']),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSectionHeader(
                      'Special Promotions',
                      Icons.local_offer_outlined,
                    ),
                    const SizedBox(height: 12),
                    ...promotions.map((p) => _buildPromoCard(context, p)),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'Incoming Bookings',
                      Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 12),
                    if (incomingBookings.isEmpty)
                      _buildEmptyIncomingState()
                    else
                      ...incomingBookings.map(
                        (b) => _buildBookingCard(context, b),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCard(BuildContext context, Map<String, dynamic> promo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PromotionPage()),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_offer, color: Colors.orange),
        ),
        title: Text(
          promo['code'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(promo['description']),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> booking) {
    final dateString = booking['date'] ?? '';
    String relativeTime = '';

    if (dateString.isNotEmpty) {
      try {
        final formatter = DateFormat('yyyy-MM-dd');
        final depDate = formatter.parse(dateString);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final difference = depDate.difference(today).inDays;

        if (difference == 0) {
          relativeTime = ' (Today)';
        } else if (difference == 1) {
          relativeTime = ' (Tomorrow)';
        } else if (difference > 1) {
          relativeTime = ' (In $difference days)';
        }
      } catch (e) {
        // ignore
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                    booking['dest'] ?? 'Destination',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Confirmed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    children: [
                      TextSpan(text: 'Departure: $dateString'),
                      if (relativeTime.isNotEmpty)
                        TextSpan(
                          text: relativeTime,
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.support_agent, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Agent: ${booking['agent']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyIncomingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note, color: Colors.grey, size: 40),
          SizedBox(height: 12),
          Text(
            'No upcoming trips found.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Notifications are turned off',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginRequiredState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Login Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please login to see your notifications.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
