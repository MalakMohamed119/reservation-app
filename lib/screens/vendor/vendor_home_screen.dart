import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:my_first_flutter_app/models/restaurant.dart';
import 'package:my_first_flutter_app/services/restaurant_service.dart';
import 'package:my_first_flutter_app/widgets/restaurant_card.dart';
import 'package:my_first_flutter_app/screens/vendor/manage_categories_screen.dart';

const Color primaryBlack = Colors.black;
const Color primaryWhite = Colors.white;
const Color lightGray = Colors.grey;

class VendorHomeScreen extends StatefulWidget {
  const VendorHomeScreen({super.key});

  @override
  State<VendorHomeScreen> createState() => _VendorHomeScreenState();
}

class _VendorHomeScreenState extends State<VendorHomeScreen> {
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final restaurantService = Provider.of<RestaurantService>(context, listen: false);
      final restaurants = restaurantService.getAllRestaurants();
      setState(() {
        _restaurants = restaurants;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurants: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/role-selection');
        return false;
      },
      child: Scaffold(
        backgroundColor: primaryWhite,
        appBar: AppBar(
          backgroundColor: primaryWhite,
          foregroundColor: primaryBlack,
          elevation: 0,
          title: const Text('My Restaurants', style: TextStyle(color: primaryBlack)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryBlack),
            onPressed: () => Navigator.pushReplacementNamed(context, '/role-selection'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.category, color: primaryBlack),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageCategoriesScreen(),
                  ),
                );
              },
              tooltip: 'Manage Categories',
            ),
            // 🔹 Replaced Refresh button with Add Restaurant button
            IconButton(
              icon: const Icon(Icons.add, color: primaryBlack),
              onPressed: () {
                Navigator.pushNamed(context, '/vendor/add-restaurant');
              },
              tooltip: 'Add Restaurant',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryBlack))
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: primaryBlack.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Restaurants Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryBlack,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first restaurant to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: lightGray,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/vendor/add-restaurant');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlack,
                foregroundColor: primaryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryBlack,
      onRefresh: _loadRestaurants,
      child: _buildRestaurantList(),
    );
  }

  Widget _buildRestaurantList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _restaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _restaurants[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RestaurantCard(
            restaurant: restaurant,
            showViewBookings: true,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/vendor/edit-restaurant',
                arguments: restaurant.id,
              );
            },
          ),
        );
      },
    );
  }
}
