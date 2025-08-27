import 'dart:async';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../services/services_management_api_service.dart';

class ServicesManagementController extends ChangeNotifier {
  final ServicesManagementApiService _apiService =
      ServicesManagementApiService();

  List<ServiceModel> _services = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ServiceModel>>? _servicesSubscription;
  String? _currentStoreId;

  // Getters
  List<ServiceModel> get services => _services;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasServices => _services.isNotEmpty;

  // Filtros
  List<ServiceModel> get activeServices =>
      _services.where((service) => service.active).toList();

  List<ServiceModel> get inactiveServices =>
      _services.where((service) => !service.active).toList();

  List<ServiceModel> get servicesWithSMS =>
      _services.where((service) => service.sms).toList();

  List<ServiceModel> get servicesWithScreen =>
      _services.where((service) => service.screen).toList();

  /// Inicia la escucha de servicios usando streams
  void startListening(String storeId) {
    if (storeId.isEmpty) {
      _setError('ID de tienda no válido');
      return;
    }

    // Si ya estamos escuchando el mismo store, no hacer nada
    if (_currentStoreId == storeId && _servicesSubscription != null) {
      return;
    }

    // Detener listener previo si existe
    stopListening();

    _currentStoreId = storeId;
    _setLoading(true);
    _clearError();

    print('🚀 Iniciando listener de servicios para tienda: $storeId');

    // Configurar el listener del stream
    _servicesSubscription = _apiService
        .getAllServicesStream(storeId)
        .listen(
          (services) {
            _services = services;
            _setLoading(false);
            notifyListeners();
            print(
              '✅ Servicios actualizados: ${services.length} servicios tipo "Servicio"',
            );
          },
          onError: (error) {
            print('❌ Error en listener de servicios: $error');
            _setError('Error al cargar servicios: $error');
            _setLoading(false);
          },
        );
  }

  /// Detiene el listener activo
  void stopListening() {
    _servicesSubscription?.cancel();
    _servicesSubscription = null;
    _currentStoreId = null;
    print('🛑 Listener de servicios detenido');
  }

  /// Método legacy - Carga todos los servicios para una tienda específica
  Future<void> loadServices(String storeId) async {
    print('⚠️ Método loadServices() legacy - reiniciando listeners');
    startListening(storeId);
  }

  /// Actualiza un servicio existente
  Future<bool> updateService({
    required String storeId,
    required String currentName,
    required String? newName,
    required String? newType,
    required bool? newActive,
    required bool? newSms,
    required bool? newScreen,
  }) async {
    if (storeId.isEmpty || currentName.isEmpty) {
      _setError('Datos de servicio no válidos');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Construir el objeto de actualizaciones solo con campos modificados
      final Map<String, dynamic> updates = {};

      if (newName != null && newName.isNotEmpty && newName != currentName) {
        updates['name'] = newName;
      }

      if (newType != null && newType.isNotEmpty) {
        // Buscar el servicio actual para comparar
        final currentService = getServiceByName(currentName);
        if (currentService != null && newType != currentService.type) {
          updates['type'] = newType;
        }
      }

      if (newActive != null) {
        // Buscar el servicio actual para comparar
        final currentService = getServiceByName(currentName);
        if (currentService != null && newActive != currentService.active) {
          updates['active'] = newActive;
        }
      }

      if (newSms != null) {
        // Buscar el servicio actual para comparar
        final currentService = getServiceByName(currentName);
        if (currentService != null && newSms != currentService.sms) {
          updates['SMS'] = newSms;
        }
      }

      if (newScreen != null) {
        // Buscar el servicio actual para comparar
        final currentService = getServiceByName(currentName);
        if (currentService != null && newScreen != currentService.screen) {
          updates['screen'] = newScreen;
        }
      }

      if (updates.isEmpty) {
        _setError('No hay cambios para actualizar');
        return false;
      }

      print('🔄 Actualizando servicio: $currentName con cambios: $updates');

      final success = await _apiService.updateService(
        storeId: storeId,
        currentName: currentName,
        updates: updates,
      );

      if (success) {
        // Recargar los servicios para reflejar los cambios
        await loadServices(storeId);
        print('✅ Servicio actualizado y lista recargada');
        return true;
      }

      return false;
    } catch (e) {
      String errorMsg = 'Error al actualizar servicio';

      if (e.toString().contains('Sin conexión a internet')) {
        errorMsg = 'Sin conexión a internet. Verifique su conexión';
      } else if (e.toString().contains('Tiempo de espera agotado')) {
        errorMsg = 'Tiempo de espera agotado. Intente nuevamente';
      } else if (e.toString().contains('no fue encontrado')) {
        errorMsg = 'El servicio no existe o fue eliminado';
      } else if (e.toString().contains('Error del servidor')) {
        errorMsg = 'Error del servidor. Intente más tarde';
      }

      _setError(errorMsg);
      print('❌ Error al actualizar servicio: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresca la lista de servicios
  Future<void> refreshServices(String storeId) async {
    await loadServices(storeId);
  }

  /// Busca servicios por nombre
  List<ServiceModel> searchServices(String query) {
    if (query.isEmpty) return _services;

    return _services
        .where(
          (service) =>
              service.name.toLowerCase().contains(query.toLowerCase()) ||
              service.type.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  /// Filtra servicios por tipo
  List<ServiceModel> filterServicesByType(String type) {
    if (type.isEmpty) return _services;

    return _services
        .where((service) => service.type.toLowerCase() == type.toLowerCase())
        .toList();
  }

  /// Obtiene un servicio por nombre
  ServiceModel? getServiceByName(String name) {
    try {
      return _services.firstWhere(
        (service) => service.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Obtiene estadísticas de los servicios
  Map<String, int> getServicesStats() {
    return {
      'total': _services.length,
      'active': activeServices.length,
      'inactive': inactiveServices.length,
      'withSMS': servicesWithSMS.length,
      'withScreen': servicesWithScreen.length,
    };
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Limpia el mensaje de error
  void clearError() {
    _clearError();
    notifyListeners();
  }

  /// Limpia todos los datos
  void clear() {
    _services = [];
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    _apiService.dispose();
    clear();
    super.dispose();
  }
}
