// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart';
// import '../models/restaurant.dart' hide User;  // Hide the User class from restaurant.dart
// import '../models/user.dart' as user_model;    // Import with prefix to avoid conflict
// import 'category_service.dart';

// class RestaurantService extends ChangeNotifier {
//   static final RestaurantService _instance = RestaurantService._internal();
//   factory RestaurantService() => _instance;
//   bool _isInitialized = false;
  
//   RestaurantService._internal() {
//     // Initialize when the instance is created
//     init();
//   }
  
//   // Getter to check if service is initialized
//   bool get isInitialized => _isInitialized;

//   // Default time slots (5 slots with 30-minute intervals)
//   static const List<String> defaultTimeSlots = [
//     '10:00',
//     '10:30',
//     '11:00',
//     '11:30',
//     '12:00',
//   ];

//   final CategoryService _categoryService = CategoryService();

//   final String _restaurantsFile = 'restaurants.json';
//   final String _usersFile = 'users.json';
//   final Uuid _uuid = const Uuid();
  
//   List<Restaurant> _restaurants = [];
//   List<user_model.User> _users = [];
//   user_model.User? _currentUser;

 


//   // Initialize the service
//   Future<void> init() async {
//     if (!_isInitialized) {
//       await _loadData();
//       _isInitialized = true;
//     }
//   }

//   // Load data from storage
//   Future<void> _loadData() async {
//     try {
//       bool dataLoaded = false;
      
//       // For web, try loading from shared_preferences first
//       if (kIsWeb) {
//         try {
//           final prefs = await SharedPreferences.getInstance();
          
//           // Load restaurants
//           final restaurantsJson = prefs.getString('restaurants_data');
//           if (restaurantsJson != null) {
//             final List<dynamic> data = jsonDecode(restaurantsJson);
//             _restaurants = data.map((item) => Restaurant.fromMap(item)).toList();
//             debugPrint('Loaded ${_restaurants.length} restaurants from shared_preferences');
//           }
          
//           // Load users
//           final usersJson = prefs.getString('app_users_data');
//           if (usersJson != null) {
//             final List<dynamic> data = jsonDecode(usersJson);
//             _users = data.map((item) => user_model.User.fromJson(item)).toList();
//             debugPrint('Loaded ${_users.length} users from shared_preferences');
//             dataLoaded = true;
//           }
//         } catch (e) {
//           debugPrint('Error loading from shared_preferences: $e');
//         }
//       }
      
//       // If web loading failed or it's not web, try loading from file
//       if (!dataLoaded) {
//         try {
//           final directory = await getApplicationDocumentsDirectory();
//           final restaurantsPath = path.join(directory.path, _restaurantsFile);
//           final usersPath = path.join(directory.path, _usersFile);
          
//           // Load restaurants
//           if (await File(restaurantsPath).exists()) {
//             final jsonData = await File(restaurantsPath).readAsString();
//             final List<dynamic> data = jsonDecode(jsonData);
//             _restaurants = data.map((item) => Restaurant.fromMap(item)).toList();
//             debugPrint('Loaded ${_restaurants.length} restaurants from file');
//           }
          
//           // Load users
//           if (await File(usersPath).exists()) {
//             final jsonData = await File(usersPath).readAsString();
//             final List<dynamic> data = jsonDecode(jsonData);
//             _users = data.map((item) => user_model.User.fromJson(item)).toList();
//             debugPrint('Loaded ${_users.length} users from file');
//           }
//         } catch (e) {
//           debugPrint('Error loading from files: $e');
//         }
//       }
      
//       // If no users were loaded, create default admin user
//       if (_users.isEmpty) {
//         debugPrint('No users found, creating default admin user');
//         _users = [
//           user_model.User(
//             id: _uuid.v4(),
//             name: 'Admin',
//             email: 'admin@example.com',
//             password: 'admin123',
//             phoneNumber: '+1234567890',
//           ),
//         ];
//         await _saveUsers();
//       }
//     } catch (e) {
//       debugPrint('Error loading data: $e');
//       _restaurants = [];
//       _users = [];
//     }
//   }

//   // Save restaurants to local storage
//   Future<void> _saveRestaurants() async {
//     final jsonData = _restaurants.map((r) => r.toMap()).toList();
//     final jsonString = jsonEncode(jsonData);
    
//     // For web, use shared_preferences
//     if (kIsWeb) {
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('restaurants_data', jsonString);
//         debugPrint('Successfully saved ${_restaurants.length} restaurants to shared_preferences');
//         notifyListeners();
//         return;
//       } catch (e) {
//         debugPrint('Error saving restaurants to shared_preferences: $e');
//         // Fall through to file storage if shared_preferences fails
//       }
//     }
    
//     // For non-web or if web storage failed, try file storage
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File(path.join(directory.path, _restaurantsFile));
//       await file.writeAsString(jsonString);
//       debugPrint('Successfully saved ${_restaurants.length} restaurants to file');
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error saving restaurants to file: $e');
//       if (!kIsWeb) {
//         rethrow; // Only rethrow for non-web platforms
//       }
//     }
//   }

//   // Save users to local storage
//   Future<void> _saveUsers() async {
//     final jsonData = _users.map((u) => u.toJson()).toList();
//     final jsonString = jsonEncode(jsonData);
    
//     // For web, use shared_preferences
//     if (kIsWeb) {
//       try {
//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('app_users_data', jsonString);
//         debugPrint('Successfully saved ${_users.length} users to shared_preferences');
//         notifyListeners();
//         return;
//       } catch (e) {
//         debugPrint('Error saving users to shared_preferences: $e');
//         // Fall through to file storage if shared_preferences fails
//       }
//     }
    
//     // For non-web or if web storage failed, try file storage
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final file = File(path.join(directory.path, _usersFile));
//       await file.writeAsString(jsonString);
//       debugPrint('Successfully saved ${_users.length} users to file');
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error saving users to file: $e');
//       if (!kIsWeb) {
//         rethrow; // Only rethrow for non-web platforms
//       }
//     }
//   }

//   // Get all available categories
//   Future<List<String>> getCategories() async {
//     return await _categoryService.getCategories();
//   }

//   // Add a new category
//   Future<bool> addCategory(String category) async {
//     final success = await _categoryService.addCategory(category);
//     if (success) {
//       notifyListeners();
//     }
//     return success;
//   }

//   // Remove a category
//   Future<bool> removeCategory(String category) async {
//     final success = await _categoryService.removeCategory(category);
//     if (success) {
//       // Remove this category from any restaurants that have it
//       for (var restaurant in _restaurants) {
//         if (restaurant.category == category) {
//           // You might want to handle this differently in a real app,
//           // like setting a default category or preventing deletion
//           restaurant = restaurant.copyWith(category: 'Uncategorized');
//         }
//       }
//       await _saveRestaurants();
//       notifyListeners();
//     }
//     return success;
//   }

//   // Get default time slots
//   List<String> getDefaultTimeSlots() {
//     return List.from(defaultTimeSlots);
//   }

//   // Restaurant CRUD operations
//   Future<Restaurant> addRestaurant({
//     required String name,
//     required String description,
//     required String imagePath,
//     required String category,
//     required int tableCount,
//     required int seatsPerTable, // This parameter is kept for backward compatibility but will be overridden
//     required Map<String, dynamic> location,
//     List<String>? timeSlots,
//   }) async {
//     // Enforce exactly 6 seats per table as per requirements
//     const validatedSeats = 6;
    
//     // Use default time slots if none provided
//     final restaurantTimeSlots = timeSlots ?? List.from(defaultTimeSlots);
    
//     // Create tables
//     final tables = List<TableModel>.generate(
//       tableCount,
//       (index) => TableModel(
//         id: _uuid.v4(),
//         number: index + 1,
//         maxSeats: validatedSeats,
//       ),
//     );

//     final newRestaurant = Restaurant(
//       id: _uuid.v4(),
//       name: name,
//       description: description,
//       imagePath: imagePath,
//       category: category,
//       tableCount: tableCount,
//       seatsPerTable: validatedSeats,
//       timeSlots: restaurantTimeSlots,
//       location: location,
//       tables: tables,
//     );

//     _restaurants.add(newRestaurant);
//     await _saveRestaurants();
//     notifyListeners();
//     return newRestaurant;
//   }

//   Future<void> updateRestaurant(Restaurant updatedRestaurant) async {
//     final index = _restaurants.indexWhere((r) => r.id == updatedRestaurant.id);
//     if (index != -1) {
//       _restaurants[index] = updatedRestaurant;
//       await _saveRestaurants();
//       notifyListeners();
//     }
//   }

//   Future<void> deleteRestaurant(String restaurantId) async {
//     _restaurants.removeWhere((r) => r.id == restaurantId);
//     await _saveRestaurants();
//     notifyListeners();
//   }

//   List<Restaurant> getAllRestaurants() {
//     return List.from(_restaurants);
//   }

//   List<String> getAllCategories() {
//     final categories = _restaurants.map((r) => r.category).toSet().toList();
//     return categories..sort();
//   }

//   List<Restaurant> getRestaurantsByCategory(String category) {
//     return _restaurants.where((r) => r.category == category).toList();
//   }

//   List<Restaurant> getAvailableRestaurants({
//     required DateTime date,
//     required String timeSlot,
//     int? minSeats,
//     String? category,
//   }) {
//     return _restaurants.where((restaurant) {
//       // Filter by category if specified
//       if (category != null && restaurant.category != category) {
//         return false;
//       }
      
//       // Check if the time slot exists
//       if (!restaurant.timeSlots.contains(timeSlot)) {
//         return false;
//       }
      
//       // Check if there's at least one available table
//       return restaurant.tables.any((table) {
//         final hasEnoughSeats = minSeats == null || table.maxSeats >= minSeats;
//         return hasEnoughSeats && table.isAvailable(date, timeSlot);
//       });
//     }).toList();
//   }

//   Restaurant? getRestaurantById(String id) {
//     try {
//       return _restaurants.firstWhere((r) => r.id == id);
//     } catch (e) {
//       return null;
//     }
//   }

//   // Get current user
//   user_model.User? get currentUser => _currentUser;

//   // Set current user
//   void setCurrentUser(user_model.User? user) {
//     _currentUser = user;
//     notifyListeners();
//   }


//   // Get available time slots for a table
//   List<String> getAvailableTimeSlots({
//     required String restaurantId,
//     required String tableId,
//     required DateTime date,
//   }) {
//     try {
//       final restaurant = getRestaurantById(restaurantId);
//       if (restaurant == null) return [];
      
//       final table = restaurant.tables.firstWhere(
//         (t) => t.id == tableId,
//         orElse: () => throw Exception('Table not found'),
//       );
      
//       // Get all time slots
//       final allTimeSlots = restaurant.timeSlots.isNotEmpty 
//           ? restaurant.timeSlots 
//           : defaultTimeSlots;
      
//       // Filter out booked time slots
//       return allTimeSlots.where((slot) {
//         return table.isAvailable(date, slot);
//       }).toList();
//     } catch (e) {
//       debugPrint('Error getting available time slots: $e');
//       return [];
//     }
//   }

//   // Get available tables for a time slot and number of people
//   List<TableModel> getAvailableTables({
//     required String restaurantId,
//     required DateTime date,
//     required String timeSlot,
//     required int numberOfPeople,
//   }) {
//     try {
//       final restaurant = getRestaurantById(restaurantId);
//       if (restaurant == null) return [];
      
//       return restaurant.tables.where((table) {
//         return table.maxSeats >= numberOfPeople && 
//                table.isAvailable(date, timeSlot);
//       }).toList();
//     } catch (e) {
//       debugPrint('Error getting available tables: $e');
//       return [];
//     }
//   }

//   // Table operations
//   Future<Restaurant> addTableToRestaurant(String restaurantId, int maxSeats) async {
//     final restaurant = getRestaurantById(restaurantId);
//     if (restaurant == null) {
//       throw Exception('Restaurant not found');
//     }

//     final newTable = TableModel(
//       id: _uuid.v4(),
//       number: restaurant.tables.length + 1,
//       maxSeats: maxSeats,
//     );

//     final updatedTables = List<TableModel>.from(restaurant.tables)..add(newTable);
//     final updatedRestaurant = restaurant.copyWith(tables: updatedTables);
//     await updateRestaurant(updatedRestaurant);
    
//     return updatedRestaurant;
//   }

//   // Make a reservation
//   Future<void> makeReservation({
//     required String restaurantId,
//     required String tableId,
//     required String userId,
//     required DateTime date,
//     required String timeSlot,
//     required int numberOfPeople,
//     String? specialRequests,
//   }) async {
//     try {
//       final restaurant = getRestaurantById(restaurantId);
//       if (restaurant == null) {
//         throw Exception('Restaurant not found');
//       }

//       final table = restaurant.tables.firstWhere(
//         (t) => t.id == tableId,
//         orElse: () => throw Exception('Table not found'),
//       );

//       // Check if table is available
//       if (!table.isAvailable(date, timeSlot)) {
//         throw Exception('This table is no longer available for the selected time slot');
//       }

//       // Check if number of people exceeds table capacity
//       if (numberOfPeople > table.maxSeats) {
//         throw Exception('Number of people exceeds table capacity');
//       }

//       // Create reservation
//       final reservation = Reservation(
//         id: _uuid.v4(),
//         userId: userId,
//         tableId: tableId,
//         date: date,
//         timeSlot: timeSlot,
//         numberOfPeople: numberOfPeople,
//         specialRequests: specialRequests,
//         createdAt: DateTime.now(),
//       );

//       // Find the restaurant and table to update
//       final restaurantIndex = _restaurants.indexWhere((r) => r.id == restaurantId);
//       if (restaurantIndex == -1) {
//         throw Exception('Restaurant not found');
//       }

//       final tableIndex = _restaurants[restaurantIndex].tables.indexWhere((t) => t.id == tableId);
//       if (tableIndex == -1) {
//         throw Exception('Table not found');
//       }

//       // Add reservation
//       _restaurants[restaurantIndex].tables[tableIndex].reservations.add(reservation);
      
//       // Save changes
//       await _saveRestaurants();
      
//     } catch (e) {
//       debugPrint('Error making reservation: $e');
//       rethrow;
//     }
//   }

//   // User authentication
//   Future<bool> login(String email, String password) async {
//     try {
//       debugPrint('Attempting login for email: $email');
      
//       // Ensure users are loaded
//       await _loadData();
      
//       // Find user by email
//       final user = _users.firstWhere(
//         (u) => u.email.toLowerCase() == email.toLowerCase(),
//         orElse: () => user_model.User(id: '', name: '', email: ''),
//       );

//       // Check if user exists
//       if (user.id.isEmpty) {
//         debugPrint('User not found with email: $email');
//         return false;
//       }

//       // Check if user has a password (using the getter)
//       final userPassword = user.password;
//       if (userPassword == null || userPassword.isEmpty) {
//         debugPrint('No password set for user: $email');
//         return false;
//       }
      
//       // Simple password comparison (in a real app, use proper password hashing)
//       if (userPassword != password) {
//         debugPrint('Incorrect password for user: $email');
//         return false;
//       }

//       // Update current user and notify listeners
//       _currentUser = user;
//       notifyListeners();
      
//       debugPrint('User logged in successfully: ${user.email}');
//       return true;
      
//     } catch (e) {
//       debugPrint('Login error: $e');
//       rethrow;
//     }
//   }

//   Future<user_model.User> register(String name, String email, String password) async {
//     if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
//       throw Exception('Email already registered');
//     }

//     final newUser = user_model.User(
//       id: _uuid.v4(),
//       name: name,
//       email: email,
//       password: password,
//     );

//     _users.add(newUser);
//     _currentUser = newUser;
//     await _saveUsers();
    
//     return Future.value(newUser);
//   }

//   // Helper method to create a copy of a restaurant with updated fields
//   // ignore: unused_element
//   Restaurant _copyRestaurantWithUpdate(Restaurant original, {List<TableModel>? tables}) {
//     return Restaurant(
//       id: original.id,
//       name: original.name,
//       description: original.description,
//       imagePath: original.imagePath,
//       category: original.category,
//       tableCount: original.tableCount,
//       seatsPerTable: original.seatsPerTable,
//       timeSlots: original.timeSlots,
//       location: original.location,
//       tables: tables ?? original.tables,
//     );
//   }
// }

// // Extension to add copyWith method to Restaurant class
// extension RestaurantExtension on Restaurant {
//   Restaurant copyWith({
//     String? id,
//     String? name,
//     String? description,
//     String? imagePath,
//     String? category,
//     int? tableCount,
//     int? seatsPerTable,
//     List<String>? timeSlots,
//     Map<String, dynamic>? location,
//     List<TableModel>? tables,
//   }) {
//     return Restaurant(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       description: description ?? this.description,
//       imagePath: imagePath ?? this.imagePath,
//       category: category ?? this.category,
//       tableCount: tableCount ?? this.tableCount,
//       seatsPerTable: seatsPerTable ?? this.seatsPerTable,
//       timeSlots: timeSlots ?? this.timeSlots,
//       location: location ?? this.location,
//       tables: tables ?? this.tables,
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/restaurant.dart' hide User; // Hide User to avoid conflict
import '../models/user.dart' as user_model;   // Import with prefix
import 'category_service.dart';

class RestaurantService extends ChangeNotifier {
  static final RestaurantService _instance = RestaurantService._internal();
  factory RestaurantService() => _instance;

  RestaurantService._internal() {
    init();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _restaurantsRef =
      FirebaseFirestore.instance.collection('restaurants');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  final Uuid _uuid = const Uuid();
  final CategoryService _categoryService = CategoryService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  List<Restaurant> _restaurants = [];
  List<user_model.User> _users = [];
  user_model.User? _currentUser;

  static const List<String> defaultTimeSlots = [
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
  ];

  // ------------------ Initialization ------------------ //
  Future<void> init() async {
    if (!_isInitialized) {
      await loadUsers();
      await loadRestaurants();
      _isInitialized = true;
    }
  }

  // ------------------ Firestore Load ------------------ //
  Future<void> loadRestaurants() async {
    try {
      final snapshot = await _restaurantsRef.get();
      _restaurants = snapshot.docs
          .map((doc) =>
              Restaurant.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      notifyListeners();
      debugPrint('Loaded ${_restaurants.length} restaurants from Firestore');
    } catch (e) {
      debugPrint('Error loading restaurants: $e');
    }
  }

  Future<void> loadUsers() async {
    try {
      final snapshot = await _usersRef.get();
      _users = snapshot.docs
          .map((doc) => user_model.User.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // If no users, create default admin
      if (_users.isEmpty) {
        final admin = user_model.User(
          id: _uuid.v4(),
          name: 'Admin',
          email: 'admin@example.com',
          password: 'admin123',
          phoneNumber: '+1234567890',
        );
        _users.add(admin);
        await _usersRef.doc(admin.id).set(admin.toJson());
      }
      notifyListeners();
      debugPrint('Loaded ${_users.length} users from Firestore');
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  // ------------------ Restaurant CRUD ------------------ //
  Future<Restaurant> addRestaurant({
    required String name,
    required String description,
    required String imagePath,
    required String category,
    required int tableCount,
    required Map<String, dynamic> location,
    List<String>? timeSlots,
  }) async {
    final restaurantTimeSlots = timeSlots ?? List.from(defaultTimeSlots);

    // Create tables
    final tables = List<TableModel>.generate(
      tableCount,
      (index) => TableModel(
        id: _uuid.v4(),
        number: index + 1,
        maxSeats: 6,
      ),
    );

    final newRestaurant = Restaurant(
      id: _uuid.v4(),
      name: name,
      description: description,
      imagePath: imagePath,
      category: category,
      tableCount: tableCount,
      seatsPerTable: 6,
      timeSlots: restaurantTimeSlots,
      location: location,
      tables: tables,
    );

    _restaurants.add(newRestaurant);
    await _restaurantsRef.doc(newRestaurant.id).set(newRestaurant.toMap());
    notifyListeners();
    return newRestaurant;
  }

  Future<void> updateRestaurant(Restaurant updatedRestaurant) async {
    final index = _restaurants.indexWhere((r) => r.id == updatedRestaurant.id);
    if (index != -1) {
      _restaurants[index] = updatedRestaurant;
      await _restaurantsRef.doc(updatedRestaurant.id).set(updatedRestaurant.toMap());
      notifyListeners();
    }
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    _restaurants.removeWhere((r) => r.id == restaurantId);
    await _restaurantsRef.doc(restaurantId).delete();
    notifyListeners();
  }

  List<Restaurant> getAllRestaurants() => List.from(_restaurants);

  List<Restaurant> getRestaurantsByCategory(String category) =>
      _restaurants.where((r) => r.category == category).toList();

  List<String> getAllCategories() {
    final categories = _restaurants.map((r) => r.category).toSet().toList();
    return categories..sort();
  }

  Restaurant? getRestaurantById(String id) {
    try {
      return _restaurants.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  // ------------------ Table & Reservation ------------------ //
  List<TableModel> getAvailableTables({
    required String restaurantId,
    required DateTime date,
    required String timeSlot,
    required int numberOfPeople,
  }) {
    final restaurant = getRestaurantById(restaurantId);
    if (restaurant == null) return [];

    return restaurant.tables.where((table) {
      return table.maxSeats >= numberOfPeople && table.isAvailable(date, timeSlot);
    }).toList();
  }

  Future<void> makeReservation({
    required String restaurantId,
    required String tableId,
    required String userId,
    required DateTime date,
    required String timeSlot,
    required int numberOfPeople,
    String? specialRequests,
  }) async {
    final restaurant = getRestaurantById(restaurantId);
    if (restaurant == null) throw Exception('Restaurant not found');

    final tableIndex = restaurant.tables.indexWhere((t) => t.id == tableId);
    if (tableIndex == -1) throw Exception('Table not found');

    final table = restaurant.tables[tableIndex];
    
    // Check if the user already has a reservation for this table at this time
    final existingReservation = table.reservations.firstWhere(
      (r) => r.userId == userId && 
             r.tableId == tableId && 
             r.date == date && 
             r.timeSlot == timeSlot,
      orElse: () => Reservation(
        id: '',
        userId: '',
        tableId: '',
        date: DateTime.now(),
        timeSlot: '',
        numberOfPeople: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (existingReservation.id.isNotEmpty) {
      throw Exception('You have already booked this table for the selected time');
    }

    if (!table.isAvailable(date, timeSlot)) {
      throw Exception('Table not available for the selected time');
    }
    
    if (numberOfPeople > table.maxSeats) {
      throw Exception('Number of people exceeds table capacity');
    }

    final reservation = Reservation(
      id: _uuid.v4(),
      userId: userId,
      tableId: tableId,
      date: date,
      timeSlot: timeSlot,
      numberOfPeople: numberOfPeople,
      specialRequests: specialRequests,
      createdAt: DateTime.now(),
    );

    restaurant.tables[tableIndex].reservations.add(reservation);
    await updateRestaurant(restaurant);
  }

  // ------------------ User Auth ------------------ //
  Future<bool> login(String email, String password) async {
    final user = _users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => user_model.User(id: '', name: '', email: ''),
    );

    if (user.id.isEmpty) return false;
    if (user.password != password) return false;

    _currentUser = user;
    notifyListeners();
    return true;
  }

  Future<user_model.User> register(String name, String email, String password) async {
    if (_users.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      throw Exception('Email already registered');
    }

    final newUser = user_model.User(
      id: _uuid.v4(),
      name: name,
      email: email,
      password: password,
    );

    _users.add(newUser);
    _currentUser = newUser;
    await _usersRef.doc(newUser.id).set(newUser.toJson());
    notifyListeners();
    return newUser;
  }

  user_model.User? get currentUser => _currentUser;
  void setCurrentUser(user_model.User? user) {
    _currentUser = user;
    notifyListeners();
  }

  // ------------------ Category ------------------ //
  Future<List<String>> getCategories() async => await _categoryService.getCategories();
  Future<bool> addCategory(String category) async {
    final success = await _categoryService.addCategory(category);
    if (success) notifyListeners();
    return success;
  }

  Future<bool> removeCategory(String category) async {
    final success = await _categoryService.removeCategory(category);
    if (success) {
      for (var i = 0; i < _restaurants.length; i++) {
        if (_restaurants[i].category == category) {
          _restaurants[i] = _restaurants[i].copyWith(category: 'Uncategorized');
          await updateRestaurant(_restaurants[i]);
        }
      }
      notifyListeners();
    }
    return success;
  }
}

// Extension to allow copyWith for Restaurant
extension RestaurantExtension on Restaurant {
  Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? imagePath,
    String? category,
    int? tableCount,
    int? seatsPerTable,
    List<String>? timeSlots,
    Map<String, dynamic>? location,
    List<TableModel>? tables,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      tableCount: tableCount ?? this.tableCount,
      seatsPerTable: seatsPerTable ?? this.seatsPerTable,
      timeSlots: timeSlots ?? this.timeSlots,
      location: location ?? this.location,
      tables: tables ?? this.tables,
    );
  }
}
