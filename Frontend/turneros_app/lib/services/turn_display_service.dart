import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/turn_model.dart';

/// Servicio para manejar los datos de la pantalla de turnos usando Firestore real-time
class TurnDisplayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamControllers para manejar los streams de datos
  final Map<String, StreamController<TurnScreenData>> _pharmacyControllers = {};
  final Map<String, StreamController<TurnScreenData>> _servicesControllers = {};

  // Referencias a los listeners para poder cancelarlos
  final Map<String, List<StreamSubscription>> _listeners = {};

  /// Obtiene un stream de datos de turnos para Farmacia usando Firestore real-time
  Stream<TurnScreenData> getPharmacyTurnsStream(int storeId) {
    final key = 'pharmacy_$storeId';

    // Si ya existe un controller para este store, lo retornamos
    if (_pharmacyControllers.containsKey(key)) {
      return _pharmacyControllers[key]!.stream;
    }

    // Crear nuevo controller
    final controller = StreamController<TurnScreenData>.broadcast();
    _pharmacyControllers[key] = controller;

    // Configurar los listeners de Firestore
    _setupPharmacyListeners(storeId, controller);

    return controller.stream;
  }

  /// Obtiene un stream de datos de turnos para Servicios Farmacéuticos usando Firestore real-time
  Stream<TurnScreenData> getServicesTurnsStream(int storeId) {
    final key = 'services_$storeId';

    // Si ya existe un controller para este store, lo retornamos
    if (_servicesControllers.containsKey(key)) {
      return _servicesControllers[key]!.stream;
    }

    // Crear nuevo controller
    final controller = StreamController<TurnScreenData>.broadcast();
    _servicesControllers[key] = controller;

    // Configurar los listeners de Firestore
    _setupServicesListeners(storeId, controller);

    return controller.stream;
  }

  /// Configura los listeners de Firestore para Farmacia
  void _setupPharmacyListeners(
    int storeId,
    StreamController<TurnScreenData> controller,
  ) {
    final key = 'pharmacy_$storeId';
    _listeners[key] = [];

    print('🏥 Configurando listeners de Farmacia para Store ID: $storeId');

    // Variables para mantener el estado actual
    TurnModel? currentlyServed;
    List<TurnModel> waitingQueue = [];

    // Función para emitir datos actualizados
    void emitData() {
      if (!controller.isClosed) {
        controller.add(
          TurnScreenData(
            currentlyBeingServed: currentlyServed,
            waitingQueue: waitingQueue,
          ),
        );
      }
    }

    // Listener para turnos en espera en Farmacia
    final waitingListener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_Pharmacy')
        .where('state', isEqualTo: 'Esperando')
        .orderBy('Created_At', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              waitingQueue =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return TurnModel.fromFirestore(data);
                  }).toList();

              print('✅ Farmacia - En espera: ${waitingQueue.length} turnos');
              emitData();
            } catch (e) {
              print('❌ Error procesando turnos en espera de Farmacia: $e');
              controller.addError(e);
            }
          },
          onError: (error) {
            print('❌ Error en listener de espera de Farmacia: $error');
            controller.addError(error);
          },
        );

    // Listener para turno siendo atendido en Farmacia
    final attendingListener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_Pharmacy')
        .where('state', isEqualTo: 'Atendiendo')
        .orderBy('Served_At', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              if (snapshot.docs.isNotEmpty) {
                final doc = snapshot.docs.first;
                final data = doc.data();
                data['id'] = doc.id;
                currentlyServed = TurnModel.fromFirestore(data);
                print(
                  '✅ Farmacia - Atendiendo: ${currentlyServed?.turn ?? 'Ninguno'}',
                );
              } else {
                currentlyServed = null;
                print('✅ Farmacia - Atendiendo: Ninguno');
              }
              emitData();
            } catch (e) {
              print('❌ Error procesando turno atendido de Farmacia: $e');
              controller.addError(e);
            }
          },
          onError: (error) {
            print('❌ Error en listener de atendido de Farmacia: $error');
            controller.addError(error);
          },
        );

    // Guardar referencias a los listeners
    _listeners[key]!.addAll([waitingListener, attendingListener]);
  }

  /// Configura los listeners de Firestore para Servicios
  void _setupServicesListeners(
    int storeId,
    StreamController<TurnScreenData> controller,
  ) {
    final key = 'services_$storeId';
    _listeners[key] = [];

    print('💊 Configurando listeners de Servicios para Store ID: $storeId');

    // Variables para mantener el estado actual
    TurnModel? currentlyServed;
    List<TurnModel> waitingQueue = [];

    // Función para emitir datos actualizados
    void emitData() {
      if (!controller.isClosed) {
        controller.add(
          TurnScreenData(
            currentlyBeingServed: currentlyServed,
            waitingQueue: waitingQueue,
          ),
        );
      }
    }

    // Listener para turnos en espera en Servicios
    final waitingListener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_Services')
        .where('state', isEqualTo: 'Esperando')
        .orderBy('Created_At', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              waitingQueue =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return TurnModel.fromFirestore(data);
                  }).toList();

              print('✅ Servicios - En espera: ${waitingQueue.length} turnos');
              emitData();
            } catch (e) {
              print('❌ Error procesando turnos en espera de Servicios: $e');
              controller.addError(e);
            }
          },
          onError: (error) {
            print('❌ Error en listener de espera de Servicios: $error');
            controller.addError(error);
          },
        );

    // Listener para turno siendo atendido en Servicios
    final attendingListener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_Services')
        .where('state', isEqualTo: 'Atendiendo')
        .orderBy('Served_At', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              if (snapshot.docs.isNotEmpty) {
                final doc = snapshot.docs.first;
                final data = doc.data();
                data['id'] = doc.id;
                currentlyServed = TurnModel.fromFirestore(data);
                print(
                  '✅ Servicios - Atendiendo: ${currentlyServed?.turn ?? 'Ninguno'}',
                );
              } else {
                currentlyServed = null;
                print('✅ Servicios - Atendiendo: Ninguno');
              }
              emitData();
            } catch (e) {
              print('❌ Error procesando turno atendido de Servicios: $e');
              controller.addError(e);
            }
          },
          onError: (error) {
            print('❌ Error en listener de atendido de Servicios: $error');
            controller.addError(error);
          },
        );

    // Guardar referencias a los listeners
    _listeners[key]!.addAll([waitingListener, attendingListener]);
  }

  /// Cancela todos los listeners y libera recursos
  void dispose() {
    print('🧹 Liberando recursos de TurnDisplayService');

    // Cancelar todos los listeners
    for (final listenerGroup in _listeners.values) {
      for (final listener in listenerGroup) {
        listener.cancel();
      }
    }
    _listeners.clear();

    // Cerrar todos los controllers
    for (final controller in _pharmacyControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _pharmacyControllers.clear();

    for (final controller in _servicesControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _servicesControllers.clear();
  }

  /// Cancela listeners específicos para un store
  void disposeStore(int storeId, {bool pharmacy = true, bool services = true}) {
    if (pharmacy) {
      final pharmacyKey = 'pharmacy_$storeId';
      _listeners[pharmacyKey]?.forEach((listener) => listener.cancel());
      _listeners.remove(pharmacyKey);

      final controller = _pharmacyControllers.remove(pharmacyKey);
      if (controller != null && !controller.isClosed) {
        controller.close();
      }
    }

    if (services) {
      final servicesKey = 'services_$storeId';
      _listeners[servicesKey]?.forEach((listener) => listener.cancel());
      _listeners.remove(servicesKey);

      final controller = _servicesControllers.remove(servicesKey);
      if (controller != null && !controller.isClosed) {
        controller.close();
      }
    }
  }
}
