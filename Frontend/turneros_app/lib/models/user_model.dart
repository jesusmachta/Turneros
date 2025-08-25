/// Modelo de usuario para el sistema
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLogin;

  // Datos de la tienda guardados directamente
  final int? storeId;
  final String? country;
  final String? storeName;
  final String? coordenada;
  final String? area;
  final String? region;
  final String? rol;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    required this.createdAt,
    this.lastLogin,
    this.storeId,
    this.country,
    this.storeName,
    this.coordenada,
    this.area,
    this.region,
    this.rol,
  });

  /// Crea un usuario desde datos de Firebase Auth y datos de la tienda
  factory UserModel.fromAuthAndStore({
    required String uid,
    required String email,
    required String displayName,
    String? photoURL,
    required int storeId,
    required String country,
    required String storeName,
    required String coordenada,
    required String area,
    required String region,
    String? rol,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      storeId: storeId,
      country: country,
      storeName: storeName,
      coordenada: coordenada,
      area: area,
      region: region,
      rol: rol ?? 'Tienda',
    );
  }

  /// Convierte a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      // Datos de la tienda directamente en el documento
      'storeId': storeId,
      'country': country,
      'storeName': storeName,
      'coordenada': coordenada,
      'area': area,
      'region': region,
      'rol': rol,
    };
  }

  /// Crea un usuario desde Map de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin:
          map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      // Datos de la tienda desde el documento directamente
      storeId: map['storeId'],
      country: map['country'],
      storeName: map['storeName'],
      coordenada: map['coordenada'],
      area: map['area'],
      region: map['region'],
      rol: map['rol'],
    );
  }

  /// Crea una copia con campos actualizados
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? storeId,
    String? country,
    String? storeName,
    String? coordenada,
    String? area,
    String? region,
    String? rol,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      storeId: storeId ?? this.storeId,
      country: country ?? this.country,
      storeName: storeName ?? this.storeName,
      coordenada: coordenada ?? this.coordenada,
      area: area ?? this.area,
      region: region ?? this.region,
      rol: rol ?? this.rol,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, storeName: $storeName)';
  }
}
