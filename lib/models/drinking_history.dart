import 'drink.dart';
import 'user.dart';

class DrinkingHistory {
  final int id;
  final int userId;
  final int drinkId;
  final int? addedById;
  final int quantity;
  final int pointsEarned;
  final DateTime consumedAt;
  final String? notes;
  final DateTime createdAt;
  final Drink? drink;
  final User? addedBy;

  DrinkingHistory({
    required this.id,
    required this.userId,
    required this.drinkId,
    this.addedById,
    required this.quantity,
    required this.pointsEarned,
    required this.consumedAt,
    this.notes,
    required this.createdAt,
    this.drink,
    this.addedBy,
  });

  factory DrinkingHistory.fromJson(Map<String, dynamic> json) {
    // added_by môže byť int (ID) alebo objekt (User) alebo null
    int? addedById;
    User? addedByUser;
    
    final addedByValue = json['added_by'];
    if (addedByValue is int) {
      addedById = addedByValue;
    } else if (addedByValue is Map<String, dynamic>) {
      addedByUser = User.fromJson(addedByValue);
      addedById = addedByUser.id;
    }
    
    // Ak nie je added_by objekt, skús added_by_user
    if (addedByUser == null && json['added_by_user'] != null) {
      addedByUser = User.fromJson(json['added_by_user']);
    }
    
    return DrinkingHistory(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'],
      drinkId: json['drink_id'] is String ? int.parse(json['drink_id']) : json['drink_id'],
      addedById: addedById,
      quantity: json['quantity'] is String ? int.parse(json['quantity']) : json['quantity'],
      pointsEarned: json['points_earned'] is String ? int.parse(json['points_earned']) : json['points_earned'],
      consumedAt: DateTime.parse(json['consumed_at']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      drink: json['drink'] != null ? Drink.fromJson(json['drink']) : null,
      addedBy: addedByUser,
    );
  }
}








