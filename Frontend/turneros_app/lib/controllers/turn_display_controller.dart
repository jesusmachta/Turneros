import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/turn_model.dart';
import '../services/turn_display_service.dart';
import '../services/audio_service.dart';

/// Controlador para manejar el estado de la pantalla de turnos usando streams
class TurnDisplayController extends ChangeNotifier {
  final TurnDisplayService _turnDisplayService = TurnDisplayService();
  final AudioService _audioService = AudioService();

  // Subscripciones a los streams
  StreamSubscription<TurnScreenData>? _pharmacySubscription;
  StreamSubscription<TurnScreenData>? _servicesSubscription;

  // Estado para Farmacia
  TurnScreenData _pharmacyData = TurnScreenData.empty();
  bool _isLoadingPharmacy = false;
  String? _pharmacyError;

  // Estado para Servicios Farmacéuticos
  TurnScreenData _servicesData = TurnScreenData.empty();
  bool _isLoadingServices = false;
  String? _servicesError;

  // Store ID actual
  int? _currentStoreId;

  // Flags para evitar sonido en la primera carga
  bool _isFirstPharmacyLoad = true;
  bool _isFirstServicesLoad = true;

  // Getters para Farmacia
  TurnScreenData get pharmacyData => _pharmacyData;
  bool get isLoadingPharmacy => _isLoadingPharmacy;
  String? get pharmacyError => _pharmacyError;

  // Getters para Servicios
  TurnScreenData get servicesData => _servicesData;
  bool get isLoadingServices => _isLoadingServices;
  String? get servicesError => _servicesError;

  // Getter para saber si está cargando algún dato
  bool get isLoading => _isLoadingPharmacy || _isLoadingServices;

  /// Inicia los streams de datos para ambas secciones
  void startListening(int storeId) {
    print('🔄 Iniciando listeners de turnos para store ID: $storeId');

    // Si ya estamos escuchando el mismo store, no hacer nada
    if (_currentStoreId == storeId &&
        _pharmacySubscription != null &&
        _servicesSubscription != null) {
      return;
    }

    // Detener listeners previos si existen
    stopListening();

    _currentStoreId = storeId;
    _isLoadingPharmacy = true;
    _isLoadingServices = true;

    // Reiniciar flags de primera carga
    _isFirstPharmacyLoad = true;
    _isFirstServicesLoad = true;

    notifyListeners();

    // Iniciar listener para Farmacia
    _startPharmacyListener(storeId);

    // Iniciar listener para Servicios
    _startServicesListener(storeId);
  }

  /// Inicia el listener para los datos de Farmacia
  void _startPharmacyListener(int storeId) {
    print('🏥 Iniciando listener de Farmacia...');

    _pharmacySubscription = _turnDisplayService
        .getPharmacyTurnsStream(storeId)
        .listen(
          (data) {
            _isLoadingPharmacy = false;
            _pharmacyError = null;

            // Solo reproducir sonido si hay cambios significativos y no es la primera carga
            if (!_isFirstPharmacyLoad &&
                _hasSignificantChange(_pharmacyData, data)) {
              _audioService.playAttendSound();
            }

            _pharmacyData = data;
            _isFirstPharmacyLoad = false;
            notifyListeners();
            print('✅ Datos de Farmacia actualizados en tiempo real');
          },
          onError: (error) {
            _isLoadingPharmacy = false;
            _pharmacyError = error.toString();
            notifyListeners();
            print('❌ Error en listener de Farmacia: $error');
          },
        );
  }

  /// Inicia el listener para los datos de Servicios
  void _startServicesListener(int storeId) {
    print('💊 Iniciando listener de Servicios...');

    _servicesSubscription = _turnDisplayService
        .getServicesTurnsStream(storeId)
        .listen(
          (data) {
            _isLoadingServices = false;
            _servicesError = null;

            // Solo reproducir sonido si hay cambios significativos y no es la primera carga
            if (!_isFirstServicesLoad &&
                _hasSignificantChange(_servicesData, data)) {
              _audioService.playAttendSound();
            }

            _servicesData = data;
            _isFirstServicesLoad = false;
            notifyListeners();
            print('✅ Datos de Servicios actualizados en tiempo real');
          },
          onError: (error) {
            _isLoadingServices = false;
            _servicesError = error.toString();
            notifyListeners();
            print('❌ Error en listener de Servicios: $error');
          },
        );
  }

  /// Verifica si hay cambios significativos que justifiquen reproducir sonido
  bool _hasSignificantChange(TurnScreenData oldData, TurnScreenData newData) {
    try {
      // Cambio en el turno que se está atendiendo
      final oldCurrentId = oldData.currentlyBeingServed?.id;
      final newCurrentId = newData.currentlyBeingServed?.id;

      if (oldCurrentId != newCurrentId) {
        print(
          '🔔 Cambio detectado en turno atendido: $oldCurrentId -> $newCurrentId',
        );
        return true;
      }

      // Cambio en la cantidad de turnos en espera (nuevo turno agregado)
      final oldQueueLength = oldData.waitingQueue.length;
      final newQueueLength = newData.waitingQueue.length;

      if (newQueueLength > oldQueueLength) {
        print(
          '🔔 Nuevo turno en espera detectado: $oldQueueLength -> $newQueueLength',
        );
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error en _hasSignificantChange: $e');
      return false; // En caso de error, no reproducir sonido
    }
  }

  /// Detiene todos los listeners activos
  void stopListening() {
    _pharmacySubscription?.cancel();
    _pharmacySubscription = null;

    _servicesSubscription?.cancel();
    _servicesSubscription = null;

    _currentStoreId = null;
    print('🛑 Listeners detenidos');
  }

  /// Limpia todos los datos y detiene listeners
  void clearData() {
    stopListening();
    _pharmacyData = TurnScreenData.empty();
    _servicesData = TurnScreenData.empty();
    _isLoadingPharmacy = false;
    _isLoadingServices = false;
    _pharmacyError = null;
    _servicesError = null;
    _isFirstPharmacyLoad = true;
    _isFirstServicesLoad = true;
    notifyListeners();
  }

  /// Obtiene el número de turno que se está atendiendo en Farmacia
  String get currentPharmacyTurn {
    final turn = _pharmacyData.currentlyBeingServed?.turn;
    return turn != null ? 'F$turn' : '--';
  }

  /// Obtiene el número de turno que se está atendiendo en Servicios
  String get currentServicesTurn {
    final turn = _servicesData.currentlyBeingServed?.turn;
    return turn != null ? 'S$turn' : '--';
  }

  /// Obtiene los próximos turnos de Farmacia para mostrar
  List<String> get nextPharmacyTurns {
    return _pharmacyData.waitingQueue
        .take(5) // Mostrar máximo 5 turnos siguientes
        .map((turn) => 'F${turn.turn}')
        .toList();
  }

  /// Obtiene los próximos turnos de Servicios para mostrar
  List<String> get nextServicesTurns {
    return _servicesData.waitingQueue
        .take(5) // Mostrar máximo 5 turnos siguientes
        .map((turn) => 'S${turn.turn}')
        .toList();
  }

  @override
  void dispose() {
    stopListening();
    _turnDisplayService.dispose();
    super.dispose();
  }
}
