import 'package:flutter/foundation.dart';

/// Modelo para los datos de turnos en el sistema
class TurnModel {
  final String id;
  final int storeId;
  final String comesFrom;
  final int cedula;
  final String documento;
  final String country;
  final int turn;
  final String state;
  final DateTime createdAt;
  final DateTime? servedAt;

  TurnModel({
    required this.id,
    required this.storeId,
    required this.comesFrom,
    required this.cedula,
    required this.documento,
    required this.country,
    required this.turn,
    required this.state,
    required this.createdAt,
    this.servedAt,
  });

  /// Crea un turno desde JSON
  factory TurnModel.fromJson(Map<String, dynamic> json) {
    return TurnModel(
      id: json['id'] ?? '',
      storeId: json['storeid'] ?? 0,
      comesFrom: json['comes_from'] ?? '',
      cedula: json['cedula'] ?? 0,
      documento: json['documento'] ?? '',
      country: json['country'] ?? '',
      turn: json['Turn'] ?? 0,
      state: json['state'] ?? '',
      createdAt: DateTime.parse(json['Created_At']),
      servedAt:
          json['Served_At'] != null ? DateTime.parse(json['Served_At']) : null,
    );
  }

  /// Crea un turno desde datos de Firestore
  factory TurnModel.fromFirestore(Map<String, dynamic> data) {
    return TurnModel(
      id: data['id'] ?? '',
      storeId: data['storeid'] ?? 0,
      comesFrom: data['comes_from'] ?? '',
      cedula: data['cedula'] ?? 0,
      documento: data['documento'] ?? '',
      country: data['country'] ?? '',
      turn: data['Turn'] ?? 0,
      state: data['state'] ?? '',
      createdAt: _parseFirestoreTimestamp(data['Created_At']),
      servedAt:
          data['Served_At'] != null
              ? _parseFirestoreTimestamp(data['Served_At'])
              : null,
    );
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

  /// Convierte a Map para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeid': storeId,
      'comes_from': comesFrom,
      'cedula': cedula,
      'documento': documento,
      'country': country,
      'Turn': turn,
      'state': state,
      'Created_At': createdAt.toIso8601String(),
      'Served_At': servedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TurnModel(id: $id, turn: $turn, state: $state, comesFrom: $comesFrom)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TurnModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Modelo para la información de turnos de una pantalla específica
class TurnScreenData {
  final TurnModel? currentlyBeingServed;
  final List<TurnModel> waitingQueue;

  TurnScreenData({this.currentlyBeingServed, required this.waitingQueue});

  /// Crear una instancia vacía
  factory TurnScreenData.empty() {
    return TurnScreenData(currentlyBeingServed: null, waitingQueue: []);
  }

  @override
  String toString() {
    return 'TurnScreenData(currentlyBeingServed: $currentlyBeingServed, waitingQueue: ${waitingQueue.length} items)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TurnScreenData &&
        other.currentlyBeingServed == currentlyBeingServed &&
        listEquals(other.waitingQueue, waitingQueue);
  }

  @override
  int get hashCode => Object.hash(currentlyBeingServed, waitingQueue);
}
