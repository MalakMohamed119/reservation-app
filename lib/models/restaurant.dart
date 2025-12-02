class Restaurant {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final String category;
  final int tableCount;
  final int seatsPerTable; // This will be the same for all tables in the restaurant
  final List<String> timeSlots;
  final Map<String, dynamic> location; // {latitude: double, longitude: double}
  final List<TableModel> tables;

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.category,
    required this.tableCount,
    required this.seatsPerTable,
    required this.timeSlots,
    required this.location,
    required this.tables,
  });

  // Convert Restaurant object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'category': category,
      'tableCount': tableCount,
      'seatsPerTable': seatsPerTable,
      'timeSlots': timeSlots,
      'location': location,
      'tables': tables.map((table) => table.toMap()).toList(),
    };
  }

  // Create Restaurant object from Map
  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      imagePath: map['imagePath'],
      category: map['category'],
      tableCount: map['tableCount'],
      seatsPerTable: map['seatsPerTable'],
      timeSlots: List<String>.from(map['timeSlots']),
      location: Map<String, dynamic>.from(map['location']),
      tables: List<TableModel>.from(
          map['tables']?.map((x) => TableModel.fromMap(x)) ?? []),
    );
  }
}

class TableModel {
  static const int maxSeatsPerTable = 6;
  
  final String id;
  final int number;
  final int maxSeats;
  List<Reservation> reservations;

  TableModel({
    required this.id,
    required this.number,
    required int maxSeats,
    List<Reservation>? reservations,
  }) : maxSeats = maxSeats.clamp(1, maxSeatsPerTable),
       reservations = reservations ?? [];

  bool isAvailable(DateTime date, String timeSlot, {String? currentUserId}) {
    // Check if there's any reservation for this date and time slot
    bool isBooked = reservations.any((reservation) =>
        reservation.date == date && 
        reservation.timeSlot == timeSlot);
        
    // If there's no booking, it's available
    if (!isBooked) return true;
    
    // If there is a booking, check if it's by the current user
    if (currentUserId != null) {
      bool isBookedByCurrentUser = reservations.any((reservation) =>
          reservation.date == date && 
          reservation.timeSlot == timeSlot &&
          reservation.userId == currentUserId);
          
      // If it's booked by the current user, it's not available (prevent duplicate bookings)
      if (isBookedByCurrentUser) return false;
    }
    
    // Otherwise, it's booked by someone else
    return !isBooked;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'maxSeats': maxSeats,
      'reservations': reservations.map((r) => r.toMap()).toList(),
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    return TableModel(
      id: map['id'],
      number: map['number'],
      maxSeats: map['maxSeats'],
      reservations: List<Reservation>.from(
          map['reservations']?.map((x) => Reservation.fromMap(x)) ?? []),
    );
  }
}

class Reservation {
  final String id;
  final String userId;
  final String tableId;
  final DateTime date;
  final String timeSlot;
  final int numberOfPeople;
  final String? specialRequests;
  final DateTime createdAt;
  final bool isCancelled;

  const Reservation({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.date,
    required this.timeSlot,
    required this.numberOfPeople,
    this.specialRequests,
    required this.createdAt,
    this.isCancelled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tableId': tableId,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'numberOfPeople': numberOfPeople,
      'specialRequests': specialRequests,
      'createdAt': createdAt.toIso8601String(),
      'isCancelled': isCancelled,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      userId: map['userId'],
      tableId: map['tableId'],
      date: DateTime.parse(map['date']),
      timeSlot: map['timeSlot'],
      numberOfPeople: map['numberOfPeople'],
      specialRequests: map['specialRequests'],
      createdAt: DateTime.parse(map['createdAt']),
      isCancelled: map['isCancelled'] ?? false,
    );
  }

  // Create a copy of the reservation with updated fields
  Reservation copyWith({
    String? id,
    String? userId,
    String? tableId,
    DateTime? date,
    String? timeSlot,
    int? numberOfPeople,
    String? specialRequests,
    DateTime? createdAt,
    bool? isCancelled,
  }) {
    return Reservation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tableId: tableId ?? this.tableId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt ?? this.createdAt,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reservation &&
        other.id == id &&
        other.userId == userId &&
        other.tableId == tableId &&
        other.date == date &&
        other.timeSlot == timeSlot;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        tableId.hashCode ^
        date.hashCode ^
        timeSlot.hashCode;
  }

  @override
  String toString() {
    return 'Reservation(id: $id, userId: $userId, tableId: $tableId, date: $date, timeSlot: $timeSlot, numberOfPeople: $numberOfPeople, isCancelled: $isCancelled)';
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> favoriteRestaurants;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    List<String>? favoriteRestaurants,
  }) : favoriteRestaurants = favoriteRestaurants ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'favoriteRestaurants': favoriteRestaurants,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      favoriteRestaurants: List<String>.from(map['favoriteRestaurants'] ?? []),
    );
  }
}
