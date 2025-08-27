import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

class ServicesApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamControllers para manejar los streams de servicios
  final Map<String, StreamController<List<ServiceModel>>> _controllers = {};

  // Referencias a los listeners para poder cancelarlos
  final Map<String, StreamSubscription> _listeners = {};

  /// Obtiene un stream de servicios activos desde Firestore
  /// [storeId] - ID de la tienda para obtener los servicios
  Stream<List<ServiceModel>> getServicesStream({required String storeId}) {
    final controllerKey = 'services_$storeId';

    // Si ya existe un controller para este store, lo retornamos
    if (_controllers.containsKey(controllerKey)) {
      return _controllers[controllerKey]!.stream;
    }

    // Crear nuevo controller
    final controller = StreamController<List<ServiceModel>>.broadcast();
    _controllers[controllerKey] = controller;

    // Configurar el listener de Firestore
    final listener = _firestore
        .collection('Turns_Store')
        .doc(storeId)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              if (!snapshot.exists) {
                if (!controller.isClosed) {
                  controller.add([]);
                }
                return;
              }

              final storeData = snapshot.data();
              final allServices =
                  storeData?['services'] as List<dynamic>? ?? [];

              // Filtrar solo servicios activos
              final activeServices =
                  allServices
                      .where((service) => service['active'] == true)
                      .map(
                        (service) => ServiceModel.fromFirestore(
                          service as Map<String, dynamic>,
                        ),
                      )
                      .toList();

              if (!controller.isClosed) {
                controller.add(activeServices);
              }

              print(
                '✅ Servicios activos: ${activeServices.length} para store $storeId',
              );
            } catch (e) {
              print('❌ Error procesando servicios: $e');
              if (!controller.isClosed) {
                controller.addError(e);
              }
            }
          },
          onError: (error) {
            print('❌ Error en listener de servicios: $error');
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    // Guardar referencia al listener
    _listeners[controllerKey] = listener;

    return controller.stream;
  }

  /// Método legacy para compatibilidad (ahora usa Firestore)
  Future<List<ServiceModel>> getServices({required String storeId}) async {
    try {
      print(
        '⚠️ Método getServices() legacy - considera usar getServicesStream()',
      );

      final snapshot =
          await _firestore.collection('Turns_Store').doc(storeId).get();

      if (!snapshot.exists) {
        return [];
      }

      final storeData = snapshot.data();
      final allServices = storeData?['services'] as List<dynamic>? ?? [];

      // Filtrar solo servicios activos
      final activeServices =
          allServices
              .where((service) => service['active'] == true)
              .map(
                (service) =>
                    ServiceModel.fromFirestore(service as Map<String, dynamic>),
              )
              .toList();

      return activeServices;
    } catch (e) {
      throw Exception('Error al obtener servicios: $e');
    }
  }

  /// Cancela todos los listeners y libera recursos
  void dispose() {
    print('🧹 Liberando recursos de ServicesApiService');

    // Cancelar todos los listeners
    for (final listener in _listeners.values) {
      listener.cancel();
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
  void disposeStore(String storeId) {
    final controllerKey = 'services_$storeId';

    _listeners[controllerKey]?.cancel();
    _listeners.remove(controllerKey);

    final controller = _controllers.remove(controllerKey);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }

  /// Versión mock para desarrollo - eliminar cuando tengas la URL real
  Future<List<ServiceModel>> getServicesMock() async {
    // Simula una llamada a la API
    await Future.delayed(const Duration(seconds: 1));

    final mockData = [
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Atención en Mostrador",
        "type": "Farmacia",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2Fatencion-mostrador.png?alt=media&token=6e3669f6-e874-438b-a264-40244c32c638",
      },
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Asistencia Preferencial",
        "type": "Farmacia",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2Fasistencia-preferencial.png?alt=media&token=b587d40c-61d5-43ac-b195-aeb4b93dadbe",
      },
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Inyectología",
        "type": "Servicio",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2FIcon%20Sizes%20Clarification.png?alt=media&token=62ebdf06-b285-4aa3-9f4c-6e9115ac00c1",
      },
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Presión Arterial",
        "type": "Servicio",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2FIcon%20Size%20Clarification.png?alt=media&token=5f65362f-c2d4-47a2-a43a-17279862e37a",
      },
    ];

    return mockData.map((json) => ServiceModel.fromJson(json)).toList();
  }
}
