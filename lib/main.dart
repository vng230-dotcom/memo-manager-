import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memo Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LocalAiTrackerScreen(),
    );
  }
}

class LocalAiTrackerScreen extends StatefulWidget {
  const LocalAiTrackerScreen({super.key});

  @override
  State<LocalAiTrackerScreen> createState() => _LocalAiTrackerScreenState();
}

class _LocalAiTrackerScreenState extends State<LocalAiTrackerScreen> {
  final TextEditingController _inputController = TextEditingController(
    text: "Car oil change done on Aug 10",
  );

  final List<String> _logs = [];

  void _addLog() {
    if (_inputController.text.trim().isNotEmpty) {
      setState(() {
        _logs.add(_inputController.text.trim());
        _inputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Manager'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'Enter log note',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addLog,
              child: const Text('Save Note'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Saved Notes:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _logs.isEmpty
                  ? const Text('No notes added yet.')
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            title: Text(_logs[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
