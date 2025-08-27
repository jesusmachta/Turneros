import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/queue_client_model.dart';
import '../models/service_model.dart';

/// Servicio para manejar las operaciones de las colas usando Firestore real-time
class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamControllers para manejar los streams de datos de cada cola
  final Map<String, StreamController<List<QueueClientModel>>> _controllers = {};

  // Referencias a los listeners para poder cancelarlos
  final Map<String, List<StreamSubscription>> _listeners = {};

  // URLs para las acciones de los botones (mantenemos estas para las acciones POST)
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

  /// Obtiene un stream de clientes en espera en farmacia
  Stream<List<QueueClientModel>> getPharmacyWaitingClientsStream(int storeId) {
    return _getClientsStream(
      storeId,
      'Turns_Pharmacy',
      'Esperando',
      'pharmacy_waiting_$storeId',
    );
  }

  /// Obtiene un stream de clientes siendo atendidos en farmacia
  Stream<List<QueueClientModel>> getPharmacyAttendingClientsStream(
    int storeId,
  ) {
    return _getClientsStream(
      storeId,
      'Turns_Pharmacy',
      'Atendiendo',
      'pharmacy_attending_$storeId',
    );
  }

  /// Obtiene un stream de clientes en espera en servicios farmacéuticos
  Stream<List<QueueClientModel>> getServicesWaitingClientsStream(int storeId) {
    return _getClientsStream(
      storeId,
      'Turns_Services',
      'Esperando',
      'services_waiting_$storeId',
    );
  }

  /// Obtiene un stream de clientes siendo atendidos en servicios farmacéuticos
  Stream<List<QueueClientModel>> getServicesAttendingClientsStream(
    int storeId,
  ) {
    return _getClientsStream(
      storeId,
      'Turns_Services',
      'Atendiendo',
      'services_attending_$storeId',
    );
  }

  /// Obtiene un stream de clientes de Picking RX pendientes (state = 0)
  Stream<List<QueueClientModel>> getPickingRxPendingClientsStream(int storeId) {
    return _getPickingRxClientsStream(storeId, 0, 'picking_pending_$storeId');
  }

  /// Obtiene un stream de clientes de Picking RX preparados (state = 1)
  Stream<List<QueueClientModel>> getPickingRxPreparedClientsStream(
    int storeId,
  ) {
    return _getPickingRxClientsStream(storeId, 1, 'picking_prepared_$storeId');
  }

  /// Obtiene todos los streams de las colas para un store específico
  Map<QueueType, Stream<List<QueueClientModel>>> getAllQueueStreams(
    int storeId,
  ) {
    return {
      QueueType.pharmacyWaiting: getPharmacyWaitingClientsStream(storeId),
      QueueType.pharmacyAttending: getPharmacyAttendingClientsStream(storeId),
      QueueType.pharmaceuticalServicesWaiting: getServicesWaitingClientsStream(
        storeId,
      ),
      QueueType.pharmaceuticalServicesAttending:
          getServicesAttendingClientsStream(storeId),
      QueueType.pickingRxPending: getPickingRxPendingClientsStream(storeId),
      QueueType.pickingRxPrepared: getPickingRxPreparedClientsStream(storeId),
    };
  }

  /// Método helper para crear streams de clientes desde Firestore
  Stream<List<QueueClientModel>> _getClientsStream(
    int storeId,
    String collection,
    String state,
    String controllerKey,
  ) {
    // Si ya existe un controller para esta consulta, lo retornamos
    if (_controllers.containsKey(controllerKey)) {
      return _controllers[controllerKey]!.stream;
    }

    // Crear nuevo controller
    final controller = StreamController<List<QueueClientModel>>.broadcast();
    _controllers[controllerKey] = controller;

    // Configurar el listener de Firestore
    final listener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection(collection)
        .where('state', isEqualTo: state)
        .orderBy('Created_At', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final clients =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return QueueClientModel.fromFirestore(data);
                  }).toList();

              if (!controller.isClosed) {
                controller.add(clients);
              }

              print('✅ $collection ($state): ${clients.length} clientes');
            } catch (e) {
              print('❌ Error procesando $collection ($state): $e');
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          },
          onError: (error) {
            print('❌ Error en listener $collection ($state): $error');
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    // Guardar referencia al listener
    _listeners[controllerKey] = [listener];

    return controller.stream;
  }

  /// Método helper para crear streams de Picking RX desde Firestore
  Stream<List<QueueClientModel>> _getPickingRxClientsStream(
    int storeId,
    int state,
    String controllerKey,
  ) {
    // Si ya existe un controller para esta consulta, lo retornamos
    if (_controllers.containsKey(controllerKey)) {
      return _controllers[controllerKey]!.stream;
    }

    // Crear nuevo controller
    final controller = StreamController<List<QueueClientModel>>.broadcast();
    _controllers[controllerKey] = controller;

    // Configurar el listener de Firestore
    final listener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_PickingRX')
        .where('state', isEqualTo: state)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final clients =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return QueueClientModel.fromFirestore(data);
                  }).toList();

              if (!controller.isClosed) {
                controller.add(clients);
              }

              final stateText = state == 0 ? 'Pendiente' : 'Preparado';
              print('✅ PickingRX ($stateText): ${clients.length} clientes');
            } catch (e) {
              print('❌ Error procesando PickingRX (state $state): $e');
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          },
          onError: (error) {
            print('❌ Error en listener PickingRX (state $state): $error');
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    // Guardar referencia al listener
    _listeners[controllerKey] = [listener];

    return controller.stream;
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

  /// Método genérico para realizar acciones POST (mantenemos esto sin cambios)
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

  /// Cancela todos los listeners y libera recursos
  void dispose() {
    print('🧹 Liberando recursos de QueueService');

    // Cancelar todos los listeners
    for (final listenerGroup in _listeners.values) {
      for (final listener in listenerGroup) {
        listener.cancel();
      }
    }
    _listeners.clear();

    // Cerrar todos los controllers
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  /// Cancela listeners específicos para un store
  void disposeStore(int storeId) {
    final keysToRemove = <String>[];

    for (final key in _controllers.keys) {
      if (key.contains('_$storeId')) {
        _listeners[key]?.forEach((listener) => listener.cancel());
        _listeners.remove(key);

        final controller = _controllers[key];
        if (controller != null && !controller.isClosed) {
          controller.close();
        }
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _controllers.remove(key);
    }
  }
}
