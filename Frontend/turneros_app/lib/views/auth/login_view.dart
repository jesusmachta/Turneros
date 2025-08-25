import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../controllers/auth_controller.dart';
import '../home/home_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002858), // Azul oscuro especificado
      body: Consumer<AuthController>(
        builder: (context, authController, child) {
          // Si está autenticado, navegar al home
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authController.isAuthenticated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeView()),
              );
            }
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Espaciado superior
                  const Spacer(flex: 2),

                  // Título principal
                  const Text(
                    'Inicio de Sesión App de Turnos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  // Espaciado
                  const SizedBox(height: 60),

                  // Botón de Google Sign In
                  if (authController.isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                  else
                    _buildGoogleSignInButton(context, authController),

                  // Mensaje de error
                  if (authController.errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authController.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () => authController.clearError(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Espaciado inferior
                  const Spacer(flex: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    AuthController authController,
  ) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleGoogleSignIn(context, authController),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de Google
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://developers.google.com/identity/images/g-logo.png',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Texto del botón
                const Text(
                  'Iniciar Sesión con Google',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002858),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(
    BuildContext context,
    AuthController authController,
  ) async {
    // Limpiar errores anteriores
    authController.clearError();

    // Realizar autenticación
    final success = await authController.signInWithGoogle();

    if (success && context.mounted) {
      // La navegación se maneja automáticamente en el Consumer
      Fluttertoast.showToast(
        msg: '¡Bienvenido ${authController.currentUser?.storeName}!',
        backgroundColor: Colors.green,
        textColor: Colors.white,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
