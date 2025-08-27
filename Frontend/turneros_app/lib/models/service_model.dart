class ServiceModel {
  final bool sms;
  final bool active;
  final bool screen;
  final String name;
  final String type;
  final String iconUrl;

  ServiceModel({
    required this.sms,
    required this.active,
    required this.screen,
    required this.name,
    required this.type,
    required this.iconUrl,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      sms: json['SMS'] ?? false,
      active: json['active'] ?? false,
      screen: json['screen'] ?? false,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
    );
  }

  /// Crea un servicio desde datos de Firestore
  factory ServiceModel.fromFirestore(Map<String, dynamic> data) {
    return ServiceModel(
      sms: data['SMS'] ?? false,
      active: data['active'] ?? false,
      screen: data['screen'] ?? false,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SMS': sms,
      'active': active,
      'screen': screen,
      'name': name,
      'type': type,
      'iconUrl': iconUrl,
    };
  }

  @override
  String toString() {
    return 'ServiceModel(name: $name, type: $type, active: $active)';
  }
}
