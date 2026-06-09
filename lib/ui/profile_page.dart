import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'enter_page.dart';
import 'settings_page.dart';
import 'cancellation_refund_page.dart';
import 'review_feedback_page.dart';
import 'promotion_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  String _userName = 'Loading...';
  String _userGender = 'male';
  String _userAge = '25';
  String _userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _userEmail = user.email ?? '');
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _userName = data['name'] ?? 'User';
            _userGender = data['gender'] ?? 'male';
            _userAge = data['age'] ?? '25';
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        }
      }
    }
  }

  IconData _getGenderIcon(String gender) {
    switch (gender) {
      case 'female':
        return Icons.female;
      case 'queer':
        return Icons.transgender;
      case 'male':
      default:
        return Icons.male;
    }
  }

  void showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final ageController = TextEditingController(text: _userAge);
    String selectedGender = _userGender;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        hintText: 'Enter your name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        hintText: 'Enter your age',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Gender Icon',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGenderOption(
                          'male',
                          Icons.male,
                          selectedGender,
                          (val) => setDialogState(() => selectedGender = val),
                        ),
                        _buildGenderOption(
                          'female',
                          Icons.female,
                          selectedGender,
                          (val) => setDialogState(() => selectedGender = val),
                        ),
                        _buildGenderOption(
                          'queer',
                          Icons.transgender,
                          selectedGender,
                          (val) => setDialogState(() => selectedGender = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newAge = ageController.text.trim();
                    if (newName.isNotEmpty) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .update({
                              'name': newName,
                              'gender': selectedGender,
                              'age': newAge,
                            });

                        setState(() {
                          _userName = newName;
                          _userGender = selectedGender;
                          _userAge = newAge;
                        });
                        if (mounted) Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGenderOption(
    String value,
    IconData icon,
    String current,
    Function(String) onSelect,
  ) {
    final bool isSelected = value == current;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : null,
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 32,
          color: isSelected ? Colors.blueAccent : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
            child: Icon(
              _getGenderIcon(_userGender),
              size: 80,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.blueAccent,
                ),
                onPressed: showEditProfileDialog,
              ),
            ],
          ),
          Text(_userEmail, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Text(
            "$_userAge years old",
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 32),

          _buildProfileTile(
            Icons.settings_outlined,
            'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          _buildProfileTile(
            Icons.cancel_presentation_outlined,
            'Cancellations & Refunds',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CancellationRefundPage(),
                ),
              );
            },
          ),
          _buildProfileTile(
            Icons.local_offer_outlined,
            'Promotions & Discounts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PromotionPage()),
              );
            },
          ),
          _buildProfileTile(
            Icons.rate_review_outlined,
            'Review & Feedback',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReviewFeedbackPage(),
                ),
              );
            },
          ),
          const Divider(height: 40),
          _buildProfileTile(
            Icons.logout,
            'Logout',
            color: Colors.red,
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const EnterPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(
    IconData icon,
    String title, {
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
