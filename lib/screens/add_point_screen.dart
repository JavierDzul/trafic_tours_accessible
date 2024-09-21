import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddPointScreen extends StatefulWidget {
  final LatLng position;

  const AddPointScreen({super.key, required this.position});

  @override
  _AddPointScreenState createState() => _AddPointScreenState();
}

class _AddPointScreenState extends State<AddPointScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Punto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre del Punto'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final newPoint = MapPoint(
                  name: _nameController.text,
                  description: _descriptionController.text,
                  position: widget.position,
                );
                Navigator.of(context).pop(newPoint);
              },
              child: const Text('Guardar Punto'),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase para guardar información de los puntos
class MapPoint {
  final String name;
  final String description;
  final LatLng position;

  MapPoint({
    required this.name,
    required this.description,
    required this.position,
  });
}

// Clase para definir rutas
class RoutePoint {
  final int id;
  final List<MapPoint> points;

  RoutePoint({required this.id, required this.points});
}
