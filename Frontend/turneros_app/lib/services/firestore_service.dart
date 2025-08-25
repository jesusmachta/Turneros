import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'Users';

  /// Guarda un usuario en Firestore
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));

      print('✅ Usuario guardado en Firestore: ${user.email}');
    } catch (e) {
      print('❌ Error al guardar usuario en Firestore: $e');
      throw Exception('Error al guardar datos del usuario');
    }
  }

  /// Obtiene un usuario desde Firestore
  Future<UserModel?> getUser(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromMap(data);
      }

      return null;
    } catch (e) {
      print('❌ Error al obtener usuario de Firestore: $e');
      throw Exception('Error al obtener datos del usuario');
    }
  }

  /// Actualiza el último login del usuario
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).update({
        'lastLogin': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error al actualizar último login: $e');
      // No lanzamos excepción porque esto no es crítico
    }
  }

  /// Verifica si un usuario existe en Firestore
  Future<bool> userExists(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection(_usersCollection).doc(uid).get();

      return doc.exists;
    } catch (e) {
      print('❌ Error al verificar existencia de usuario: $e');
      return false;
    }
  }
}
