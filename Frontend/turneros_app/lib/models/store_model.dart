/// Modelo de datos para la información de la tienda
class StoreInfo {
  final int storeId;
  final String country;
  final String storeName;
  final String coordenada;
  final String area;
  final String region;

  StoreInfo({
    required this.storeId,
    required this.country,
    required this.storeName,
    required this.coordenada,
    required this.area,
    required this.region,
  });

  /// Crea una instancia desde JSON recibido de la API
  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      storeId: json['storeid'] ?? 0,
      country: json['country'] ?? '',
      storeName: json['storename'] ?? '',
      coordenada: json['coordenada'] ?? '',
      area: json['area'] ?? '',
      region: json['region'] ?? '',
    );
  }

  /// Convierte a Map para guardar en Firebase
  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'country': country,
      'storeName': storeName,
      'coordenada': coordenada,
      'area': area,
      'region': region,
    };
  }

  @override
  String toString() {
    return 'StoreInfo(storeId: $storeId, storeName: $storeName, country: $country)';
  }
}
