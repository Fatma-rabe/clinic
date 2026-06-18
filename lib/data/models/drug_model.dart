import 'package:equatable/equatable.dart';

class DrugModel extends Equatable {
  const DrugModel({
    required this.commercialNameEn,
    required this.commercialNameAr,
    required this.scientificName,
    required this.manufacturer,
    required this.drugClass,
    required this.route,
    required this.priceEgp,
  });

  final String commercialNameEn;
  final String commercialNameAr;
  final String scientificName;
  final String manufacturer;
  final String drugClass;
  final String route;
  final double priceEgp;

  factory DrugModel.fromJson(Map<String, dynamic> json) {
    return DrugModel(
      commercialNameEn: json['commercial_name_en'] as String? ?? '',
      commercialNameAr: json['commercial_name_ar'] as String? ?? '',
      scientificName: json['scientific_name'] as String? ?? '',
      manufacturer: json['manufacturer'] as String? ?? '',
      drugClass: json['drug_class'] as String? ?? '',
      route: json['route'] as String? ?? '',
      priceEgp: (json['price_egp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'commercial_name_en': commercialNameEn,
        'commercial_name_ar': commercialNameAr,
        'scientific_name': scientificName,
        'manufacturer': manufacturer,
        'drug_class': drugClass,
        'route': route,
        'price_egp': priceEgp,
      };

  @override
  List<Object?> get props => [
        commercialNameEn,
        commercialNameAr,
        scientificName,
        manufacturer,
        drugClass,
        route,
        priceEgp,
      ];
}
