import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: LocalAiTrackerScreen(),
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
    text: "Car oil change done on Aug 10. Next service due Feb 10.",
  );

  Database? _db;
  List<Map<String, dynamic>> _savedLogs = [];
  bool _isLoading = false;
  String _statusMessage = "Ready";

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  // Initialize SQLite database
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'app_memory.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE logs(id INTEGER PRIMARY KEY AUTOINCREMENT, raw_text TEXT, parsed_data TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)',
        );
      },
    );
    _loadLogs();
  }

  // Read saved logs
  Future<void> _loadLogs() async {
    if (_db == null) return;
    final data = await _db!.query('logs', orderBy: 'id DESC');
    setState(() {
      _savedLogs = data;
    });
  }

  // Process text with the downloaded local model
  Future<void> _processAndSave() async {
    if (_inputController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _statusMessage = "Reading local model file...";
    });

    try {
      // Direct path to your Lenovo local storage Download folder
      const modelFilePath = '/storage/emulated/0/Download/gemma-2b-it-gpu-int4.bin';

      await FlutterGemmaPlugin.instance.loadModel(path: modelFilePath);

      setState(() => _statusMessage = "Analyzing text locally...");

      final prompt = '''
Extract key details (event, date, due date, amount) from this text. 
Return concise summary:
Text: "${_inputController.text}"
''';

      final response = await FlutterGemmaPlugin.instance.getResponse(prompt);
      final parsedOutput = response ?? "Could not extract data.";

      // Insert extracted output to SQLite
      if (_db != null) {
        await _db!.insert('logs', {
          'raw_text': _inputController.text,
          'parsed_data': parsedOutput,
        });
      }

      _inputController.clear();
      await _loadLogs();

      setState(() {
        _statusMessage = "Saved log to database!";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local AI Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAlignment.start,
          children: [
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'Enter reminder or paste text',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _processAndSave,
                icon: const Icon(Icons.memory),
                label: Text(_isLoading ? 'Processing...' : 'Analyze & Save'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $_statusMessage',
              style: TextStyle(
                color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 32),
            const Text(
              'Saved Logs:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _savedLogs.isEmpty
                  ? const Center(child: Text('No logs recorded yet.'))
                  : ListView.builder(
                      itemCount: _savedLogs.length,
                      itemBuilder: (context, index) {
                        final item = _savedLogs[index];
                        return Card(
                          child: ListTile(
                            title: Text(item['raw_text'] ?? ''),
                            subtitle: Text(
                              item['parsed_data'] ?? '',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
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
