import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({super.key});

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  final List<Map<String, String>> _messages = [];
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  bool _loading = false;
  bool _isSpeaking = false; // 👈 NEW FLAG
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    // Detect when speaking ends (to hide stop button automatically)
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _isSpeaking = true);

    await _flutterTts.setLanguage("en-US"); // restore to old-style English
    await _flutterTts.setVoice({"name": "en-us-x-sfg-local", "locale": "en-US"});
    await _flutterTts.setPitch(0.9);
    await _flutterTts.setSpeechRate(0.85);
    await _flutterTts.speak(text);
  }


  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
            });
          },
        );
      } else {
        setState(() => _isListening = false);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_recognizedText.isNotEmpty) {
        await _sendMessage(_recognizedText);
      }
    }
  }

  Future<void> _sendMessage(String question) async {
    if (question.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _loading = true;
      _recognizedText = '';
    });

    try {
      final uri = Uri.parse('http://127.0.0.1:8000/ask');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': question}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final botReply = data['answer'] ?? 'No response received.';
        setState(() {
          _messages.add({'role': 'bot', 'text': botReply});
        });
        await _speak(botReply);
      } else {
        setState(() {
          _messages.add({'role': 'bot', 'text': 'Error: ${response.statusCode}'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': '⚠️ Failed to connect to backend.'});
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    bool isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LawBot — Voice Chat'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFEDE7F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildMessage(_messages[index]),
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 12),
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 12),
                    Text('LawBot is responding...', style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),

            if (_recognizedText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '"$_recognizedText"',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ),

            // 🎙️ Microphone + Stop Speaking button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _listen,
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor:
                            _isListening ? Colors.redAccent : Colors.deepPurple,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 👇 Show stop speaking button only when bot is talking
                    if (_isSpeaking)
                      ElevatedButton.icon(
                        onPressed: _stopSpeaking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Stop Speaking'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
