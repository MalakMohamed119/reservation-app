import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_first_flutter_app/models/restaurant.dart';
import 'package:my_first_flutter_app/services/restaurant_service.dart';
import 'package:intl/intl.dart';





// Color constants for B&W theme consistency
const Color primaryBlack = Colors.black;
const Color primaryWhite = Colors.white;
const Color lightGray = Color(0xFFE0E0E0); // Lighter gray for backgrounds/dividers
const Color mediumGray = Colors.grey; // Medium gray for secondary text/icons
const Color accentBlack = Color(0xFF1E1E1E); // Slightly off-black for card background
const Color actionBlue = Color(0xFF007AFF); // A touch of color for action/notification

class BookedTablesScreen extends StatefulWidget {
  final String restaurantId;

  const BookedTablesScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<BookedTablesScreen> createState() => _BookedTablesScreenState();
}

class _BookedTablesScreenState extends State<BookedTablesScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  List<Reservation> _reservations = [];
  bool _isLoading = false;
  Restaurant? _restaurant;
  final double borderRadius = 8.0;

  @override
  void initState() {
    super.initState();
    _loadRestaurantAndReservations();
  }

  Future<void> _loadRestaurantAndReservations() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final restaurantService = context.read<RestaurantService>();
      // NOTE: Assuming getRestaurantById and models (Restaurant, TableModel, Reservation) are available in the project structure
      // The implementation for getRestaurantById is not shown, but we assume it works.
      _restaurant = restaurantService.getRestaurantById(widget.restaurantId);
      
      if (_restaurant != null) {
        // Get all reservations for this restaurant
        _reservations = [];
        for (var table in _restaurant!.tables) {
          // This assumes `table` has a `reservations` property and is of type TableModel
          // Since TableModel definition is missing, this is kept as-is, assuming it works.
          _reservations.addAll(table.reservations); 
        }
        // Sort by date and time
        _reservations.sort((a, b) => 
            a.date.compareTo(b.date) != 0 
                ? a.date.compareTo(b.date) 
                : a.timeSlot.compareTo(b.timeSlot));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reservations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Reservation> get _filteredReservations {
    // Filter logic remains unchanged
    if (_selectedTimeSlot == null) {
      return _reservations.where((r) => 
          r.date.year == _selectedDate.year &&
          r.date.month == _selectedDate.month &&
          r.date.day == _selectedDate.day).toList();
    }
    return _reservations.where((r) => 
        r.date.year == _selectedDate.year &&
        r.date.month == _selectedDate.month &&
        r.date.day == _selectedDate.day &&
        r.timeSlot == _selectedTimeSlot).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryWhite, // ⭐️ UI CHANGE: White background
      appBar: AppBar(
        // ⭐️ UI CHANGE: B&W AppBar
        title: const Text('Booked Tables', style: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold)),
        backgroundColor: primaryWhite,
        foregroundColor: primaryBlack,
        elevation: 1, // Slight elevation to separate from content
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryBlack),
            onPressed: _loadRestaurantAndReservations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlack)) // ⭐️ UI CHANGE: Black indicator
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_restaurant == null) {
      return const Center(child: Text('Restaurant not found', style: TextStyle(color: primaryBlack)));
    }

    return Column(
      children: [
        // Date Picker
        _buildDateSelector(),
        
        // Time Slot Filter
        _buildTimeSlotFilter(),

        const Divider(height: 1, color: lightGray), // ⭐️ UI CHANGE: Divider
        
        // Reservations List
        Expanded(
          child: _filteredReservations.isEmpty
              ? _buildEmptyState()
              : _buildReservationsList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: lightGray, // ⭐️ UI CHANGE: Light gray background for selector
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20, color: primaryBlack), // ⭐️ UI CHANGE: Black icon
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, MMM d, y').format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryBlack, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton(
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow looking back for bookings
                lastDate: DateTime.now().add(const Duration(days: 365)), // Allow looking far ahead
                // ⭐️ UI CHANGE: DatePicker Theme
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: primaryBlack, // Header background/selected date color
                        onPrimary: primaryWhite, // Header text/selected date text color
                        onSurface: primaryBlack, // Picker text color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: primaryBlack), // Dialog button color
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null && pickedDate != _selectedDate) {
                setState(() {
                  _selectedDate = pickedDate;
                  _selectedTimeSlot = null;
                });
              }
            },
            child: const Text('Change Date', style: TextStyle(color: primaryBlack, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotFilter() {
    if (_restaurant == null || _restaurant!.timeSlots.isEmpty) {
      return Container();
    }

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // All time slots option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              // ⭐️ UI CHANGE: B&W ChoiceChip for 'All'
              label: const Text('All', style: TextStyle(color: primaryBlack)),
              selected: _selectedTimeSlot == null,
              selectedColor: primaryBlack, // Selected color is black
              backgroundColor: lightGray, // Unselected color is light gray
              labelStyle: TextStyle(
                color: _selectedTimeSlot == null ? primaryWhite : primaryBlack, // Text is white when selected
                fontWeight: FontWeight.bold,
              ),
              onSelected: (selected) {
                setState(() => _selectedTimeSlot = null);
              },
            ),
          ),
          // Time slot options
          ..._restaurant!.timeSlots.map((slot) {
            final isSelected = _selectedTimeSlot == slot;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                // ⭐️ UI CHANGE: B&W ChoiceChip for Slots
                label: Text(slot),
                selected: isSelected,
                selectedColor: primaryBlack, // Selected color is black
                backgroundColor: lightGray, // Unselected color is light gray
                labelStyle: TextStyle(
                  color: isSelected ? primaryWhite : primaryBlack, // Text is white when selected
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() => _selectedTimeSlot = selected ? slot : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = _filteredReservations[index];
        // NOTE: This logic assumes TableModel exists and handles the fallback.
        final table = _restaurant!.tables.firstWhere(
          (t) => t.id == reservation.tableId,
          // Assuming TableModel constructor needs id, number, and maxSeats
          orElse: () => TableModel(id: 'unknown', number: 0, maxSeats: 0, reservations: []),
        );
        
        return Card(
          // ⭐️ UI CHANGE: B&W Card
          color: accentBlack, // Darker card background
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            leading: const Icon(Icons.table_restaurant, size: 32, color: primaryWhite), // ⭐️ UI CHANGE: White icon
            title: Text(
              'Table ${table.number}', 
              style: const TextStyle(color: primaryWhite, fontWeight: FontWeight.bold), // ⭐️ UI CHANGE: White text
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time: ${reservation.timeSlot}', style: const TextStyle(color: lightGray)),
                Text('Guests: ${reservation.numberOfPeople}', style: const TextStyle(color: lightGray)),
                Text(
                  'Booked on: ${DateFormat('MMM d, y - h:mm a').format(reservation.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mediumGray, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 64,
            color: primaryBlack.withOpacity(0.3), // ⭐️ UI CHANGE: Faded black icon
          ),
          const SizedBox(height: 16),
          Text(
            'No Bookings Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primaryBlack, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'No tables are booked for the selected date${_selectedTimeSlot != null ? ' and time' : ''}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mediumGray),
            ),
          ),
        ],
      ),
    );
  }
}
