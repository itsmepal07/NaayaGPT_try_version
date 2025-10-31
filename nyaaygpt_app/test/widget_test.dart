import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MaterialApp(home: TestAPIPage()));
}

class TestAPIPage extends StatefulWidget {
  const TestAPIPage({super.key});

  @override
  State<TestAPIPage> createState() => _TestAPIPageState();
}

class _TestAPIPageState extends State<TestAPIPage> {
  final TextEditingController _controller = TextEditingController();
  String _response = "";
  bool _loading = false;

  Future<void> _testAPI() async {
    setState(() => _loading = true);

    try {
      final uri = Uri.parse("http://10.0.2.2:8000/ask"); // emulator
      // use http://127.0.0.1:8000/ask for mac desktop build

      final res = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"question": _controller.text}),
      );

      if (res.statusCode == 200) {
        setState(() => _response = json.decode(res.body)['answer'] ?? "No answer");
      } else {
        setState(() => _response = "Error ${res.statusCode}");
      }
    } catch (e) {
      setState(() => _response = "⚠️ Connection failed: $e");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("API Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter test question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loading ? null : _testAPI,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Request"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _response,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
