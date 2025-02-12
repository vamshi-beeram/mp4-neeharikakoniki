import 'package:flutter/material.dart';
import 'package:battleships/utils/sessionmanager.dart';
import 'package:battleships/views/new_game.dart';

class MyDrawer extends StatelessWidget {
  final void Function(bool) refreshPage;
  final void Function({bool isSessionTimedOut}) logout;
  final bool showCompleted;

  const MyDrawer({
    required this.showCompleted,
    required this.refreshPage,
    required this.logout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getUsername(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final String username = snapshot.data ?? '';

          return Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerHeader(username),
                _buildListTile(
                  title: "New Game",
                  onTap: () => _navigateToNewGameScreen(context,
                      isAgainstAI: false, typeOfAI: ""),
                ),
                _buildListTile(
                  title: "New game (AI)",
                  onTap: () async {
                    await showOptionsDialog(context);
                    if (!context.mounted) return;
                    refreshPage(showCompleted);
                    Navigator.pop(context);
                  },
                ),
                _buildListTile(
                  title: showCompleted ? "Show active games" : "Show Completed",
                  onTap: () => refreshPage(!showCompleted),
                ),
                _buildListTile(
                  title: "Log out",
                  onTap: () => logout(isSessionTimedOut: false),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildDrawerHeader(String username) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.blue),
      curve: Curves.fastOutSlowIn,
      child: ListTile(
        title: const Text('Battleships'),
        subtitle: Text('Logged in as: $username'),
      ),
    );
  }

  Widget _buildListTile({required String title, required VoidCallback onTap}) {
    return ListTile(
      title: Text(title),
      onTap: onTap,
    );
  }

  Future<void> _navigateToNewGameScreen(BuildContext context,
      {required bool isAgainstAI, required String typeOfAI}) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => NewGameScreen(
          isAgainstAI: isAgainstAI,
          typeOfAI: typeOfAI,
        ),
      ),
    );
    if (!context.mounted) return;
    refreshPage(showCompleted);
    Navigator.pop(context);
  }

  Future<void> showOptionsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Which AI do you want to play against?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const NewGameScreen(
                        isAgainstAI: true,
                        typeOfAI: "random",
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Random'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const NewGameScreen(
                        isAgainstAI: true,
                        typeOfAI: "perfect",
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Perfect'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const NewGameScreen(
                        isAgainstAI: true,
                        typeOfAI: "oneship",
                      ),
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('One ship (AI)'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> _getUsername() async {
    return await SessionManager.getSessionUserName();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
