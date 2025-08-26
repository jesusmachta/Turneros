import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/turn_model.dart';

/// Servicio para manejar los datos de la pantalla de turnos
class TurnDisplayService {
  // URLs base para los endpoints
  static const String _pharmacyLastAttendedUrl =
      'https://lasttobeattended-228344336816.us-central1.run.app';
  static const String _pharmacyWaitingUrl =
      'https://waitingpharmacy-228344336816.us-central1.run.app';
  static const String _servicesLastAttendedUrl =
      'https://lasttobeattendedservices-228344336816.us-central1.run.app';
  static const String _servicesWaitingUrl =
      'https://waitinginservices-228344336816.us-central1.run.app';

  /// Obtiene los datos de turnos para Farmacia
  Future<TurnScreenData> getPharmacyTurns(int storeId) async {
    try {
      print('🏥 Obteniendo datos de turnos para Farmacia - Store ID: $storeId');

      // Hacer ambas llamadas en paralelo
      final results = await Future.wait([
        _getLastAttended(_pharmacyLastAttendedUrl, storeId),
        _getWaitingQueue(_pharmacyWaitingUrl, storeId),
      ]);

      final currentlyServed = results[0] as TurnModel?;
      final waitingQueue = results[1] as List<TurnModel>;

      print('✅ Farmacia - Atendiendo: ${currentlyServed?.turn ?? 'Ninguno'}');
      print('✅ Farmacia - En espera: ${waitingQueue.length} turnos');

      return TurnScreenData(
        currentlyBeingServed: currentlyServed,
        waitingQueue: waitingQueue,
      );
    } catch (e) {
      print('❌ Error obteniendo datos de Farmacia: $e');
      throw Exception('Error al obtener datos de turnos de Farmacia: $e');
    }
  }

  /// Obtiene los datos de turnos para Servicios Farmacéuticos
  Future<TurnScreenData> getServicesTurns(int storeId) async {
    try {
      print(
        '💊 Obteniendo datos de turnos para Servicios - Store ID: $storeId',
      );

      // Hacer ambas llamadas en paralelo
      final results = await Future.wait([
        _getLastAttended(_servicesLastAttendedUrl, storeId),
        _getWaitingQueue(_servicesWaitingUrl, storeId),
      ]);

      final currentlyServed = results[0] as TurnModel?;
      final waitingQueue = results[1] as List<TurnModel>;

      print('✅ Servicios - Atendiendo: ${currentlyServed?.turn ?? 'Ninguno'}');
      print('✅ Servicios - En espera: ${waitingQueue.length} turnos');

      return TurnScreenData(
        currentlyBeingServed: currentlyServed,
        waitingQueue: waitingQueue,
      );
    } catch (e) {
      print('❌ Error obteniendo datos de Servicios: $e');
      throw Exception('Error al obtener datos de turnos de Servicios: $e');
    }
  }

  /// Obtiene el último turno atendido
  Future<TurnModel?> _getLastAttended(String baseUrl, int storeId) async {
    try {
      final uri = Uri.parse('$baseUrl?storeid=$storeId');

      print('📡 Llamando a: $uri');

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
              throw Exception('Tiempo de espera agotado');
            },
          );

      print('📊 Respuesta lastAttended - Código: ${response.statusCode}');
      print('📄 Respuesta lastAttended - Body: ${response.body}');

      if (response.statusCode == 200) {
        final String body = response.body.trim();

        // Si la respuesta está vacía o es null, no hay nadie siendo atendido
        if (body.isEmpty || body == 'null') {
          return null;
        }

        try {
          final Map<String, dynamic> data = json.decode(body);
          return TurnModel.fromJson(data);
        } catch (e) {
          print('⚠️ Error parseando JSON de lastAttended: $e');
          return null;
        }
      } else if (response.statusCode == 404) {
        // No hay nadie siendo atendido actualmente
        return null;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en _getLastAttended: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Sin conexión a internet');
      }
      rethrow;
    }
  }

  /// Obtiene la cola de espera
  Future<List<TurnModel>> _getWaitingQueue(String baseUrl, int storeId) async {
    try {
      final uri = Uri.parse('$baseUrl?storeid=$storeId');

      print('📡 Llamando a: $uri');

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
              throw Exception('Tiempo de espera agotado');
            },
          );

      print('📊 Respuesta waiting - Código: ${response.statusCode}');
      print('📄 Respuesta waiting - Body: ${response.body}');

      if (response.statusCode == 200) {
        final String body = response.body.trim();

        // Si la respuesta está vacía o es un array vacío
        if (body.isEmpty || body == '[]' || body == 'null') {
          return [];
        }

        try {
          final List<dynamic> data = json.decode(body);
          return data.map((item) => TurnModel.fromJson(item)).toList();
        } catch (e) {
          print('⚠️ Error parseando JSON de waiting: $e');
          return [];
        }
      } else if (response.statusCode == 404) {
        // No hay cola de espera
        return [];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en _getWaitingQueue: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Sin conexión a internet');
      }
      rethrow;
    }
  }
}
