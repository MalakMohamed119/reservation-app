import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_first_flutter_app/services/auth_service.dart';
import 'package:my_first_flutter_app/services/restaurant_service.dart';
import 'package:my_first_flutter_app/services/category_service.dart';
import 'package:my_first_flutter_app/models/restaurant.dart';
import 'package:my_first_flutter_app/screens/customer/restaurant_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<Restaurant> _restaurants = [];
  List<String> _categories = [];
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final restaurantService = context.read<RestaurantService>();
      final categoryService = CategoryService();
      
      // Load restaurants and categories in parallel
      final restaurants = await restaurantService.getAllRestaurants();
      final categories = await categoryService.getCategories();
      
      if (mounted) {
        setState(() {
          _restaurants = restaurants;
          _categories = categories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Restaurant> get _filteredRestaurants {
    if (_searchQuery.isEmpty && _selectedCategory == null) {
      return _restaurants;
    }
    
    return _restaurants.where((restaurant) {
      final name = restaurant.name?.toLowerCase() ?? '';
      final description = restaurant.description?.toLowerCase() ?? '';
      final category = restaurant.category?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      final matchesSearch = query.isEmpty || 
          name.contains(query) || 
          description.contains(query);
      
      final matchesCategory = _selectedCategory == null || 
          category == _selectedCategory?.toLowerCase();
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  void _onCategorySelected(String? category) {
    setState(() {
      _selectedCategory = category == _selectedCategory ? null : category;
      // Clear search when changing categories for better UX
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  Future<void> _handleLogout() async {
    final authService = context.read<AuthService>();
    try {
      await authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search restaurants...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),

                // Categories
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    children: [
                      const SizedBox(width: 8.0),
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => _onCategorySelected(null),
                      ),
                      ..._categories.map((category) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (_) => _onCategorySelected(category),
                            ),
                          )),
                    ],
                  ),
                ),
                const Divider(),

                // Restaurants List
                Expanded(
                  child: _filteredRestaurants.isEmpty
                      ? Center(
                          child: Text(
                            'No restaurants found',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                          ),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return Card(
                              elevation: 2,
                              child: InkWell(
                                onTap: () {
                                  if (restaurant.id != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RestaurantDetailScreen(
                                          restaurantId: restaurant.id!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: restaurant.imagePath?.isNotEmpty == true
                                          ? Image.network(
                                              restaurant.imagePath,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, size: 50),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.restaurant, size: 50),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            restaurant.name?.isNotEmpty == true 
                                                ? restaurant.name 
                                                : 'Unnamed Restaurant',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            restaurant.category?.isNotEmpty == true 
                                                ? restaurant.category
                                                : 'No Category',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
