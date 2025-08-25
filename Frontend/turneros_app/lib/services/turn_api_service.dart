import 'dart:convert';
import 'package:http/http.dart' as http;

class TurnApiService {
  static const String _baseUrl =
      'https://createturn-228344336816.us-central1.run.app';

  /// Crea un nuevo turno
  Future<Map<String, dynamic>> createTurn({
    required int storeId,
    required String name,
    required String type,
    required int cedula,
    required String documento,
    required String country,
  }) async {
    try {
      final url = Uri.parse(_baseUrl);

      final body = {
        'storeid': storeId,
        'name': name,
        'type': type,
        'cedula': cedula,
        'documento': documento,
        'country': country,
      };

      print('🚀 Enviando solicitud de turno:');
      print('URL: $url');
      print('Body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📡 Respuesta del servidor:');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        // Intentar decodificar el error del servidor
        String errorMessage = 'Error al crear el turno';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Error del servidor: ${response.statusCode}';
        }

        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      print('❌ Error en createTurn: $e');
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    }
  }
}
