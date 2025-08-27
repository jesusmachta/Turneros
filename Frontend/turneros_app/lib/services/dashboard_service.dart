import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/// Servicio para manejar las métricas del dashboard usando Firestore real-time
class DashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // StreamControllers para manejar los streams de métricas
  final Map<String, StreamController<DashboardStats>> _controllers = {};

  // Referencias a los listeners para poder cancelarlos
  final Map<String, List<StreamSubscription>> _listeners = {};

  // URLs legacy para cloud functions (mantenemos por compatibilidad)
  static const String _clientesFinalizadosUrl =
      'clientesfinalizados-228344336816.us-central1.run.app';
  static const String _clientesAtendiendoUrl =
      'clientesatendiendo-228344336816.us-central1.run.app';
  static const String _clientesEsperaUrl =
      'clientesespera-228344336816.us-central1.run.app';
  static const String _clientesCanceladosUrl =
      'clientescancelados-228344336816.us-central1.run.app';
  static const String _waitingTimeUrl =
      'us-central1-farmaturnos.cloudfunctions.net/waitingTime';

  /// Obtiene un stream de estadísticas del dashboard usando Firestore real-time
  Stream<DashboardStats> getDashboardStatsStream(int storeId) {
    final controllerKey = 'dashboard_$storeId';

    // Si ya existe un controller para este store, lo retornamos
    if (_controllers.containsKey(controllerKey)) {
      return _controllers[controllerKey]!.stream;
    }

    // Crear nuevo controller
    final controller = StreamController<DashboardStats>.broadcast();
    _controllers[controllerKey] = controller;

    // Variables para almacenar las métricas actuales
    int pharmacyAtendidos = 0,
        pharmacyAtencion = 0,
        pharmacyEspera = 0,
        pharmacyCancelados = 0;
    int servicesAtendidos = 0,
        servicesAtencion = 0,
        servicesEspera = 0,
        servicesCancelados = 0;
    double pharmacyAvgWait = 0.0, servicesAvgWait = 0.0;

    // Función para emitir las estadísticas combinadas
    void emitStats() {
      if (!controller.isClosed) {
        final totalAtendidos = pharmacyAtendidos + servicesAtendidos;
        final totalAtencion = pharmacyAtencion + servicesAtencion;
        final totalEspera = pharmacyEspera + servicesEspera;
        final totalCancelados = pharmacyCancelados + servicesCancelados;

        // Promedio ponderado del tiempo de espera
        final totalWaitTime =
            totalAtendidos > 0
                ? ((pharmacyAtendidos * pharmacyAvgWait) +
                        (servicesAtendidos * servicesAvgWait)) /
                    totalAtendidos
                : 0.0;

        controller.add(
          DashboardStats(
            clientesAtendidos: totalAtendidos,
            clientesEnAtencion: totalAtencion,
            clientesEnEspera: totalEspera,
            clientesCancelados: totalCancelados,
            tiempoPromedioEspera: totalWaitTime,
          ),
        );

        print(
          '✅ Métricas actualizadas: A=$totalAtendidos, E=$totalAtencion, Es=$totalEspera, C=$totalCancelados, T=${totalWaitTime.toStringAsFixed(1)}min',
        );
      }
    }

    final listeners = <StreamSubscription>[];

    // Listener para Turns_Pharmacy
    final pharmacyListener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_Pharmacy')
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final metrics = _calculateMetrics(snapshot);
              pharmacyAtendidos = metrics['atendidos']! as int;
              pharmacyAtencion = metrics['atencion']! as int;
              pharmacyEspera = metrics['espera']! as int;
              pharmacyCancelados = metrics['cancelados']! as int;
              pharmacyAvgWait = metrics['avgWaitTime']!.toDouble();

              print(
                '📊 Farmacia - A:$pharmacyAtendidos, E:$pharmacyAtencion, Es:$pharmacyEspera, C:$pharmacyCancelados, T:${pharmacyAvgWait.toStringAsFixed(1)}min',
              );
              emitStats();
            } catch (e) {
              print('❌ Error procesando métricas de Farmacia: $e');
            }
          },
          onError: (error) {
            print('❌ Error en listener de Pharmacy: $error');
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    // Listener para Turns_Services
    final servicesListener = _firestore
        .collection('Turns_Store')
        .doc(storeId.toString())
        .collection('Turns_Services')
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final metrics = _calculateMetrics(snapshot);
              servicesAtendidos = metrics['atendidos']! as int;
              servicesAtencion = metrics['atencion']! as int;
              servicesEspera = metrics['espera']! as int;
              servicesCancelados = metrics['cancelados']! as int;
              servicesAvgWait = metrics['avgWaitTime']!.toDouble();

              print(
                '📊 Servicios - A:$servicesAtendidos, E:$servicesAtencion, Es:$servicesEspera, C:$servicesCancelados, T:${servicesAvgWait.toStringAsFixed(1)}min',
              );
              emitStats();
            } catch (e) {
              print('❌ Error procesando métricas de Servicios: $e');
            }
          },
          onError: (error) {
            print('❌ Error en listener de Services: $error');
            if (!controller.isClosed) {
              controller.addError(error);
            }
          },
        );

    listeners.addAll([pharmacyListener, servicesListener]);

    // Guardar referencias a los listeners
    _listeners[controllerKey] = listeners;

    return controller.stream;
  }

  /// Calcula las métricas para una colección específica
  Map<String, num> _calculateMetrics(QuerySnapshot snapshot) {
    int atendidos = 0;
    int atencion = 0;
    int espera = 0;
    int cancelados = 0;
    List<double> waitTimes = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final state = data['state'] as String?;

      switch (state) {
        case 'Finalizado':
          atendidos++;
          // Calcular tiempo de espera para turnos finalizados
          final waitTime = _calculateWaitTime(data);
          if (waitTime != null) {
            waitTimes.add(waitTime);
          }
          break;
        case 'Atendiendo':
          atencion++;
          break;
        case 'Esperando':
          espera++;
          break;
        case 'Cancelado':
          cancelados++;
          break;
      }
    }

    final avgWaitTime =
        waitTimes.isNotEmpty
            ? waitTimes.reduce((a, b) => a + b) / waitTimes.length
            : 0.0;

    return {
      'atendidos': atendidos,
      'atencion': atencion,
      'espera': espera,
      'cancelados': cancelados,
      'avgWaitTime': avgWaitTime,
    };
  }

  /// Calcula el tiempo de espera para un turno específico
  double? _calculateWaitTime(Map<String, dynamic> data) {
    try {
      final createdAt = data['Created_At'];
      final servedAt = data['Served_At'];

      if (createdAt != null && servedAt != null) {
        final createdTime = (createdAt as Timestamp).toDate();
        final servedTime = (servedAt as Timestamp).toDate();
        final waitMinutes =
            servedTime.difference(createdTime).inMinutes.toDouble();

        return waitMinutes >= 0 ? waitMinutes : null;
      }
    } catch (e) {
      print('Error calculando tiempo de espera: $e');
    }
    return null;
  }

  /// Obtiene el número de clientes atendidos
  Future<int> getClientesAtendidos(int storeId) async {
    try {
      final url = Uri.https(_clientesFinalizadosUrl, '', {
        'storeid': storeId.toString(),
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total_clients_finalizado'] ?? 0;
      } else {
        throw Exception(
          'Error al obtener clientes atendidos: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getClientesAtendidos: $e');
      return 0;
    }
  }

  /// Obtiene el número de clientes en atención
  Future<int> getClientesEnAtencion(int storeId) async {
    try {
      final url = Uri.https(_clientesAtendiendoUrl, '', {
        'storeid': storeId.toString(),
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total_clients_atendiendo'] ?? 0;
      } else {
        throw Exception(
          'Error al obtener clientes en atención: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getClientesEnAtencion: $e');
      return 0;
    }
  }

  /// Obtiene el número de clientes en espera
  Future<int> getClientesEnEspera(int storeId) async {
    try {
      final url = Uri.https(_clientesEsperaUrl, '', {
        'storeid': storeId.toString(),
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total_clients_esperando'] ?? 0;
      } else {
        throw Exception(
          'Error al obtener clientes en espera: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getClientesEnEspera: $e');
      return 0;
    }
  }

  /// Obtiene el número de clientes cancelados
  Future<int> getClientesCancelados(int storeId) async {
    try {
      final url = Uri.https(_clientesCanceladosUrl, '', {
        'storeid': storeId.toString(),
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total_clients_cancelado'] ?? 0;
      } else {
        throw Exception(
          'Error al obtener clientes cancelados: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getClientesCancelados: $e');
      return 0;
    }
  }

  /// Obtiene el tiempo promedio de espera
  Future<double> getTiempoPromedioDespera(int storeId) async {
    try {
      final url = Uri.https(_waitingTimeUrl, '', {
        'storeid': storeId.toString(),
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['average_wait_time_minutes'] ?? 0.0).toDouble();
      } else {
        throw Exception(
          'Error al obtener tiempo de espera: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error en getTiempoPromedioDespera: $e');
      return 0.0;
    }
  }

  /// Método legacy - Obtiene todas las estadísticas del dashboard
  Future<DashboardStats> getDashboardStats(int storeId) async {
    try {
      print(
        '⚠️ Método getDashboardStats() legacy - considera usar getDashboardStatsStream()',
      );

      final results = await Future.wait([
        getClientesAtendidos(storeId),
        getClientesEnAtencion(storeId),
        getClientesEnEspera(storeId),
        getClientesCancelados(storeId),
        getTiempoPromedioDespera(storeId),
      ]);

      return DashboardStats(
        clientesAtendidos: results[0] as int,
        clientesEnAtencion: results[1] as int,
        clientesEnEspera: results[2] as int,
        clientesCancelados: results[3] as int,
        tiempoPromedioEspera: results[4] as double,
      );
    } catch (e) {
      print('Error en getDashboardStats: $e');
      return DashboardStats.empty();
    }
  }

  /// Cancela todos los listeners y libera recursos
  void dispose() {
    print('🧹 Liberando recursos de DashboardService');

    // Cancelar todos los listeners
    for (final listenerList in _listeners.values) {
      for (final listener in listenerList) {
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
    final controllerKey = 'dashboard_$storeId';

    final listeners = _listeners[controllerKey];
    if (listeners != null) {
      for (final listener in listeners) {
        listener.cancel();
      }
      _listeners.remove(controllerKey);
    }

    final controller = _controllers.remove(controllerKey);
    if (controller != null && !controller.isClosed) {
      controller.close();
    }
  }
}

/// Modelo para las estadísticas del dashboard
class DashboardStats {
  final int clientesAtendidos;
  final int clientesEnAtencion;
  final int clientesEnEspera;
  final int clientesCancelados;
  final double tiempoPromedioEspera;

  DashboardStats({
    required this.clientesAtendidos,
    required this.clientesEnAtencion,
    required this.clientesEnEspera,
    required this.clientesCancelados,
    required this.tiempoPromedioEspera,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      clientesAtendidos: 0,
      clientesEnAtencion: 0,
      clientesEnEspera: 0,
      clientesCancelados: 0,
      tiempoPromedioEspera: 0.0,
    );
  }
}
