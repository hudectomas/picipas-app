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
    return DrinkingHistory(
      id: json['id'],
      userId: json['user_id'],
      drinkId: json['drink_id'],
      addedById: json['added_by'],
      quantity: json['quantity'],
      pointsEarned: json['points_earned'],
      consumedAt: DateTime.parse(json['consumed_at']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      drink: json['drink'] != null ? Drink.fromJson(json['drink']) : null,
      addedBy: json['added_by_user'] != null ? User.fromJson(json['added_by_user']) : null,
    );
  }
}








