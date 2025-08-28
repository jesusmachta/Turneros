import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/queue_client_model.dart';
import '../models/service_model.dart';

/// Servicio para manejar las operaciones de las colas usando Firestore real-time
class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamControllers para manejar los streams de datos de cada cola
  final Map<String, StreamController<List<QueueClientModel>>> _controllers = {};

  // Referencias a los listeners para poder cancelarlos
  final Map<String, List<StreamSubscription>> _listeners = {};

  // URLs legacy removidas - ahora todo usa Firestore directo

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
  // MÉTODOS FIRESTORE PARA ACCIONES DE BOTONES (REAL-TIME)
  // ===========================================

  /// Inicia la atención de un cliente en farmacia (Firestore directo)
  Future<bool> startAttendingPharmacy(int storeId, String turnId) async {
    try {
      print('🚀 Iniciando atención en farmacia: $turnId');

      final turnDocRef = _firestore
          .collection('Turns_Store')
          .doc(storeId.toString())
          .collection('Turns_Pharmacy')
          .doc(turnId);

      await turnDocRef.update({
        'state': 'Atendiendo',
        'Served_At': FieldValue.serverTimestamp(),
      });

      print('✅ Turno $turnId marcado como Atendiendo en farmacia');
      return true;
    } catch (e) {
      print('❌ Error al iniciar atención en farmacia: $e');
      throw Exception('Error al iniciar atención en farmacia: $e');
    }
  }

  /// Inicia la atención de un cliente en servicios farmacéuticos (Firestore directo)
  Future<bool> startAttendingService(int storeId, String turnId) async {
    try {
      print('🚀 Iniciando atención en servicios: $turnId');

      final turnDocRef = _firestore
          .collection('Turns_Store')
          .doc(storeId.toString())
          .collection('Turns_Services')
          .doc(turnId);

      await turnDocRef.update({
        'state': 'Atendiendo',
        'Served_At': FieldValue.serverTimestamp(),
      });

      print('✅ Turno $turnId marcado como Atendiendo en servicios');
      return true;
    } catch (e) {
      print('❌ Error al iniciar atención en servicios: $e');
      throw Exception('Error al iniciar atención en servicios: $e');
    }
  }

  /// Finaliza la atención de un cliente en farmacia (Firestore directo)
  Future<bool> finishAttendingPharmacy(int storeId, String turnId) async {
    try {
      print('🏁 Finalizando atención en farmacia: $turnId');

      final turnDocRef = _firestore
          .collection('Turns_Store')
          .doc(storeId.toString())
          .collection('Turns_Pharmacy')
          .doc(turnId);

      await turnDocRef.update({
        'state': 'Finalizado',
        'Finished_At': FieldValue.serverTimestamp(),
      });

      print('✅ Turno $turnId marcado como Finalizado en farmacia');
      return true;
    } catch (e) {
      print('❌ Error al finalizar atención en farmacia: $e');
      throw Exception('Error al finalizar atención en farmacia: $e');
    }
  }

  /// Finaliza la atención de un cliente en servicios farmacéuticos (Firestore directo)
  Future<bool> finishAttendingService(int storeId, String turnId) async {
    try {
      print('🏁 Finalizando atención en servicios: $turnId');

      final turnDocRef = _firestore
          .collection('Turns_Store')
          .doc(storeId.toString())
          .collection('Turns_Services')
          .doc(turnId);

      await turnDocRef.update({
        'state': 'Finalizado',
        'Finished_At': FieldValue.serverTimestamp(),
      });

      print('✅ Turno $turnId marcado como Finalizado en servicios');
      return true;
    } catch (e) {
      print('❌ Error al finalizar atención en servicios: $e');
      throw Exception('Error al finalizar atención en servicios: $e');
    }
  }

  /// Cancela un turno en farmacia (Firestore directo)
  Future<bool> cancelTurnPharmacy(int storeId, String turnId) async {
    try {
      print('❌ Cancelando turno en farmacia: $turnId');

      final turnDocRef = _firestore
          .collection('Turns_Store')
          .doc(storeId.toString())
          .collection('Turns_Pharmacy')
          .doc(turnId);

      await turnDocRef.update({
        'state': 'Cancelado',
        'Cancel_At': FieldValue.serverTimestamp(),
      });

      print('✅ Turno $turnId marcado como Cancelado en farmacia');
      return true;
    } catch (e) {
      print('❌ Error al cancelar turno en farmacia: $e');
      throw Exception('Error al cancelar turno en farmacia: $e');
    }
  }

  /// Cancela un turno en servicios farmacéuticos (Firestore directo)
  Future<bool> cancelTurnService(int storeId, String turnId) async {
    try {
      print('❌ Cancelando turno en servicios: $turnId');

      final turnDocRef = _firestore
          .collection('Turns_Store')
          .doc(storeId.toString())
          .collection('Turns_Services')
          .doc(turnId);

      await turnDocRef.update({
        'state': 'Cancelado',
        'Cancel_At': FieldValue.serverTimestamp(),
      });

      print('✅ Turno $turnId marcado como Cancelado en servicios');
      return true;
    } catch (e) {
      print('❌ Error al cancelar turno en servicios: $e');
      throw Exception('Error al cancelar turno en servicios: $e');
    }
  }

  /// Obtiene los servicios activos para transferencia (Firestore directo)
  Future<List<ServiceModel>> getActiveServices(int storeId) async {
    try {
      print(
        '🔍 Obteniendo servicios activos desde Firestore para store: $storeId',
      );

      final storeDoc =
          await _firestore
              .collection('Turns_Store')
              .doc(storeId.toString())
              .get();

      if (!storeDoc.exists) {
        print('⚠️ Store $storeId no encontrado');
        return [];
      }

      final storeData = storeDoc.data();
      final allServices = storeData?['services'] as List<dynamic>? ?? [];

      // Filtrar solo servicios activos de tipo 'Servicio'
      final activeServices =
          allServices
              .where(
                (service) =>
                    service['active'] == true && service['type'] == 'Servicio',
              )
              .map(
                (service) =>
                    ServiceModel.fromFirestore(service as Map<String, dynamic>),
              )
              .toList();

      print('✅ Servicios activos obtenidos: ${activeServices.length}');
      return activeServices;
    } catch (e) {
      print('❌ Error al obtener servicios activos: $e');
      throw Exception('Error al obtener servicios activos: $e');
    }
  }

  /// Transfiere un cliente a un servicio (Firestore directo con transacción)
  Future<bool> transferToService(
    int storeId,
    String originalTurnId,
    String serviceName,
    String serviceType,
  ) async {
    try {
      print('🔄 Transfiriendo turno $originalTurnId a servicio: $serviceName');

      // Ejecutar transferencia en una transacción para consistencia
      await _firestore.runTransaction((transaction) async {
        // Referencias a los documentos
        final storeRef = _firestore
            .collection('Turns_Store')
            .doc(storeId.toString());
        final originalTurnRef = storeRef
            .collection('Turns_Pharmacy')
            .doc(originalTurnId);

        // 1. Leer documentos necesarios
        final storeDoc = await transaction.get(storeRef);
        final originalTurnDoc = await transaction.get(originalTurnRef);

        if (!storeDoc.exists) {
          throw Exception('Store $storeId no encontrado');
        }
        if (!originalTurnDoc.exists) {
          throw Exception('Turno original $originalTurnId no encontrado');
        }

        final storeData = storeDoc.data()!;
        final originalTurnData = originalTurnDoc.data()!;

        // 2. Obtener nuevo número de turno para servicios
        final serviceTurnNumber = storeData['Turns_Services'] ?? 1;

        // 3. Crear nuevo turno en Turns_Services
        final newServiceTurnRef = storeRef.collection('Turns_Services').doc();
        final newServiceTurnData = {
          'storeid': storeId,
          'cedula': originalTurnData['cedula'],
          'documento': originalTurnData['documento'],
          'country': originalTurnData['country'],
          'comes_from': serviceName,
          'state': 'Esperando',
          'Turn': serviceTurnNumber,
          'Created_At': FieldValue.serverTimestamp(),
        };

        // 4. Realizar todas las escrituras en la transacción
        transaction.set(newServiceTurnRef, newServiceTurnData);

        transaction.update(storeRef, {'Turns_Services': serviceTurnNumber + 1});

        transaction.update(originalTurnRef, {
          'state': 'Transferido',
          'Served_At': FieldValue.serverTimestamp(),
        });

        print(
          '✅ Transferencia completada: turno #$serviceTurnNumber creado en servicios',
        );
      });

      return true;
    } catch (e) {
      print('❌ Error al transferir cliente: $e');
      throw Exception('Error al transferir cliente: $e');
    }
  }

  // Método _performAction removido - ya no se necesita con Firestore directo

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
