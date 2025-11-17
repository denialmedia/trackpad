import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';

void main() {
  runApp(const TrackpadApp());
}

class TrackpadApp extends StatelessWidget {
  const TrackpadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackPAD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
      ),
      home: const TrackpadPage(),
    );
  }
}

class TrackpadPage extends StatefulWidget {
  const TrackpadPage({super.key});

  @override
  _TrackpadPageState createState() => _TrackpadPageState();
}

class _TrackpadPageState extends State<TrackpadPage> {
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.1.100',
  );
  String? _serverIp;
  final int _serverPort = 5005;
  RawDatagramSocket? _socket;
  Offset? _lastPosition;

  @override
  void dispose() {
    _socket?.close();
    _ipController.dispose();
    super.dispose();
  }

  void _initializeSocket() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid IP address')),
      );
      return;
    }

    _serverIp = ip;
    RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)
        .then((socket) {
          setState(() {
            _socket = socket;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Connected to $ip')));
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $error')));
        });
  }

  void _sendMessage(String message) {
    if (_socket != null && _serverIp != null) {
      final address = InternetAddress(_serverIp!);
      _socket!.send(message.codeUnits, address, _serverPort);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastPosition != null) {
      final deltaX = details.globalPosition.dx - _lastPosition!.dx;
      final deltaY = details.globalPosition.dy - _lastPosition!.dy;
      _sendMessage('MOVE:${deltaX.toInt()}:${deltaY.toInt()}');
    }
    _lastPosition = details.globalPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPosition = null;
  }

  void _onPanDown(DragDownDetails details) {
    _lastPosition = details.globalPosition;
  }

  void _onTapDown(TapDownDetails details) {
    // Reset last position to avoid small pan triggers
    _lastPosition = details.globalPosition;
  }

  void _onTap() {
    _sendMessage('CLICK:0:0');
  }

  void _onLongPress() {
    _sendMessage('RIGHT_CLICK:0:0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackPAD'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'PC IP Address (e.g., 192.168.1.100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeSocket,
              child: const Text('Connect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  onPanDown: _onPanDown,
                  onTapDown: _onTapDown,
                  onTap: _onTap,
                  onLongPress: _onLongPress,
                  child: const Center(
                    child: Text(
                      'Touch here\n(Tap: Click, Drag: Move, Long Press: Right Click)',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
