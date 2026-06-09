import 'package:firebase_auth/firebase_auth.dart';

// SessionData manages registered users, current session, and user-specific data.
class SessionData {
  static final Map<String, String> _registeredUsers = {};

  // Use Firebase Auth to track the current user
  static String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // User-specific wishlists (ID -> List of items)
  static final Map<String, List<Map<String, dynamic>>> _userWishlists = {};

  // User-specific bookings (ID -> List of items)
  static final Map<String, List<Map<String, dynamic>>> _userBookings = {};

  // User-specific profiles (ID -> {name, gender, age, email})
  static final Map<String, Map<String, String>> _userProfiles = {};

  // User-specific payment methods (ID -> {number, expiry, cvv})
  static final Map<String, Map<String, String>> _userPaymentMethods = {};

  // User-specific feedbacks (ID -> List of {rating, comment, date})
  static final Map<String, List<Map<String, dynamic>>> _userFeedbacks = {};

  // User-specific settings (ID -> {notificationsEnabled: bool, currency: String})
  static final Map<String, Map<String, dynamic>> _userSettings = {};

  // User-specific used promotions (ID -> Set of codes)
  static final Map<String, Set<String>> _userUsedPromos = {};

  // Global static promotions
  static final List<Map<String, dynamic>> _promotions = [
    {
      'code': 'WELCOME10',
      'description': '10% off for your first booking!',
      'discountPercent': 10.0,
      'type': 'percent',
    },
    {
      'code': 'HOLIDAY20',
      'description': '20% off on all packages!',
      'discountPercent': 20.0,
      'type': 'percent',
    },
    {
      'code': 'SUMMER15',
      'description': '15% off for summer season!',
      'discountPercent': 15.0,
      'type': 'percent',
    },
  ];

  // Global static agents and their packages
  static final List<Map<String, dynamic>> _agents = [
    {
      'name': 'Elite Travel Services',
      'rating': 4.8,
      'image':
          'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400',
      'description': 'Luxury travel specialists with 20 years of experience.',
      'packages': [
        {
          'name': 'Kuala Lumpur City Stay',
          'price': '150',
          'accommodation': 'Luxury Suite',
          'location': 'KL',
          'image':
              'https://upload.wikimedia.org/wikipedia/commons/4/41/KL_-_Skyline_on_a_rainy_morning_2.png',
          'activities': [
            'Petronas Towers Visit',
            'Batu Caves Tour',
            'Night Market',
          ],
          'isFeatured': true,
        },
        {
          'name': 'Executive Tokyo',
          'price': '200',
          'accommodation': 'Business Suite',
          'location': 'Tokyo',
          'image':
              'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=400',
          'activities': ['City Tour', 'Networking Dinner', 'Tea Ceremony'],
          'isFeatured': true,
        },
        {
          'name': 'Standard Hotel & Dinner',
          'price': '120',
          'accommodation': '4-Star Hotel',
          'location': 'Generic',
          'image':
              'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
          'activities': ['Hotel Breakfast', 'Fine Dining Dinner', 'City Guide'],
        },
      ],
    },
    {
      'name': 'Adventure Seekers',
      'rating': 4.6,
      'image':
          'https://images.unsplash.com/photo-1527631746610-bca00a040d60?w=400',
      'description': 'Expert guides for off-the-beaten-path experiences.',
      'packages': [
        {
          'name': 'Morocco Desert Magic',
          'price': '180',
          'accommodation': 'Traditional Riad',
          'location': 'Morocco',
          'image':
              'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=400',
          'activities': [
            'Sahara Camel Trek',
            'Marrakesh Souks',
            'Atlas Mountains',
          ],
          'isFeatured': true,
        },
        {
          'name': 'Dubai Desert Safari',
          'price': '300',
          'accommodation': 'Desert Camp',
          'location': 'Dubai',
          'image':
              'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400',
          'activities': ['Dune Bashing', 'Camel Riding', 'Belly Dance'],
          'isFeatured': true,
        },
        {
          'name': 'Essential Travel Package',
          'price': '90',
          'accommodation': 'Comfort Inn',
          'location': 'Generic',
          'image':
              'https://images.unsplash.com/photo-1551882547-ff43c61f3c3a?w=400',
          'activities': ['Daily Breakfast', 'Local Tour', 'Transport Card'],
        },
      ],
    },
  ];

  // Static exchange rates (Base: 1 USD)
  static final Map<String, double> exchangeRates = {
    'USD': 1.0,
    'MYR': 4.73,
    'CNY': 7.24,
    'SGD': 1.35,
  };

  static void registerUser(String id, String password) {
    final key = id.trim().toLowerCase();
    _registeredUsers[key] = password;
    _userWishlists[key] = []; // Initialize empty wishlist for new user
    _userBookings[key] = []; // Initialize empty bookings for new user
    _userFeedbacks[key] = []; // Initialize empty feedbacks for new user
    _userUsedPromos[key] = {}; // Initialize empty used promos for new user
    _userProfiles[key] = {
      'name': 'User $key',
      'gender': 'male', // Default
      'age': '25', // Default
      'email': '$key@example.com', // Default
    };
    _userSettings[key] = {'notificationsEnabled': true, 'currency': 'USD'};
  }

  static bool isValidUser(String id, String password) {
    final storedPassword = _registeredUsers[id.trim().toLowerCase()];
    return storedPassword != null && storedPassword == password;
  }

  static bool isIdRegistered(String id) {
    return _registeredUsers.containsKey(id.trim().toLowerCase());
  }

  // Session Management Methods
  static void setCurrentUser(String? id) {
    // No longer needed as we use FirebaseAuth directly
  }

  static String? getCurrentUser() {
    return _currentUserId;
  }

  static bool isLoggedIn() {
    return _currentUserId != null;
  }

  static void logout() {
    // No longer needed as we use FirebaseAuth directly
  }

  // Profile Management
  static Map<String, String> getProfile() {
    final id = _currentUserId;
    if (id == null) {
      return {
        'name': 'Guest',
        'gender': 'male',
        'age': 'N/A',
        'email': 'guest@example.com',
      };
    }
    return _userProfiles[id] ??
        {
          'name': 'User',
          'gender': 'male',
          'age': '25',
          'email': '$id@example.com',
        };
  }

  static void updateProfile(
    String name,
    String gender,
    String age,
    String email,
  ) {
    final id = _currentUserId;
    if (id != null) {
      _userProfiles[id] = {
        'name': name,
        'gender': gender,
        'age': age,
        'email': email,
      };
    }
  }

  // Settings
  static bool areNotificationsEnabled() {
    final id = _currentUserId;
    if (id == null) return true;
    return _userSettings[id]?['notificationsEnabled'] ?? true;
  }

  static void setNotificationsEnabled(bool enabled) {
    final id = _currentUserId;
    if (id != null) {
      _userSettings[id] ??= {};
      _userSettings[id]!['notificationsEnabled'] = enabled;
    }
  }

  static String getSelectedCurrency() {
    final id = _currentUserId;
    if (id == null) return 'USD';
    return _userSettings[id]?['currency'] ?? 'USD';
  }

  static void setSelectedCurrency(String currency) {
    final id = _currentUserId;
    if (id != null) {
      _userSettings[id] ??= {};
      _userSettings[id]!['currency'] = currency;
    }
  }

  // Currency conversion helper
  static String formatPrice(dynamic priceInUsd) {
    final currency = getSelectedCurrency();
    final rate = exchangeRates[currency] ?? 1.0;

    double numericPrice = 0.0;
    if (priceInUsd is String) {
      numericPrice =
          double.tryParse(priceInUsd.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    } else if (priceInUsd is num) {
      numericPrice = priceInUsd.toDouble();
    }

    final converted = numericPrice * rate;

    switch (currency) {
      case 'MYR':
        return 'RM ${converted.toStringAsFixed(2)}';
      case 'CNY':
        return '¥ ${converted.toStringAsFixed(2)}';
      case 'SGD':
        return 'S\$ ${converted.toStringAsFixed(2)}';
      case 'USD':
      default:
        return '\$ ${converted.toStringAsFixed(2)}';
    }
  }

  // Payment Methods
  static Map<String, String>? getSavedCard() {
    final id = _currentUserId;
    if (id == null) return null;
    return _userPaymentMethods[id];
  }

  static void saveCard(String cardNumber, String expiry, String cvv) {
    final id = _currentUserId;
    if (id != null) {
      _userPaymentMethods[id] = {
        'number': cardNumber,
        'expiry': expiry,
        'cvv': cvv,
      };
    }
  }

  static void removeSavedCard() {
    final id = _currentUserId;
    if (id != null) {
      _userPaymentMethods.remove(id);
    }
  }

  // Wishlist Data Methods
  static List<Map<String, dynamic>> getWishlist() {
    final id = _currentUserId;
    if (id == null) return [];
    return _userWishlists[id] ?? [];
  }

  static void addToWishlist(Map<String, dynamic> item) {
    final id = _currentUserId;
    if (id != null) {
      final list = _userWishlists[id]!;
      // Prevent duplicates
      if (!list.any((e) => e['name'] == item['name'])) {
        list.add(item);
      }
    }
  }

  static void removeFromWishlist(int index) {
    final id = _currentUserId;
    if (id != null) {
      _userWishlists[id]?.removeAt(index);
    }
  }

  // Booking Data Methods
  static List<Map<String, dynamic>> getBookings() {
    final id = _currentUserId;
    if (id == null) return [];
    return _userBookings[id] ?? [];
  }

  static void addBooking(Map<String, dynamic> booking) {
    final id = _currentUserId;
    if (id != null) {
      _userBookings[id]?.add(booking);
    }
  }

  static void cancelBooking(int index) {
    final id = _currentUserId;
    if (id != null && _userBookings[id] != null) {
      if (index >= 0 && index < _userBookings[id]!.length) {
        _userBookings[id]![index]['status'] = 'Cancelled';
        _userBookings[id]![index]['refundStatus'] = 'Refund Processing';
      }
    }
  }

  // Feedback Methods
  static List<Map<String, dynamic>> getFeedbacks() {
    final id = _currentUserId;
    if (id == null) return [];
    return _userFeedbacks[id] ?? [];
  }

  static void addFeedback(double rating, String comment) {
    final id = _currentUserId;
    if (id != null) {
      _userFeedbacks[id] ??= [];
      _userFeedbacks[id]!.add({
        'rating': rating,
        'comment': comment,
        'date': DateTime.now().toString().split('.')[0],
      });
    }
  }

  // Promotion Methods
  static List<Map<String, dynamic>> getPromotions() {
    return _promotions;
  }

  static Map<String, dynamic>? getPromotionByCode(String code) {
    try {
      return _promotions.firstWhere(
        (p) => p['code'].toString().toUpperCase() == code.trim().toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static bool isPromoUsed(String code) {
    final id = _currentUserId;
    if (id == null) return false;
    return _userUsedPromos[id]?.contains(code.toUpperCase()) ?? false;
  }

  static void usePromo(String code) {
    final id = _currentUserId;
    if (id != null) {
      _userUsedPromos[id] ??= {};
      _userUsedPromos[id]!.add(code.toUpperCase());
    }
  }

  // Agent and Package Methods
  static List<Map<String, dynamic>> getAgents() {
    return _agents;
  }

  static List<Map<String, dynamic>> getFeaturedPackages() {
    List<Map<String, dynamic>> featured = [];
    for (var agent in _agents) {
      final packages = agent['packages'] as List<Map<String, dynamic>>;
      for (var pkg in packages) {
        if (pkg['isFeatured'] == true) {
          final featuredPkg = Map<String, dynamic>.from(pkg);
          featuredPkg['agentName'] = agent['name'];
          featured.add(featuredPkg);
        }
      }
    }
    return featured;
  }
}
