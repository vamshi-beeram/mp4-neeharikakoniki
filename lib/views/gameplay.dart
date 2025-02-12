import 'dart:convert';
import 'package:battleships/models/game.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';
import 'login_page.dart';

class GamePlay extends StatefulWidget {
  final String gameId;

  const GamePlay({required this.gameId, super.key});

  @override
  _GamePlayState createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay> {
  Set<String> selectedShips = {};
  Future<GameInfo>? gameInfoFuture;

  @override
  void initState() {
    super.initState();
    gameInfoFuture = _loadGameInfo();
  }

  void _doLogout() async {
    await SessionManager.clearSession();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session timeout')),
    );

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const LoginScreen(),
    ));
  }

  Future<GameInfo> _loadGameInfo() async {
    String token = await SessionManager.getSessionToken();

    final url = Uri.parse('http://165.227.117.48/games/${widget.gameId}');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      "Authorization": token,
    });

    if (response.statusCode == 401) {
      _doLogout();
    }

    Map<String, dynamic> jsonData = json.decode(response.body);

    return GameInfo.fromJson(jsonData);
  }

  Future<void> _submitShot() async {
    String token = await SessionManager.getSessionToken();
    var jsonData = jsonEncode({
      'shot': selectedShips.elementAt(0),
    });
    final url = Uri.parse('http://165.227.117.48/games/${widget.gameId}');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Authorization": token,
      },
      body: jsonData,
    );
    selectedShips.clear();

    if (!mounted) return;
    if (response.statusCode == 401) {
      _doLogout();
    }
    final shotResult = json.decode(response.body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(shotResult["sunk_ship"] ? 'Ship sunk!' : 'No enemy ship hit!'),
      ),
    );

    final response2 = await http.get(url, headers: {
      'Content-Type': 'application/json',
      "Authorization": token,
    });

    if (response2.statusCode == 401) {
      _doLogout();
    }
    final gameData = json.decode(response2.body);
    if (response2.statusCode == 200 &&
        (gameData["status"] == 1 || gameData["status"] == 2)) {
      if (!mounted) return;
      _showResultDialog(context, gameData["status"] == gameData["position"]);
    }
  }

  void _showResultDialog(BuildContext context, bool gameWon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(gameWon ? 'Congratulations!' : 'Game Over'),
          content: Text(gameWon ? 'You won the game!' : 'Sorry, you lost.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double itemWidth = MediaQuery.of(context).size.width / 7;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Battleships'),
      ),
      body: FutureBuilder<GameInfo>(
        future: gameInfoFuture,
        initialData: null,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 0.0,
                          mainAxisSpacing: 0.0,
                        ),
                        itemCount: 36,
                        itemBuilder: (BuildContext context, int index) {
                          String label;

                          if (index == 0) {
                            label = '';
                          } else if (index <= 5) {
                            label = index.toString();
                          } else {
                            label =
                                String.fromCharCode((index / 6).floor() + 64);
                          }

                          if (index <= 5 || index % 6 == 0) {
                            return Container(
                              color: Colors.white,
                              child: Center(
                                child: Text(
                                  label,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          }

                          int row = ((index - 1) / 6).floor();
                          int col = (index - 1) % 6;
                          label =
                              '${String.fromCharCode(row + 65 - 1)}${col + 1}';

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedShips.clear();
                                selectedShips.add(label);
                              });
                            },
                            child: Container(
                              color: selectedShips.contains(label) &&
                                      snapshot.data?.status == 3
                                  ? const Color.fromARGB(255, 235, 110, 110)
                                  : Colors.white,
                              child: Center(
                                child: snapshot.data
                                    ?.getWidgetForPosition(label, itemWidth),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      style: snapshot.data?.status != 3 ||
                              snapshot.data?.turn != snapshot.data?.position
                          ? ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey)
                          : ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                      onPressed: () async {
                        bool canShoot = selectedShips.isNotEmpty &&
                            snapshot.data?.status == 3 &&
                            snapshot.data?.turn == snapshot.data?.position;

                        if (canShoot &&
                            (snapshot.data!.shots
                                    .contains(selectedShips.elementAt(0)) ||
                                snapshot.data!.sunk
                                    .contains(selectedShips.elementAt(0)))) {
                          canShoot = false;
                          selectedShips.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shot already taken!'),
                            ),
                          );
                        }
                        if (canShoot) await _submitShot();
                        setState(() {
                          gameInfoFuture = _loadGameInfo();
                        });
                      },
                      child: const Text('Submit'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
