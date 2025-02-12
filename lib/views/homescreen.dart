// Imports...
import 'dart:convert';
import 'package:battleships/views/gameplay.dart';
import 'drawer.dart';
import 'package:battleships/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/sessionmanager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> futureGames;
  bool showCompleted = false;

  @override
  void initState() {
    super.initState();
    futureGames = _loadGames();
  }

  Future<List<dynamic>> _loadGames() async {
    try {
      final token = await SessionManager.getSessionToken();
      final response =
          await http.get(Uri.parse('http://165.227.117.48/games'), headers: {
        'Authorization': token,
      });
      if (response.statusCode == 401) {
        _logout();
      }
      final games = json.decode(response.body)['games'] ?? [];
      return games;
    } catch (e) {
      throw Exception('Failed to load games: $e');
    }
  }

  Future<void> _logout({bool isSessionTimedOut = true}) async {
    await SessionManager.clearSession();
    if (!mounted) return;
    if (isSessionTimedOut) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Session timeout')));
    }
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _refreshGames(bool showCompltedLoc) async {
    setState(() {
      showCompleted = showCompltedLoc;
      futureGames = _loadGames();
    });
  }

  void _deleteGame(int id) async {
    try {
      final token = await SessionManager.getSessionToken();
      await http.delete(Uri.parse('http://165.227.117.48/games/$id'), headers: {
        'Authorization': token,
      });
      _refreshGames(showCompleted);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to delete game')));
    }
  }

  String _getTrailingMessage(dynamic game) {
    if (game['status'] == 0) {
      return 'Matchmaking';
    } else if (game['status'] == 3) {
      return game['turn'] == game['position'] ? 'Your turn' : 'Opponent turn';
    } else {
      return game['status'] == game['position'] ? 'You won' : 'Opponent won';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => (_refreshGames(showCompleted)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: MyDrawer(
          showCompleted: showCompleted,
          refreshPage: _refreshGames,
          logout: _logout),
      body: FutureBuilder<List<dynamic>>(
        future: futureGames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final games = snapshot.data as List<dynamic>;
            final filteredGames = showCompleted
                ? games
                    .where((game) => game['status'] == 1 || game['status'] == 2)
                    .toList()
                : games
                    .where((game) => game['status'] == 0 || game['status'] == 3)
                    .toList();
            return ListView.builder(
              itemCount: filteredGames.length,
              itemBuilder: (context, index) {
                final game = filteredGames[index];
                return Dismissible(
                  key: Key(game['id'].toString()),
                  onDismissed: (_) => _deleteGame(game['id']),
                  background: Container(
                      color: Colors.red, child: const Icon(Icons.delete)),
                  child: ListTile(
                    onTap: () async {
                      if (game["status"] != 0) {
                        _navigateToGamePlayScreen(game['id'].toString());
                      }
                    },
                    title: Text('#${game['id']}'),
                    subtitle: Text(game['player2'] != null
                        ? '${game['player1']} vs ${game['player2']}'
                        : 'Waiting for opponent'),
                    trailing: Text(_getTrailingMessage(game)),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _navigateToGamePlayScreen(String gameId) async {
    try {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (context) => GamePlay(gameId: gameId),
      ));

      setState(() {
        _refreshGames(showCompleted);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to navigate to game')));
    }
  }
}
