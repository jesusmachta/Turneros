import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';
import 'api_service.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Solo especificar clientId en plataformas que no sean web
    clientId:
        kIsWeb
            ? null
            : '228344336816-vinfojvhf5e39iuvr7fuhk7e40acdstf.apps.googleusercontent.com',
  );
  final ApiService _apiService = ApiService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Inicia sesión con Google y valida la tienda
  Future<UserModel> signInWithGoogle() async {
    try {
      // 1. Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado por el usuario');
      }

      // 2. Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Autenticar con Firebase
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      final User? user = result.user;

      if (user == null || user.email == null) {
        throw Exception('Error al obtener información del usuario');
      }

      // 4. Validar tienda en la API
      final StoreInfo storeInfo = await _apiService.validateStore(user.email!);

      // 5. Crear modelo de usuario con datos individuales
      final userModel = UserModel.fromAuthAndStore(
        uid: user.uid,
        email: user.email!,
        displayName: user.displayName ?? '',
        photoURL: user.photoURL,
        storeId: storeInfo.storeId,
        country: storeInfo.country,
        storeName: storeInfo.storeName,
        coordenada: storeInfo.coordenada,
        area: storeInfo.area,
        region: storeInfo.region,
        rol: 'Tienda',
      );

      // 6. Guardar en Firestore
      await _firestoreService.saveUser(userModel);

      return userModel;
    } catch (e) {
      // Si hay un error, cerrar sesión de Google y Firebase
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Proporcionar más contexto sobre el error
      print('❌ Error detallado en signInWithGoogle: $e');
      if (e.toString().contains('popup_closed_by_user')) {
        throw Exception('Inicio de sesión cancelado por el usuario');
      } else if (e.toString().contains('network_error')) {
        throw Exception('Error de red. Verifique su conexión a internet');
      } else if (e.toString().contains('CLIENT_ID')) {
        throw Exception('Error de configuración. Contacte al administrador');
      }

      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  /// Obtener usuario actual desde Firestore
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;

    return await _firestoreService.getUser(user.uid);
  }
}
