class Drink {
  final int id;
  final String name;
  final double alcoholPercentage;
  final int pointsPerUnit;
  final String unit;
  final int? volumeMl;
  final String? description;
  final bool active;

  Drink({
    required this.id,
    required this.name,
    required this.alcoholPercentage,
    required this.pointsPerUnit,
    required this.unit,
    this.volumeMl,
    this.description,
    required this.active,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    // Parsovať alcohol_percentage - môže prísť ako string alebo num
    double parseAlcoholPercentage(dynamic value) {
      if (value is num) {
        return value.toDouble();
      } else if (value is String) {
        return double.parse(value);
      } else {
        return 0.0;
      }
    }

    return Drink(
      id: json['id'],
      name: json['name'],
      alcoholPercentage: parseAlcoholPercentage(json['alcohol_percentage']),
      pointsPerUnit: json['points_per_unit'] is int 
          ? json['points_per_unit'] 
          : int.parse(json['points_per_unit'].toString()),
      unit: json['unit'],
      volumeMl: json['volume_ml'] == null 
          ? null 
          : (json['volume_ml'] is int 
              ? json['volume_ml'] 
              : int.parse(json['volume_ml'].toString())),
      description: json['description'],
      active: json['active'] == null 
          ? true 
          : (json['active'] is bool 
              ? json['active'] 
              : json['active'].toString().toLowerCase() == 'true'),
    );
  }
}






