import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_model.dart';

class ServicesApiService {
  static const String _baseUrl =
      'https://getservices-228344336816.us-central1.run.app';

  /// Obtiene la lista de servicios disponibles desde la API
  /// [storeId] - ID de la tienda para filtrar los servicios
  Future<List<ServiceModel>> getServices({required String storeId}) async {
    try {
      final uri = Uri.parse(
        _baseUrl,
      ).replace(queryParameters: {'storeid': storeId});

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => ServiceModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar servicios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Versión mock para desarrollo - eliminar cuando tengas la URL real
  Future<List<ServiceModel>> getServicesMock() async {
    // Simula una llamada a la API
    await Future.delayed(const Duration(seconds: 1));

    final mockData = [
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Atención en Mostrador",
        "type": "Farmacia",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2Fatencion-mostrador.png?alt=media&token=6e3669f6-e874-438b-a264-40244c32c638",
      },
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Asistencia Preferencial",
        "type": "Farmacia",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2Fasistencia-preferencial.png?alt=media&token=b587d40c-61d5-43ac-b195-aeb4b93dadbe",
      },
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Inyectología",
        "type": "Servicio",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2FIcon%20Sizes%20Clarification.png?alt=media&token=62ebdf06-b285-4aa3-9f4c-6e9115ac00c1",
      },
      {
        "SMS": true,
        "active": true,
        "screen": true,
        "name": "Presión Arterial",
        "type": "Servicio",
        "iconUrl":
            "https://firebasestorage.googleapis.com/v0/b/farmaturnos.firebasestorage.app/o/Iconos%2FIcon%20Size%20Clarification.png?alt=media&token=5f65362f-c2d4-47a2-a43a-17279862e37a",
      },
    ];

    return mockData.map((json) => ServiceModel.fromJson(json)).toList();
  }
}
