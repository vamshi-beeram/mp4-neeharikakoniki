import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';
import 'login_page.dart';

class NewGameScreen extends StatefulWidget {
  final bool isAgainstAI;
  final String typeOfAI;

  const NewGameScreen({
    required this.isAgainstAI,
    required this.typeOfAI,
    super.key,
  });

  @override
  _NewGameScreenState createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final Set<String> selectedShips = <String>{};

  void _logout() async {
    await SessionManager.clearSession();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session timeout')),
    );

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ));
  }

  Future<void> _submitGame() async {
    final String token = await SessionManager.getSessionToken();
    final List<String> shipList = selectedShips.toList();
    final jsonData = jsonEncode({
      'ships': shipList,
      if (widget.isAgainstAI) 'ai': widget.typeOfAI,
    });
    final url = Uri.parse('http://165.227.117.48/games');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonData,
    );
    if (response.statusCode == 401) {
      _logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Ships'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 0.0,
                    mainAxisSpacing: 0.0,
                  ),
                  itemCount: 36,
                  itemBuilder: (BuildContext context, int index) {
                    if (index <= 5 || index % 6 == 0) {
                      return _buildLabelCell(index);
                    }
                    return _buildShipCell(index);
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedShips.length != 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Please select 5 ships to submit the game'),
                      ),
                    );
                  } else {
                    await _submitGame();
                    if (!mounted) return;
                    Navigator.pop(context);
                  }
                },
                child: const Text('Submit'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelCell(int index) {
    String label;
    if (index == 0) {
      label = '';
    } else if (index <= 5) {
      label = index.toString();
    } else {
      label = String.fromCharCode((index / 6).floor() + 64);
    }
    return Container(
      color: Colors.white10,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildShipCell(int index) {
    final int row = ((index - 1) / 6).floor();
    final int col = (index - 1) % 6;
    final String label = '${String.fromCharCode(row + 65 - 1)}${col + 1}';
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedShips.contains(label)) {
            selectedShips.remove(label);
          } else {
            selectedShips.add(label);
          }
        });
      },
      child: Container(
        color: selectedShips.contains(label) ? Colors.green : Colors.white10,
      ),
    );
  }
}
