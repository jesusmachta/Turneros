import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/queue_client_model.dart';
import '../models/service_model.dart';

/// Servicio para manejar las operaciones de las colas con el backend
class QueueService {
  // URLs de los endpoints reales
  static const String _pharmacyWaitingUrl =
      'https://waitingpharmacy-228344336816.us-central1.run.app/';
  static const String _pharmacyAttendingUrl =
      'https://attendigpharmacy-228344336816.us-central1.run.app/';
  static const String _servicesWaitingUrl =
      'https://waitinginservices-228344336816.us-central1.run.app/';
  static const String _servicesAttendingUrl =
      'https://attendingservices-228344336816.us-central1.run.app/';

  // URLs para las acciones de los botones
  static const String _startAttendingPharmacyUrl =
      'https://startattendingpharmacy-228344336816.us-central1.run.app';
  static const String _startAttendingServiceUrl =
      'https://startattendingservice-228344336816.us-central1.run.app';
  static const String _finishAttendingPharmacyUrl =
      'https://finishattendingpharmacy-228344336816.us-central1.run.app';
  static const String _finishAttendingServiceUrl =
      'https://finishattendingservice-228344336816.us-central1.run.app';
  static const String _cancelTurnPharmacyUrl =
      'https://cancelturnpharmacy-228344336816.us-central1.run.app';
  static const String _cancelTurnServiceUrl =
      'https://cancelturnservice-228344336816.us-central1.run.app';

  // URLs para servicios activos y transferencias
  static const String _activeServicesUrl =
      'https://activeservices-228344336816.us-central1.run.app';
  static const String _transferToServiceUrl =
      'https://transfertoservice-228344336816.us-central1.run.app';

  // URL para Picking RX
  static const String _pickingRxUrl =
      'https://obtainpicking-228344336816.us-central1.run.app';

  /// Obtiene los clientes en espera en farmacia
  Future<List<QueueClientModel>> getPharmacyWaitingClients(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_pharmacyWaitingUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => QueueClientModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        // No hay clientes en espera
        return [];
      } else {
        throw Exception(
          'Error al obtener clientes en espera de farmacia: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene los clientes siendo atendidos en farmacia
  Future<List<QueueClientModel>> getPharmacyAttendingClients(
    int storeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_pharmacyAttendingUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => QueueClientModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        // No hay clientes siendo atendidos
        return [];
      } else {
        throw Exception(
          'Error al obtener clientes siendo atendidos en farmacia: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene los clientes en espera en servicios farmacéuticos
  Future<List<QueueClientModel>> getServicesWaitingClients(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_servicesWaitingUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => QueueClientModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        // No hay clientes en espera
        return [];
      } else {
        throw Exception(
          'Error al obtener clientes en espera de servicios: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene los clientes siendo atendidos en servicios farmacéuticos
  Future<List<QueueClientModel>> getServicesAttendingClients(
    int storeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_servicesAttendingUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => QueueClientModel.fromJson(item)).toList();
      } else if (response.statusCode == 404) {
        // No hay clientes siendo atendidos
        return [];
      } else {
        throw Exception(
          'Error al obtener clientes siendo atendidos en servicios: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene los clientes de Picking RX pendientes (state = 0)
  Future<List<QueueClientModel>> getPickingRxPendingClients(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_pickingRxUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => QueueClientModel.fromJson(item))
            .where((client) => client.state == '0')
            .toList();
      } else if (response.statusCode == 404) {
        // No hay clientes pendientes
        return [];
      } else {
        throw Exception(
          'Error al obtener clientes pendientes de Picking RX: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene los clientes de Picking RX preparados (state = 1)
  Future<List<QueueClientModel>> getPickingRxPreparedClients(
    int storeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_pickingRxUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => QueueClientModel.fromJson(item))
            .where((client) => client.state == '1')
            .toList();
      } else if (response.statusCode == 404) {
        // No hay clientes preparados
        return [];
      } else {
        throw Exception(
          'Error al obtener clientes preparados de Picking RX: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtiene todos los datos de las colas para un store específico
  Future<Map<QueueType, List<QueueClientModel>>> getAllQueueData(
    int storeId,
  ) async {
    try {
      final results = await Future.wait([
        getPharmacyWaitingClients(storeId),
        getPharmacyAttendingClients(storeId),
        getServicesWaitingClients(storeId),
        getServicesAttendingClients(storeId),
        getPickingRxPendingClients(storeId),
        getPickingRxPreparedClients(storeId),
      ]);

      return {
        QueueType.pharmacyWaiting: results[0],
        QueueType.pharmacyAttending: results[1],
        QueueType.pharmaceuticalServicesWaiting: results[2],
        QueueType.pharmaceuticalServicesAttending: results[3],
        QueueType.pickingRxPending: results[4],
        QueueType.pickingRxPrepared: results[5],
      };
    } catch (e) {
      // En caso de error, devolver listas vacías
      return {
        QueueType.pharmacyWaiting: [],
        QueueType.pharmacyAttending: [],
        QueueType.pharmaceuticalServicesWaiting: [],
        QueueType.pharmaceuticalServicesAttending: [],
        QueueType.pickingRxPending: [],
        QueueType.pickingRxPrepared: [],
      };
    }
  }

  // ===========================================
  // MÉTODOS PARA LAS ACCIONES DE LOS BOTONES
  // ===========================================

  /// Inicia la atención de un cliente en farmacia
  Future<bool> startAttendingPharmacy(int storeId, String turnId) async {
    return await _performAction(
      _startAttendingPharmacyUrl,
      storeId,
      turnId,
      'iniciar atención en farmacia',
    );
  }

  /// Inicia la atención de un cliente en servicios farmacéuticos
  Future<bool> startAttendingService(int storeId, String turnId) async {
    return await _performAction(
      _startAttendingServiceUrl,
      storeId,
      turnId,
      'iniciar atención en servicios',
    );
  }

  /// Finaliza la atención de un cliente en farmacia
  Future<bool> finishAttendingPharmacy(int storeId, String turnId) async {
    return await _performAction(
      _finishAttendingPharmacyUrl,
      storeId,
      turnId,
      'finalizar atención en farmacia',
    );
  }

  /// Finaliza la atención de un cliente en servicios farmacéuticos
  Future<bool> finishAttendingService(int storeId, String turnId) async {
    return await _performAction(
      _finishAttendingServiceUrl,
      storeId,
      turnId,
      'finalizar atención en servicios',
    );
  }

  /// Cancela un turno en farmacia
  Future<bool> cancelTurnPharmacy(int storeId, String turnId) async {
    return await _performAction(
      _cancelTurnPharmacyUrl,
      storeId,
      turnId,
      'cancelar turno en farmacia',
    );
  }

  /// Cancela un turno en servicios farmacéuticos
  Future<bool> cancelTurnService(int storeId, String turnId) async {
    return await _performAction(
      _cancelTurnServiceUrl,
      storeId,
      turnId,
      'cancelar turno en servicios',
    );
  }

  /// Obtiene los servicios activos para transferencia
  Future<List<ServiceModel>> getActiveServices(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_activeServicesUrl?storeid=$storeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => ServiceModel.fromJson(item))
            .where((service) => service.active && service.type == 'Servicio')
            .toList();
      } else if (response.statusCode == 404) {
        // No hay servicios activos
        return [];
      } else {
        throw Exception(
          'Error al obtener servicios activos: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Transfiere un cliente a un servicio
  Future<bool> transferToService(
    int storeId,
    String originalTurnId,
    String serviceName,
    String serviceType,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_transferToServiceUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'storeid': storeId.toString(),
          'originalTurnId': originalTurnId,
          'name': serviceName,
          'type': serviceType,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error al transferir cliente: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión al transferir cliente: $e');
    }
  }

  /// Método genérico para realizar acciones POST
  Future<bool> _performAction(
    String url,
    int storeId,
    String turnId,
    String actionDescription,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'storeid': storeId.toString(), 'turnId': turnId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
          'Error $actionDescription: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión al $actionDescription: $e');
    }
  }
}
