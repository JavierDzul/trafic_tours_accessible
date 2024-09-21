import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:trafic_tours_accessible/screens/add_point_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final List<MapPoint> _savedPoints = []; // Puntos individuales
  final List<RoutePoint> _savedRoutes = []; // Lista de rutas
  StreamSubscription<Position>? _positionStream;
  final List<Polyline> _polylines = []; // Polilíneas para las rutas
  bool _isRouteMode = false; // Modo ruta
  bool _ttsEnabled = false; // Modo texto a voz
  final FlutterTts _flutterTts = FlutterTts(); // Text-to-Speech
  RoutePoint? _currentRoute; // Ruta activa
  MapPoint? _lastAnnouncedPoint; // Último punto anunciado
  RoutePoint? _activeRouteToFollow; // Ruta que el usuario está siguiendo
  BitmapDescriptor?
      _routeNodeIcon; // Icono personalizado para los nodos de ruta

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
    _checkLocationPermission();
  }

  // Cargar ícono personalizado para los nodos de ruta
  Future<void> _loadCustomMarkerIcon() async {
    _routeNodeIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue); // Icono azul para los nodos
  }

  // Pedir permiso de ubicación
  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Los servicios de ubicación están deshabilitados. Actívelos para continuar.'),
      ));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Permisos de ubicación denegados. No se puede proceder sin permisos.'),
        ));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Permisos de ubicación denegados permanentemente. Habilítelos en la configuración.'),
      ));
      return;
    }

    _getLocationUpdates();
  }

  // Obtener la ubicación actual
  void _getLocationUpdates() async {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null) {
        _mapController
            ?.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
      }

      if (_ttsEnabled) {
        _announceNearestPoint();
      }

      if (_activeRouteToFollow != null) {
        _trackActiveRoute(); // Verificar si sigue la ruta
      }
    });
  }

  // Función para leer el punto más cercano (puntos y nodos de rutas) con TTS
  Future<void> _announceNearestPoint() async {
    if (_currentPosition == null) return;

    final nearbyPoints =
        _getNearbyPoints(_currentPosition!, 100); // Rango de 100 metros
    final nearbyRouteNodes = _getNearbyRouteNodes(
        _currentPosition!, 100); // Rango de 100 metros para nodos de rutas

    if (nearbyPoints.isNotEmpty || nearbyRouteNodes.isNotEmpty) {
      // Unir los puntos y nodos cercanos para encontrar el más cercano
      final allNearbyPoints = [...nearbyPoints, ...nearbyRouteNodes];
      MapPoint nearestPoint = allNearbyPoints.reduce((curr, next) {
        double currDistance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            curr.position.latitude,
            curr.position.longitude);
        double nextDistance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            next.position.latitude,
            next.position.longitude);
        return (currDistance < nextDistance) ? curr : next;
      });

      if (_lastAnnouncedPoint == null ||
          _lastAnnouncedPoint!.name != nearestPoint.name) {
        _lastAnnouncedPoint = nearestPoint;
        await _flutterTts.speak(
            "Estás cerca del punto: ${nearestPoint.name}. Descripción: ${nearestPoint.description}");
      }
    }
  }

  // Función para verificar si estás siguiendo correctamente la ruta activa
  void _trackActiveRoute() {
    if (_activeRouteToFollow != null && _currentPosition != null) {
      final routePoints =
          _activeRouteToFollow!.points.map((p) => p.position).toList();
      double closestDistance = double.infinity;

      for (final point in routePoints) {
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          point.latitude,
          point.longitude,
        );
        if (distance < closestDistance) {
          closestDistance = distance;
        }
      }

      if (closestDistance > 30) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Te estás alejando de la ruta activa.'),
        ));
        _flutterTts.speak(
            "Te estás alejando de la ruta, por favor regresa a la ruta marcada.");
      }
    }
  }

  // Dibujar la ruta actual
  void _drawCurrentRoute() {
    if (_currentRoute != null && _currentRoute!.points.length > 1) {
      List<LatLng> routePoints =
          _currentRoute!.points.map((point) => point.position).toList();

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('route_${_currentRoute!.id}'),
            color: Colors.green, // Color diferente para las rutas
            width: 5,
            points: routePoints,
          ),
        );
      });
    }
  }

  // Obtener puntos cercanos
  List<MapPoint> _getNearbyPoints(
      LatLng currentLocation, double rangeInMeters) {
    return _savedPoints.where((point) {
      final distance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        point.position.latitude,
        point.position.longitude,
      );
      return distance <= rangeInMeters;
    }).toList();
  }

  // Obtener nodos de rutas cercanos
  List<MapPoint> _getNearbyRouteNodes(
      LatLng currentLocation, double rangeInMeters) {
    List<MapPoint> nearbyRouteNodes = [];
    for (final route in _savedRoutes) {
      for (final point in route.points) {
        final distance = Geolocator.distanceBetween(
          currentLocation.latitude,
          currentLocation.longitude,
          point.position.latitude,
          point.position.longitude,
        );
        if (distance <= rangeInMeters) {
          nearbyRouteNodes.add(point);
        }
      }
    }
    return nearbyRouteNodes;
  }

  // Crear una nueva ruta
  void _startNewRoute() {
    final newRoute = RoutePoint(id: _savedRoutes.length + 1, points: []);
    setState(() {
      _currentRoute = newRoute;
      _savedRoutes.add(newRoute);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Nueva ruta iniciada')));
  }

  // Añadir un punto a la ruta actual o como punto individual
  Future<void> _addPoint() async {
    if (_currentPosition == null) return;

    final MapPoint? newPoint = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPointScreen(position: _currentPosition!),
      ),
    );

    if (newPoint != null) {
      setState(() {
        if (_isRouteMode && _currentRoute != null) {
          _currentRoute!.points.add(newPoint);
          _drawCurrentRoute();
        } else {
          _savedPoints.add(newPoint); // Punto individual
        }
      });
    }
  }

  // Finalizar la ruta actual
  void _finishRoute() {
    if (_currentRoute != null && _currentRoute!.points.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ruta ${_currentRoute!.id} guardada con éxito')),
      );
      setState(() {
        _currentRoute = null; // Terminar la ruta actual
      });
    }
  }

  // Seleccionar una ruta para seguir
  void _selectRouteToFollow(RoutePoint route) {
    setState(() {
      _activeRouteToFollow = route;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Has seleccionado la ruta ${route.id} para seguir.'),
      ));
      _flutterTts.speak('Has seleccionado la ruta para seguir.');
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // Dibujar puntos individuales en el mapa
  Set<Marker> _getMarkers() {
    return _savedPoints.map((point) {
      return Marker(
        markerId: MarkerId(point.name),
        position: point.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor
            .hueRed), // Usar el icono predeterminado rojo para puntos
        infoWindow: InfoWindow(
          title: point.name,
          snippet: point.description,
        ),
      );
    }).toSet();
  }

  // Dibujar los nodos (puntos) de las rutas
  Set<Marker> _getRouteMarkers() {
    Set<Marker> routeMarkers = {};
    for (final route in _savedRoutes) {
      for (final point in route.points) {
        routeMarkers.add(Marker(
          markerId: MarkerId('route_${route.id}_point_${point.name}'),
          position: point.position,
          icon: _routeNodeIcon!, // Usar icono azul para nodos de ruta
          infoWindow: InfoWindow(
            title: 'Ruta ${route.id} - ${point.name}',
            snippet: point.description,
          ),
        ));
      }
    }
    return routeMarkers;
  }

  // Dibujar las rutas guardadas en el mapa
  List<Polyline> _getRoutePolylines() {
    List<Polyline> routePolylines = [];
    for (final route in _savedRoutes) {
      if (route.points.length > 1) {
        routePolylines.add(
          Polyline(
            polylineId: PolylineId('route_${route.id}'),
            color: Colors.green,
            width: 5,
            points: route.points.map((point) => point.position).toList(),
          ),
        );
      }
    }
    return routePolylines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trafic Tours Access'),
        backgroundColor: const Color.fromARGB(192, 87, 191, 247),
        actions: [
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                final nearbyPoints = _getNearbyPoints(_currentPosition!, 500);
                showModalBottomSheet(
                  context: context,
                  builder: (context) => ListView.builder(
                    itemCount: nearbyPoints.length,
                    itemBuilder: (context, index) {
                      final point = nearbyPoints[index];
                      return ListTile(
                        title: Text(point.name),
                        subtitle: Text(point.description),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 16.0,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  markers: _getMarkers().union(
                      _getRouteMarkers()), // Mostrar puntos y nodos de ruta
                  polylines: Set<Polyline>.of(
                      _getRoutePolylines()), // Mostrar las rutas guardadas
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                Positioned(
                  bottom: 80,
                  left: 20,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        onPressed: _addPoint,
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        backgroundColor:
                            _isRouteMode ? Colors.green : Colors.blue,
                        onPressed: () {
                          setState(() {
                            _isRouteMode = !_isRouteMode;
                            if (_isRouteMode) {
                              _startNewRoute();
                            } else {
                              _finishRoute();
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isRouteMode
                                    ? 'Modo Ruta Activado: Añadiendo puntos a la ruta.'
                                    : 'Ruta finalizada.',
                              ),
                            ),
                          );
                        },
                        child: Icon(_isRouteMode ? Icons.route : Icons.place),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        backgroundColor:
                            _ttsEnabled ? Colors.green : Colors.blue,
                        onPressed: () {
                          setState(() {
                            _ttsEnabled = !_ttsEnabled;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _ttsEnabled
                                    ? 'Texto a Voz Activado: Se leerán los puntos cercanos.'
                                    : 'Texto a Voz Desactivado.',
                              ),
                            ),
                          );
                        },
                        child: Icon(
                            _ttsEnabled ? Icons.volume_up : Icons.volume_off),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
