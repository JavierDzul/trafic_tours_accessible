import 'package:flutter/material.dart';
import 'package:trafic_tours_accessible/screens/map_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 2.0).animate(_controller);

    _controller.forward();

    // Navegar a la siguiente pantalla después de 3 segundos
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MapScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF394f5c),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset(
              'assets/images/logo.jpg'), // Asegúrate de tener tu imagen en esta ruta
        ),
      ),
    );
  }
}
