import 'dart:async';
import 'package:flutter/material.dart';
import '../models/queue_client_model.dart';
import '../models/service_model.dart';
import '../services/queue_service.dart';

/// Controlador para manejar las colas de espera y atención
class QueueController extends ChangeNotifier {
  final QueueService _queueService = QueueService();

  // Listas para cada tipo de cola
  List<QueueClientModel> _pharmacyWaiting = [];
  List<QueueClientModel> _pharmacyAttending = [];
  List<QueueClientModel> _pharmaceuticalServicesWaiting = [];
  List<QueueClientModel> _pharmaceuticalServicesAttending = [];
  List<QueueClientModel> _pickingRxPending = [];
  List<QueueClientModel> _pickingRxPrepared = [];

  bool _isLoading = false;
  String? _error;
  int? _storeId;
  Timer? _refreshTimer;

  // Getters
  List<QueueClientModel> get pharmacyWaiting => _pharmacyWaiting;
  List<QueueClientModel> get pharmacyAttending => _pharmacyAttending;
  List<QueueClientModel> get pharmaceuticalServicesWaiting =>
      _pharmaceuticalServicesWaiting;
  List<QueueClientModel> get pharmaceuticalServicesAttending =>
      _pharmaceuticalServicesAttending;
  List<QueueClientModel> get pickingRxPending => _pickingRxPending;
  List<QueueClientModel> get pickingRxPrepared => _pickingRxPrepared;

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Inicializa el controlador con el storeId
  void initialize(int storeId) {
    _storeId = storeId;
    loadQueueData();
    startAutoRefresh(); // Iniciar auto-refresh
  }

  /// Carga todos los datos de las colas
  Future<void> loadQueueData() async {
    if (_storeId == null) return;

    _setLoading(true);
    _error = null;

    try {
      final queueData = await _queueService.getAllQueueData(_storeId!);

      _pharmacyWaiting = queueData[QueueType.pharmacyWaiting] ?? [];
      _pharmacyAttending = queueData[QueueType.pharmacyAttending] ?? [];
      _pharmaceuticalServicesWaiting =
          queueData[QueueType.pharmaceuticalServicesWaiting] ?? [];
      _pharmaceuticalServicesAttending =
          queueData[QueueType.pharmaceuticalServicesAttending] ?? [];
      _pickingRxPending = queueData[QueueType.pickingRxPending] ?? [];
      _pickingRxPrepared = queueData[QueueType.pickingRxPrepared] ?? [];

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error en loadQueueData: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Recarga manualmente los datos
  Future<void> refresh() async {
    await loadQueueData();
  }

  /// Actualiza automáticamente los datos cada cierto tiempo
  void startAutoRefresh({Duration interval = const Duration(seconds: 30)}) {
    stopAutoRefresh(); // Cancelar timer anterior si existe
    _refreshTimer = Timer.periodic(interval, (timer) {
      loadQueueData();
    });
  }

  /// Para el auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ===========================================
  // MÉTODOS PARA LAS ACCIONES DE LOS BOTONES
  // ===========================================

  /// Inicia la atención de un cliente en farmacia
  Future<void> startAttendingPharmacy(QueueClientModel client) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.startAttendingPharmacy(
        _storeId!,
        client.id,
      );

      if (success) {
        // Recargar datos para mostrar los cambios
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al iniciar atención: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Inicia la atención de un cliente en servicios farmacéuticos
  Future<void> startAttendingService(QueueClientModel client) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.startAttendingService(
        _storeId!,
        client.id,
      );

      if (success) {
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al iniciar atención: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Finaliza la atención de un cliente en farmacia
  Future<void> finishAttendingPharmacy(QueueClientModel client) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.finishAttendingPharmacy(
        _storeId!,
        client.id,
      );

      if (success) {
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al finalizar atención: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Finaliza la atención de un cliente en servicios farmacéuticos
  Future<void> finishAttendingService(QueueClientModel client) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.finishAttendingService(
        _storeId!,
        client.id,
      );

      if (success) {
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al finalizar atención: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Cancela un turno en farmacia
  Future<void> cancelTurnPharmacy(QueueClientModel client) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.cancelTurnPharmacy(
        _storeId!,
        client.id,
      );

      if (success) {
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al cancelar turno: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Cancela un turno en servicios farmacéuticos
  Future<void> cancelTurnService(QueueClientModel client) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.cancelTurnService(
        _storeId!,
        client.id,
      );

      if (success) {
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al cancelar turno: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene los servicios activos para transferencia
  Future<List<ServiceModel>> getActiveServices() async {
    if (_storeId == null) return [];

    try {
      return await _queueService.getActiveServices(_storeId!);
    } catch (e) {
      _error = 'Error al obtener servicios: $e';
      notifyListeners();
      return [];
    }
  }

  /// Transfiere un cliente a un servicio
  Future<void> transferToService(
    QueueClientModel client,
    ServiceModel service,
  ) async {
    if (_storeId == null) return;

    try {
      _setLoading(true);
      final success = await _queueService.transferToService(
        _storeId!,
        client.id,
        service.name,
        service.type,
      );

      if (success) {
        await loadQueueData();
      }
    } catch (e) {
      _error = 'Error al transferir cliente: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
