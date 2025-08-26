import 'package:flutter/foundation.dart';
import '../models/turn_model.dart';
import '../services/turn_display_service.dart';
import '../services/audio_service.dart';

/// Controlador para manejar el estado de la pantalla de turnos
class TurnDisplayController extends ChangeNotifier {
  final TurnDisplayService _turnDisplayService = TurnDisplayService();
  final AudioService _audioService = AudioService();

  bool _soundPlayedInCycle = false;

  // Estado para Farmacia
  TurnScreenData _pharmacyData = TurnScreenData.empty();
  bool _isLoadingPharmacy = false;
  String? _pharmacyError;

  // Estado para Servicios Farmacéuticos
  TurnScreenData _servicesData = TurnScreenData.empty();
  bool _isLoadingServices = false;
  String? _servicesError;

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

  /// Carga los datos de turnos para ambas secciones
  Future<void> loadAllTurnsData(int storeId) async {
    print('🔄 Cargando datos de turnos para store ID: $storeId');
    _soundPlayedInCycle = false; // Reset flag at the start of refresh cycle

    // Cargar ambos en paralelo
    await Future.wait([loadPharmacyData(storeId), loadServicesData(storeId)]);
  }

  /// Carga los datos de turnos para Farmacia
  Future<void> loadPharmacyData(int storeId) async {
    try {
      _isLoadingPharmacy = true;
      _pharmacyError = null;
      notifyListeners();

      print('🏥 Cargando datos de Farmacia...');
      final data = await _turnDisplayService.getPharmacyTurns(storeId);

      if (_pharmacyData != data) {
        if (!_soundPlayedInCycle) {
          _audioService.playAttendSound();
          _soundPlayedInCycle = true;
        }
        _pharmacyData = data;
      }
      print('✅ Datos de Farmacia cargados exitosamente');
    } catch (e) {
      _pharmacyError = e.toString();
      print('❌ Error cargando datos de Farmacia: $e');
    } finally {
      _isLoadingPharmacy = false;
      notifyListeners();
    }
  }

  /// Carga los datos de turnos para Servicios Farmacéuticos
  Future<void> loadServicesData(int storeId) async {
    try {
      _isLoadingServices = true;
      _servicesError = null;
      notifyListeners();

      print('💊 Cargando datos de Servicios...');
      final data = await _turnDisplayService.getServicesTurns(storeId);

      if (_servicesData != data) {
        if (!_soundPlayedInCycle) {
          _audioService.playAttendSound();
          _soundPlayedInCycle = true;
        }
        _servicesData = data;
      }
      print('✅ Datos de Servicios cargados exitosamente');
    } catch (e) {
      _servicesError = e.toString();
      print('❌ Error cargando datos de Servicios: $e');
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  /// Refresca todos los datos
  Future<void> refreshData(int storeId) async {
    print('🔄 Refrescando todos los datos de turnos...');
    await loadAllTurnsData(storeId);
  }

  /// Limpia todos los datos
  void clearData() {
    _pharmacyData = TurnScreenData.empty();
    _servicesData = TurnScreenData.empty();
    _isLoadingPharmacy = false;
    _isLoadingServices = false;
    _pharmacyError = null;
    _servicesError = null;
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
}
