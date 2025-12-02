// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:my_first_flutter_app/models/restaurant.dart';
// import 'package:my_first_flutter_app/services/restaurant_service.dart';
// import 'package:my_first_flutter_app/services/auth_service.dart';
// import 'package:my_first_flutter_app/widgets/restaurant_card.dart';

// class CustomerHomeScreen extends StatefulWidget {
//   const CustomerHomeScreen({super.key});

//   @override
//   State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
// }

// class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   List<Restaurant> _restaurants = [];
//   List<Restaurant> _filteredRestaurants = [];
//   List<String> _categories = [];
//   String? _selectedCategory;
//   bool _isLoading = true;
//   final FocusNode _searchFocusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     debugPrint('🚀 CustomerHomeScreen initialized');
//     _checkAuthAndLoadData();
//     _searchController.addListener(_onSearchChanged);
//   }

//   void _onSearchChanged() {
//     _filterRestaurants(_searchController.text);
//   }

//   Future<void> _checkAuthAndLoadData() async {
//     debugPrint('🔍 Checking authentication status...');
//     try {
//       final restaurantService = context.read<RestaurantService>();
//       debugPrint('🔄 Initializing RestaurantService...');
//       await restaurantService.init(); 

//       if (!mounted) {
//         debugPrint('⚠️ Widget not mounted after service init');
//         return;
//       }

//       debugPrint('📥 Loading restaurants...');
//       await _loadRestaurants();
//       debugPrint('👤 Current user: ${restaurantService.currentUser?.email ?? "Not logged in"}');
//     } catch (e) {
//       debugPrint('Error in _checkAuthAndLoadData: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Error loading data. Please try again.'),
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.removeListener(_onSearchChanged);
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     super.dispose();
//   }

//   Future<void> _loadRestaurants() async {
//     if (!mounted) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final restaurantService = context.read<RestaurantService>();
//       final restaurants = restaurantService.getAllRestaurants();
//       final categories = restaurantService.getAllCategories();

//       if (mounted) {
//         setState(() {
//           _restaurants = List.from(restaurants);
//           _filteredRestaurants = List.from(restaurants);
//           _categories = List.from(categories);
//           _filterRestaurants(_searchController.text); 
//           debugPrint('Loaded ${_restaurants.length} restaurants');
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading restaurants: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Error loading restaurants. Please try again.'),
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _filterRestaurants(String query) {
//     setState(() {
//       final queryLower = query.toLowerCase();
//       Iterable<Restaurant> baseList = _selectedCategory == null
//           ? _restaurants
//           : _restaurants.where((r) => r.category == _selectedCategory);

//       if (query.isEmpty) {
//         _filteredRestaurants = baseList.toList();
//       } else {
//         _filteredRestaurants = baseList.where((restaurant) {
//           final nameMatch = restaurant.name.toLowerCase().contains(queryLower);
//           final descriptionMatch = restaurant.description.toLowerCase().contains(queryLower);
//           final categoryMatch = restaurant.category.toLowerCase().contains(queryLower); 
//           return nameMatch || categoryMatch || descriptionMatch;
//         }).toList();
//       }
//     });
//   }

//   void _filterByCategory(String? category) {
//     setState(() {
//       _selectedCategory = category;
//       final query = _searchController.text;
//       Iterable<Restaurant> categoryFiltered = category == null
//           ? _restaurants
//           : _restaurants.where((restaurant) => restaurant.category == category);

//       if (query.isEmpty) {
//         _filteredRestaurants = categoryFiltered.toList();
//       } else {
//         final queryLower = query.toLowerCase();
//         _filteredRestaurants = categoryFiltered.where((restaurant) {
//           final nameMatch = restaurant.name.toLowerCase().contains(queryLower);
//           final descriptionMatch = restaurant.description.toLowerCase().contains(queryLower);
//           final categoryMatch = restaurant.category.toLowerCase().contains(queryLower);
//           return nameMatch || categoryMatch || descriptionMatch;
//         }).toList();
//       }
//     });
//   }

//   Future<void> _handleLogout() async {
//     final authService = context.read<AuthService>(); 
//     await authService.logout();
//     if (mounted) {
//       Navigator.pushNamedAndRemoveUntil(
//         context,
//         '/role-selection',
//         (route) => false,
//       );
//     }
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.restaurant_menu,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'No restaurants available',
//             style: TextStyle(fontSize: 16, color: Colors.grey),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Please try again later',
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRestaurantGrid() {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: TextField(
//             controller: _searchController,
//             decoration: InputDecoration(
//               hintText: 'Search restaurants...',
//               prefixIcon: const Icon(Icons.search),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10.0),
//               ),
//               filled: true,
//               fillColor: Colors.grey[100],
//             ),
//             onChanged: (value) {
//               _filterRestaurants(value);
//             },
//           ),
//         ),
//         if (_categories.isNotEmpty) ...[
//           SizedBox(
//             height: 50,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               itemCount: _categories.length + 1,
//               itemBuilder: (context, index) {
//                 if (index == 0) {
//                   return Padding(
//                     padding: const EdgeInsets.only(right: 8.0),
//                     child: FilterChip(
//                       label: const Text('All'),
//                       selected: _selectedCategory == null,
//                       onSelected: (_) => _filterByCategory(null),
//                     ),
//                   );
//                 }
//                 final category = _categories[index - 1];
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8.0),
//                   child: FilterChip(
//                     label: Text(category),
//                     selected: _selectedCategory == category,
//                     onSelected: (_) => _filterByCategory(category),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const SizedBox(height: 8),
//         ],
//         Expanded(
//           child: GridView.builder(
//             padding: const EdgeInsets.all(16),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2,
//               childAspectRatio: 0.8,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//             ),
//             itemCount: _filteredRestaurants.length,
//             itemBuilder: (context, index) {
//               final restaurant = _filteredRestaurants[index];
//               return RestaurantCard(
//                 restaurant: restaurant,
//                 onTap: () {
//                   Navigator.pushNamed(context, '/restaurant/${restaurant.id}');
//                 },
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         Navigator.pop(context);
//         return false;
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => Navigator.pop(context),
//           ),
//           title: const Text('Restaurants'),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.logout),
//               onPressed: _handleLogout,
//             ),
//           ],
//         ),
//         body: _isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : _filteredRestaurants.isEmpty
//                 ? _buildEmptyState()
//                 : _buildRestaurantGrid(),
//       ),
//     );
//   }
// }


