import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  TextEditingController ipController = TextEditingController();
  Socket? socket;
  Timer? helloTimer;
  String logs = '';
  final int port = 4040;

  void addLog(String text) {
    setState(() => logs += '$text\n');
  }

  Future<void> connectToServer() async {
    final ip = ipController.text.trim();
    if (ip.isEmpty) {
      addLog('⚠️ Please enter a server IP');
      return;
    }

    try {
      addLog('🔌 Connecting to $ip:$port...');
      socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 5),
      );
      addLog('✅ Connected to server!');

      socket!.listen(
        (data) {
          final message = String.fromCharCodes(data).trim();
          addLog('📩 Server says: $message');
        },
        onDone: () {
          addLog('❌ Disconnected from server');
        },
      );

      // Send "hello" every 10 seconds
      helloTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        addLog('📤 Sending: hello');
        socket!.write('hello\n');
      });
    } catch (e) {
      addLog('⚠️ Connection failed: $e');
    }
  }

  @override
  void dispose() {
    helloTimer?.cancel();
    socket?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'Server LAN IP Address',
                hintText: 'e.g. 192.168.1.100',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: connectToServer,
              child: const Text('Connect & Start Hello'),
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
