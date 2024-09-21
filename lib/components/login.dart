import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_pantalla_carga.jpg', // Reemplaza con la imagen que desees usar.
              fit: BoxFit.cover,
            ),
          ),
          // Degradado sobre la imagen
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black
                        .withOpacity(0.3), // Más oscuro en la parte superior
                    Colors.white
                        .withOpacity(0.9), // Más claro en la parte inferior
                  ],
                ),
              ),
            ),
          ),
          // Contenido sobre el fondo
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Texto principal
                  const Text(
                    'Toda la info de\naccesibilidad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Texto secundario
                  const Text(
                    'Encontrá toda la información de la accesibilidad de los alojamientos, '
                    'gastronomía, atractivos, transporte y más.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Indicador (puedes modificar según sea necesario)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.orange),
                      Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
                      Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
                    ],
                  ),
                  const Spacer(),
                  // Botón Iniciar sesión
                  OutlinedButton(
                    onPressed: () {
                      // Lógica para iniciar sesión
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.orange),
                    ),
                    child: const Text(
                      'Iniciar sesión',
                      style: TextStyle(color: Colors.orange, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón Registrarse
                  ElevatedButton(
                    onPressed: () {
                      // Lógica para registrarse
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      'Registrarse',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
