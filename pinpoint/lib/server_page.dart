import 'dart:io';
import 'package:flutter/material.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  ServerSocket? _serverSocket;
  String logs = '';
  final int port = 4040;
  String localIp = 'Detecting...';

  @override
  void initState() {
    super.initState();
    _findLocalIp();
  }

  /// Get the device's actual LAN IP (not 0.0.0.0 or loopback)
  Future<void> _findLocalIp() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              (addr.address.startsWith('192.') ||
                  addr.address.startsWith('172.') ||
                  addr.address.startsWith('10.'))) {
            setState(() => localIp = addr.address);
            return;
          }
        }
      }
      setState(() => localIp = 'Could not find LAN IP');
    } catch (e) {
      setState(() => localIp = 'Error getting IP: $e');
    }
  }

  void addLog(String text) {
    setState(() => logs += '$text\n');
  }

  Future<void> startServer() async {
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      addLog('✅ Server started on IP: $localIp  Port: $port');

      _serverSocket!.listen((client) {
        addLog('🔗 Client connected: ${client.remoteAddress.address}');
        client.listen(
          (data) {
            final msg = String.fromCharCodes(data).trim();
            addLog('📩 From Client: $msg');
            if (msg == 'hello') {
              client.write('hello from server\n');
            }
          },
          onDone: () {
            addLog('❌ Client disconnected');
          },
        );
      });
    } catch (e) {
      addLog('⚠️ Server error: $e');
    }
  }

  @override
  void dispose() {
    _serverSocket?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Server')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📡 LAN IP: $localIp',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: startServer,
              child: const Text('Start Server'),
            ),
            const SizedBox(height: 10),
            const Text('Logs:'),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                width: double.infinity,
                child: SingleChildScrollView(child: Text(logs)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
