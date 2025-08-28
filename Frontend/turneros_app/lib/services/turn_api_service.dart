import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para crear turnos usando Firestore directo (Real-time optimizado)
class TurnApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crea un nuevo turno con Firestore directo (transacción atómica)
  Future<Map<String, dynamic>> createTurn({
    required int storeId,
    required String name,
    required String type,
    required int cedula,
    required String documento,
    required String country,
  }) async {
    try {
      print('🚀 Creando turno con Firestore directo:');
      print('Store: $storeId, Name: $name, Type: $type, Cedula: $cedula');

      // Validar tipo
      if (type != 'Farmacia' && type != 'Servicio') {
        return {
          'success': false,
          'error': "El tipo debe ser 'Farmacia' o 'Servicio'",
        };
      }

      int assignedTurnNumber = 0;
      String newTurnId = '';

      // Ejecutar creación en transacción atómica para consistencia
      await _firestore.runTransaction((transaction) async {
        final storeRef = _firestore
            .collection('Turns_Store')
            .doc(storeId.toString());

        // Determinar campos según el tipo
        final isFarmacia = type == 'Farmacia';
        final counterField = isFarmacia ? 'Turns_Pharmacy' : 'Turns_Services';
        final subcollectionName =
            isFarmacia ? 'Turns_Pharmacy' : 'Turns_Services';

        // Leer documento de la tienda
        final storeDoc = await transaction.get(storeRef);
        if (!storeDoc.exists) {
          throw Exception('La tienda con ID $storeId no fue encontrada');
        }

        final storeData = storeDoc.data()!;
        final currentTurnNumber = storeData[counterField] ?? 1;
        assignedTurnNumber = currentTurnNumber;

        // Crear nuevo documento de turno
        final newTurnRef = storeRef.collection(subcollectionName).doc();
        newTurnId = newTurnRef.id;

        final newTurnData = {
          'storeid': storeId,
          'comes_from': name,
          'cedula': cedula,
          'documento': documento,
          'country': country,
          'Turn': currentTurnNumber,
          'state': 'Esperando',
          'Created_At': FieldValue.serverTimestamp(),
        };

        // Realizar escrituras en la transacción
        transaction.set(newTurnRef, newTurnData);
        transaction.update(storeRef, {counterField: currentTurnNumber + 1});

        print('✅ Turno #$currentTurnNumber creado con ID: $newTurnId');
      });

      // Respuesta exitosa compatible con la API anterior
      return {
        'success': true,
        'data': {
          'success': true,
          'message':
              'Turno #$assignedTurnNumber creado exitosamente para el tipo \'$type\'.',
          'assignedTurn': assignedTurnNumber,
          'storeid': storeId,
          'turnNumber': assignedTurnNumber,
          'turnId': newTurnId,
        },
      };
    } catch (e) {
      print('❌ Error al crear turno con Firestore: $e');

      if (e.toString().contains('no fue encontrada')) {
        return {'success': false, 'error': e.toString()};
      } else {
        return {'success': false, 'error': 'Error al crear el turno: $e'};
      }
    }
  }
}
