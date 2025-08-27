import 'dart:async';
import 'package:flutter/material.dart';
import '../models/queue_client_model.dart';
import '../models/service_model.dart';
import '../services/queue_service.dart';

/// Controlador para manejar las colas de espera y atención usando streams
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

  // Subscripciones a los streams
  final Map<QueueType, StreamSubscription<List<QueueClientModel>>>
  _subscriptions = {};

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

  /// Inicializa el controlador con el storeId usando streams
  void initialize(int storeId) {
    _storeId = storeId;
    _startListening();
  }

  /// Inicia la escucha de todos los streams de las colas
  void _startListening() {
    if (_storeId == null) return;

    _setLoading(true);
    _error = null;

    print(
      '🚀 Iniciando listeners para gestión de clientes - Store ID: $_storeId',
    );

    final streams = _queueService.getAllQueueStreams(_storeId!);

    // Configurar listener para farmacia en espera
    _subscriptions[QueueType
        .pharmacyWaiting] = streams[QueueType.pharmacyWaiting]!.listen(
      (clients) {
        _pharmacyWaiting = clients;
        _setLoading(false);
        notifyListeners();
        print('✅ Farmacia en espera: ${clients.length} clientes');
      },
      onError: (error) {
        _handleStreamError('Farmacia en espera', error);
      },
    );

    // Configurar listener para farmacia atendiendo
    _subscriptions[QueueType
        .pharmacyAttending] = streams[QueueType.pharmacyAttending]!.listen(
      (clients) {
        _pharmacyAttending = clients;
        _setLoading(false);
        notifyListeners();
        print('✅ Farmacia atendiendo: ${clients.length} clientes');
      },
      onError: (error) {
        _handleStreamError('Farmacia atendiendo', error);
      },
    );

    // Configurar listener para servicios en espera
    _subscriptions[QueueType.pharmaceuticalServicesWaiting] =
        streams[QueueType.pharmaceuticalServicesWaiting]!.listen(
          (clients) {
            _pharmaceuticalServicesWaiting = clients;
            _setLoading(false);
            notifyListeners();
            print('✅ Servicios en espera: ${clients.length} clientes');
          },
          onError: (error) {
            _handleStreamError('Servicios en espera', error);
          },
        );

    // Configurar listener para servicios atendiendo
    _subscriptions[QueueType.pharmaceuticalServicesAttending] =
        streams[QueueType.pharmaceuticalServicesAttending]!.listen(
          (clients) {
            _pharmaceuticalServicesAttending = clients;
            _setLoading(false);
            notifyListeners();
            print('✅ Servicios atendiendo: ${clients.length} clientes');
          },
          onError: (error) {
            _handleStreamError('Servicios atendiendo', error);
          },
        );

    // Configurar listener para picking RX pendiente
    _subscriptions[QueueType
        .pickingRxPending] = streams[QueueType.pickingRxPending]!.listen(
      (clients) {
        _pickingRxPending = clients;
        _setLoading(false);
        notifyListeners();
        print('✅ Picking RX pendiente: ${clients.length} clientes');
      },
      onError: (error) {
        _handleStreamError('Picking RX pendiente', error);
      },
    );

    // Configurar listener para picking RX preparado
    _subscriptions[QueueType
        .pickingRxPrepared] = streams[QueueType.pickingRxPrepared]!.listen(
      (clients) {
        _pickingRxPrepared = clients;
        _setLoading(false);
        notifyListeners();
        print('✅ Picking RX preparado: ${clients.length} clientes');
      },
      onError: (error) {
        _handleStreamError('Picking RX preparado', error);
      },
    );
  }

  /// Maneja errores de los streams
  void _handleStreamError(String streamName, dynamic error) {
    _setLoading(false);
    _error = 'Error en $streamName: $error';
    print('❌ Error en stream $streamName: $error');
    notifyListeners();
  }

  /// Recarga manualmente los datos (ahora solo reinicia los listeners)
  Future<void> refresh() async {
    if (_storeId != null) {
      _stopListening();
      _startListening();
    }
  }

  /// Detiene todos los listeners activos
  void _stopListening() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    print('🛑 Listeners de gestión de clientes detenidos');
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
        // Los datos se actualizarán automáticamente via streams
        print('✅ Acción completada: iniciar atención farmacia');
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
        // Los datos se actualizarán automáticamente via streams
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
        // Los datos se actualizarán automáticamente via streams
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
        // Los datos se actualizarán automáticamente via streams
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
        // Los datos se actualizarán automáticamente via streams
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
        // Los datos se actualizarán automáticamente via streams
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
        // Los datos se actualizarán automáticamente via streams
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
    _stopListening();
    _queueService.dispose();
    super.dispose();
  }
}
