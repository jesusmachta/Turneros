import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio para manejar las llamadas a cloud functions del dashboard
class DashboardService {
  // URLs de los cloud functions
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

  /// Obtiene el número de clientes atendidos
  Future<int> getClientesAtendidos(int storeId) async {
    try {
      final url = Uri.https(_clientesFinalizadosUrl, '', {
        'storeid': storeId.toString(),
      });
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total_clients_atendiendo'] ?? 0;
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

  /// Obtiene todas las estadísticas del dashboard
  Future<DashboardStats> getDashboardStats(int storeId) async {
    try {
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
