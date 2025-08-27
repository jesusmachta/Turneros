import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';

class ServicesManagementApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamControllers para manejar los streams de servicios
  final Map<String, StreamController<List<ServiceModel>>> _controllers = {};

  // Referencias a los listeners para poder cancelarlos
  final Map<String, StreamSubscription> _listeners = {};

  // URLs para las acciones POST (mantenemos estas)
  static const String _baseUrl =
      'https://getallonlyservices-228344336816.us-central1.run.app';

  /// Actualiza un servicio existente
  Future<bool> updateService({
    required String storeId,
    required String currentName,
    required Map<String, dynamic> updates,
  }) async {
    try {
      const updateUrl =
          'https://updateexistentservice-228344336816.us-central1.run.app';
      final uri = Uri.parse(updateUrl);

      final requestBody = {
        'storeid': int.parse(storeId),
        'currentName': currentName,
        'updates': updates,
      };

      print('🔄 Actualizando servicio: $currentName');
      print('📡 URL de la API: $uri');
      print('📄 Datos a enviar: $requestBody');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Tiempo de espera agotado al actualizar servicio',
              );
            },
          );

      print('📊 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Servicio actualizado exitosamente');
        return true;
      } else if (response.statusCode == 404) {
        throw ServiceUpdateException(
          'El servicio "$currentName" no fue encontrado',
        );
      } else if (response.statusCode >= 500) {
        throw Exception('Error del servidor. Por favor, intente más tarde');
      } else {
        throw Exception('Error al actualizar servicio: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServiceUpdateException) {
        rethrow;
      }

      print('❌ Error al actualizar servicio: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Sin conexión a internet. Verifique su conexión');
      }

      throw Exception('Error al actualizar servicio: ${e.toString()}');
    }
  }

  /// Obtiene un stream de todos los servicios tipo 'Servicio' desde Firestore
  Stream<List<ServiceModel>> getAllServicesStream(String storeId) {
    final controllerKey = 'all_services_$storeId';

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

              // Filtrar solo servicios de tipo 'Servicio' (como en tu Cloud Function)
              final filteredServices =
                  allServices
                      .where((service) => service['type'] == 'Servicio')
                      .map(
                        (service) => ServiceModel.fromFirestore(
                          service as Map<String, dynamic>,
                        ),
                      )
                      .toList();

              if (!controller.isClosed) {
                controller.add(filteredServices);
              }

              print(
                '✅ Servicios tipo "Servicio": ${filteredServices.length} para store $storeId',
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

  /// Método legacy - Obtiene todos los servicios disponibles para una tienda
  Future<List<ServiceModel>> getAllServices(String storeId) async {
    try {
      final uri = Uri.parse('$_baseUrl?storeid=$storeId');

      print('🔍 Obteniendo servicios para tienda: $storeId');
      print('📡 URL de la API: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado al obtener servicios');
            },
          );

      print('📊 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Convertir la lista de JSON a lista de ServiceModel
        final List<ServiceModel> services =
            data
                .map((serviceJson) => ServiceModel.fromJson(serviceJson))
                .toList();

        print(
          '✅ Servicios obtenidos exitosamente: ${services.length} servicios',
        );

        return services;
      } else if (response.statusCode == 404) {
        throw ServicesNotFoundException(
          'No se encontraron servicios para la tienda $storeId',
        );
      } else if (response.statusCode >= 500) {
        throw Exception('Error del servidor. Por favor, intente más tarde');
      } else {
        throw Exception('Error al obtener servicios: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ServicesNotFoundException) {
        rethrow;
      }

      print('❌ Error al obtener servicios: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Sin conexión a internet. Verifique su conexión');
      }

      throw Exception('Error al obtener servicios: ${e.toString()}');
    }
  }

  /// Cancela todos los listeners y libera recursos
  void dispose() {
    print('🧹 Liberando recursos de ServicesManagementApiService');

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
    final controllerKey = 'all_services_$storeId';

    _listeners[controllerKey]?.cancel();
    _listeners.remove(controllerKey);

    final controller = _controllers.remove(controllerKey);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }
}

/// Excepción específica cuando no se encuentran servicios
class ServicesNotFoundException implements Exception {
  final String message;
  ServicesNotFoundException(this.message);

  @override
  String toString() => message;
}

/// Excepción específica cuando falla la actualización de servicios
class ServiceUpdateException implements Exception {
  final String message;
  ServiceUpdateException(this.message);

  @override
  String toString() => message;
}
