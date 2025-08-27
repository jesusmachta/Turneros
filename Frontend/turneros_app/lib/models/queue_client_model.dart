/// Modelo para los clientes en las colas de espera y atención
class QueueClientModel {
  final String id;
  final int storeid;
  final String comesFrom;
  final int cedula;
  final String documento;
  final String country;
  final int turn;
  final String state;
  final DateTime createdAt;
  final String? attendedBy; // Para clientes siendo atendidos

  QueueClientModel({
    required this.id,
    required this.storeid,
    required this.comesFrom,
    required this.cedula,
    required this.documento,
    required this.country,
    required this.turn,
    required this.state,
    required this.createdAt,
    this.attendedBy,
  });

  factory QueueClientModel.fromJson(Map<String, dynamic> json) {
    return QueueClientModel(
      id: json['id'] ?? '',
      storeid: json['storeid'] ?? 0,
      comesFrom: json['comes_from'] ?? '',
      cedula: json['cedula'] ?? 0,
      documento: json['documento'] ?? '',
      country: json['country'] ?? '',
      turn: json['Turn'] ?? 0,
      state: json['state'] ?? '',
      createdAt: DateTime.parse(json['Created_At']),
      attendedBy: json['attendedBy'], // Puede ser null
    );
  }

  /// Crea un cliente desde datos de Firestore
  factory QueueClientModel.fromFirestore(Map<String, dynamic> data) {
    return QueueClientModel(
      id: data['id'] ?? '',
      storeid: data['storeid'] ?? 0,
      comesFrom: data['comes_from'] ?? '',
      cedula: data['cedula'] ?? 0,
      documento: data['documento'] ?? '',
      country: data['country'] ?? '',
      turn: data['Turn'] ?? 0,
      state: _parseFirestoreState(data['state']),
      createdAt: _parseFirestoreTimestamp(data['Created_At']),
      attendedBy: data['attendedBy'], // Puede ser null
    );
  }

  /// Convierte un estado de Firestore a String
  static String _parseFirestoreState(dynamic state) {
    if (state == null) return '';

    // Si es un número (como en PickingRX), convertir a string
    if (state is int) {
      return state.toString();
    }

    // Si es string, devolverlo tal como está
    if (state is String) {
      return state;
    }

    return state.toString();
  }

  /// Convierte un Timestamp de Firestore a DateTime
  static DateTime _parseFirestoreTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }

    // Si es un Timestamp de Firestore
    if (timestamp.runtimeType.toString().contains('Timestamp')) {
      return timestamp.toDate();
    }

    // Si es un String (formato ISO)
    if (timestamp is String) {
      return DateTime.parse(timestamp);
    }

    // Si es un Map con _seconds y _nanoseconds (formato serializado de Timestamp)
    if (timestamp is Map<String, dynamic>) {
      if (timestamp.containsKey('_seconds')) {
        final seconds = timestamp['_seconds'];
        final nanoseconds = timestamp['_nanoseconds'] ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanoseconds / 1000000).round(),
        );
      }
    }

    // Fallback
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeid': storeid,
      'comes_from': comesFrom,
      'cedula': cedula,
      'documento': documento,
      'country': country,
      'Turn': turn,
      'state': state,
      'Created_At': createdAt.toIso8601String(),
      'attendedBy': attendedBy,
    };
  }

  /// Determina si el cliente está en espera
  bool get isWaiting => state == 'Esperando';

  /// Determina si el cliente está siendo atendido
  bool get isAttending => state == 'Atendiendo';

  /// Obtiene el número de turno formateado
  String get formattedTurn {
    if (comesFrom.contains('Mostrador') || comesFrom.contains('Farmacia')) {
      return 'F-${turn.toString().padLeft(3, '0')}';
    } else if (comesFrom.contains('Inyectología') ||
        comesFrom.contains('Servicios')) {
      return 'S-${turn.toString().padLeft(2, '0')}';
    }
    return '#$turn';
  }

  /// Obtiene el nombre del cliente basado en la cédula
  String get clientName => 'Cliente $cedula';

  @override
  String toString() {
    return 'QueueClientModel(id: $id, cedula: $cedula, turn: $turn, state: $state)';
  }
}

/// Tipos de cola para organizar los clientes
enum QueueType {
  pharmacyWaiting, // Farmacia - En espera
  pharmacyAttending, // Farmacia - Siendo atendidos
  pharmaceuticalServicesWaiting, // Servicios Farmacéuticos - En espera
  pharmaceuticalServicesAttending, // Servicios Farmacéuticos - Siendo atendidos
  pickingRxPending, // Picking Rx - Pendiente (state = 0)
  pickingRxPrepared, // Picking Rx - Preparado (state = 1)
}
