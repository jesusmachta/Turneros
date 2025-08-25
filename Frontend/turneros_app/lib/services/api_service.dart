import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_model.dart';

class ApiService {
  static const String _baseUrl =
      'https://querrystoreid-228344336816.us-central1.run.app';

  /// Valida si una tienda existe en el sistema
  Future<StoreInfo> validateStore(String email) async {
    try {
      final uri = Uri.parse('$_baseUrl?email=$email');

      print('🔍 Validando tienda para email: $email');
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
              throw Exception('Tiempo de espera agotado al validar la tienda');
            },
          );

      print('📊 Código de respuesta: ${response.statusCode}');
      print('📄 Respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Validar que el JSON contenga los campos requeridos
        if (!data.containsKey('storeid') || !data.containsKey('storename')) {
          throw Exception('Respuesta de la API incompleta');
        }

        final storeInfo = StoreInfo.fromJson(data);
        print(
          '✅ Tienda válida: ${storeInfo.storeName} (ID: ${storeInfo.storeId})',
        );

        return storeInfo;
      } else if (response.statusCode == 404) {
        throw StoreNotFoundException(
          'La tienda con email $email no fue encontrada',
        );
      } else if (response.statusCode >= 500) {
        throw Exception('Error del servidor. Por favor, intente más tarde');
      } else {
        throw Exception('Error al validar la tienda: ${response.statusCode}');
      }
    } catch (e) {
      if (e is StoreNotFoundException) {
        rethrow;
      }

      print('❌ Error al validar tienda: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        throw Exception('Sin conexión a internet. Verifique su conexión');
      }

      throw Exception('Error al validar la tienda: ${e.toString()}');
    }
  }
}

/// Excepción específica cuando no se encuentra la tienda
class StoreNotFoundException implements Exception {
  final String message;
  StoreNotFoundException(this.message);

  @override
  String toString() => message;
}
