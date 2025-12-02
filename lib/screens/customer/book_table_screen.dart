import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:my_first_flutter_app/models/restaurant.dart';
import 'package:my_first_flutter_app/services/restaurant_service.dart';
import 'package:my_first_flutter_app/services/auth_service.dart';

class BookTableScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const BookTableScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<BookTableScreen> createState() => _BookTableScreenState();
}

class _BookTableScreenState extends State<BookTableScreen> {
  late Restaurant _restaurant;
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  int _selectedPeople = 2;
  String? _selectedTableId;
  final List<int> _peopleOptions = [1, 2, 3, 4, 5, 6];
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    setState(() => _isLoading = true);

    try {
      final restaurantService = context.read<RestaurantService>();
      final restaurant = restaurantService.getRestaurantById(widget.restaurantId);
      
      if (restaurant == null) {
        throw Exception('Restaurant not found');
      }
      
      setState(() {
        _restaurant = restaurant;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load restaurant: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDaySelected(DateTime selectedDate, DateTime focusedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _selectedTimeSlot = null;
      _selectedTableId = null; // Reset table selection when date changes
    });
  }

  Future<void> _onBookTable() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }
    
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a table')),
      );
      return;
    }

    final authService = context.read<AuthService>();
    if (authService.currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to book a table')),
        );
      }
      return;
    }

    setState(() => _isBooking = true);

    try {
      final restaurantService = context.read<RestaurantService>();
      
      // Find the selected table
      final table = _restaurant.tables.firstWhere(
        (table) => table.id == _selectedTableId,
        orElse: () => throw Exception('Selected table not found')
      );
      
      // Verify the table is still available
      if (!table.isAvailable(_selectedDate, _selectedTimeSlot!)) {
        throw Exception('The selected table is no longer available');
      }
      
      await restaurantService.makeReservation(
        restaurantId: _restaurant.id,
        tableId: table.id,
        userId: authService.currentUser!.id,
        date: _selectedDate,
        timeSlot: _selectedTimeSlot!,
        numberOfPeople: _selectedPeople,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table booked successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book table: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  List<String> _getAvailableTimeSlots() {
    if (_restaurant.timeSlots.isEmpty) return [];
    
    return _restaurant.timeSlots.where((slot) {
      // Check if any table is available for this slot
      return _restaurant.tables.any((table) => 
        table.maxSeats >= _selectedPeople && 
        table.isAvailable(_selectedDate, slot)
      );
    }).toList();
  }
  
  List<TableModel> _getAvailableTables() {
    if (_selectedTimeSlot == null) return [];
    
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUser?.id;
    
    return _restaurant.tables.where((table) => 
      table.maxSeats >= _selectedPeople && 
      table.isAvailable(
        _selectedDate, 
        _selectedTimeSlot!,
        currentUserId: currentUserId,
      )
    ).toList();
  }
  
  Widget _buildTableSelection() {
    if (_selectedTimeSlot == null) return const SizedBox.shrink();
    
    final availableTables = _getAvailableTables();
    final allTables = _restaurant.tables;
    final authService = context.read<AuthService>();
    final currentUserId = authService.currentUser?.id;
    
    if (allTables.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No tables available in this restaurant'),
      );
    }
    
    // Sort tables by number for consistent display
    allTables.sort((a, b) => a.number.compareTo(b.number));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Available Tables • ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${availableTables.length} of ${allTables.length} available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
          ),
          itemCount: allTables.length,
          itemBuilder: (context, index) {
            final table = allTables[index];
            final isAvailable = availableTables.contains(table);
            final isBookedByCurrentUser = !isAvailable && 
                table.reservations.any((r) => 
                    r.userId == currentUserId && 
                    r.timeSlot == _selectedTimeSlot &&
                    r.date.year == _selectedDate.year &&
                    r.date.month == _selectedDate.month &&
                    r.date.day == _selectedDate.day);
            
            return GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        _selectedTableId = table.id;
                      });
                    }
                  : null,
              child: Tooltip(
                message: isBookedByCurrentUser 
                    ? 'You have already booked this table' 
                    : !isAvailable ? 'This table is already booked' : 'Table ${table.number} (${table.maxSeats} seats)',
                child: Container(
                  decoration: BoxDecoration(
                    color: _selectedTableId == table.id
                        ? Theme.of(context).primaryColor
                        : isAvailable
                            ? Colors.green[50]
                            : isBookedByCurrentUser
                                ? Colors.orange[300]
                                : Colors.grey[400],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: _selectedTableId == table.id
                          ? Theme.of(context).primaryColor
                          : isBookedByCurrentUser
                              ? Colors.orange[700] ?? Colors.orange
                              : Colors.transparent,
                      width: _selectedTableId == table.id || isBookedByCurrentUser ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (_selectedTableId == table.id || isBookedByCurrentUser)
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            size: 32,
                            color: _selectedTableId == table.id
                                ? Colors.white
                                : isBookedByCurrentUser
                                    ? Colors.white
                                    : isAvailable
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                          ),
                          if (isBookedByCurrentUser)
                            const Positioned(
                              top: 0,
                              right: 4,
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Table ${table.number}',
                        style: TextStyle(
                          color: _selectedTableId == table.id
                              ? Colors.white
                              : isBookedByCurrentUser
                                  ? Colors.white
                                  : isAvailable
                                      ? Colors.black87
                                      : Colors.white,
                          fontWeight: _selectedTableId == table.id || isBookedByCurrentUser
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (!isAvailable) ...[
                        const SizedBox(height: 2),
                        Text(
                          isBookedByCurrentUser ? 'Your Booking' : 'Booked',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Table at ${widget.restaurantName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Calendar
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 30)),
                        focusedDay: _selectedDate,
                        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                        onDaySelected: _onDaySelected,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Number of People
                  Text(
                    'Number of People',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedPeople,
                    items: _peopleOptions
                        .map((count) => DropdownMenuItem(
                              value: count,
                              child: Text('$count ${count == 1 ? 'person' : 'people'}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPeople = value;
                          _selectedTimeSlot = null; // Reset time slot when people count changes
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Available Time Slots
                  Text(
                    'Available Time Slots',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildTimeSlotsGrid(),
                  
                  if (_selectedTimeSlot != null) _buildTableSelection(),
                  
                  const SizedBox(height: 20),
                  
                  // Book Now Button
                  ElevatedButton(
                    onPressed: _isBooking ? null : _onBookTable,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isBooking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Book Now'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeSlotsGrid() {
    final availableSlots = _getAvailableTimeSlots();
    
    if (availableSlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No available time slots for the selected date'),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableSlots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        return FilterChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedTimeSlot = selected ? slot : null;
            });
          },
          backgroundColor: Colors.grey[200],
          selectedColor: Theme.of(context).primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
          ),
        );
      }).toList(),
    );
  }
}
