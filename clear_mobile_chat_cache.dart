// Ajoutez ce code temporairement dans support_screen.dart ou chat_screen.dart

// Dans un FloatingActionButton ou menu de debug:
Future<void> clearChatCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('chat_messages_cache');
  print('✅ Cache mobile supprimé');
  setState(() {
    _messages.clear();
  });
}
