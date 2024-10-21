import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  void _loadThemeMode() {
    setState(() {
      _themeMode = widget.prefs.getBool('isDarkMode') ?? false ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      widget.prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Gemini Multi-Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: ChatListScreen(toggleTheme: toggleTheme, prefs: widget.prefs),
    );
  }
}

class Chat {
  String id;
  String name;
  List<ChatMessage> messages;
  DateTime lastModified;
  String category;

  Chat({
    required this.id,
    required this.name,
    this.messages = const [],
    DateTime? lastModified,
    this.category = 'Non classé',
  }) : lastModified = lastModified ?? DateTime.now();

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      name: json['name'],
      messages: (json['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList(),
      lastModified: DateTime.parse(json['lastModified']),
      category: json['category'] ?? 'Non classé',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastModified': lastModified.toIso8601String(),
      'category': category,
    };
  }
}

class ChatListScreen extends StatefulWidget {
  final Function toggleTheme;
  final SharedPreferences prefs;

  const ChatListScreen({Key? key, required this.toggleTheme, required this.prefs}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Chat> chats = [];
  List<Chat> filteredChats = [];
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'Toutes';
  List<String> categories = ['Toutes', 'Non classé'];

  @override
  void initState() {
    super.initState();
    _loadChats();
    searchController.addListener(_filterChats);
  }

  void _loadChats() {
    final chatList = widget.prefs.getStringList('chats') ?? [];
    setState(() {
      chats = chatList.map((chatJson) => Chat.fromJson(json.decode(chatJson))).toList();
      filteredChats = List.from(chats);
    });
  }

  void _saveChats() {
    final chatList = chats.map((chat) => json.encode(chat.toJson())).toList();
    widget.prefs.setStringList('chats', chatList);
  }

  void _filterChats() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredChats = chats.where((chat) {
        final nameMatch = chat.name.toLowerCase().contains(query);
        final contentMatch = chat.messages.any((msg) => msg.text.toLowerCase().contains(query));
        final categoryMatch = selectedCategory == 'Toutes' || chat.category == selectedCategory;
        return (nameMatch || contentMatch) && categoryMatch;
      }).toList();
    });
  }

  void _createNewChat() {
    final newChat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Nouveau chat ${chats.length + 1}',
    );
    setState(() {
      chats.add(newChat);
      _updateCategories();
      _filterChats();
      _saveChats();
    });
    _openChat(newChat);
  }

  void _updateCategories() {
    Set<String> uniqueCategories = {'Toutes', 'Non classé'};
    for (var chat in chats) {
      uniqueCategories.add(chat.category);
    }
    categories = uniqueCategories.toList();
  }

  void _changeChatCategory(Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCategory = chat.category;
        return AlertDialog(
          title: const Text('Changer la catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: newCategory,
                items: categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    newCategory = value;
                  }
                },
              ),
              TextField(
                decoration: const InputDecoration(hintText: "Ou créer une nouvelle catégorie"),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    newCategory = value;
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Changer'),
              onPressed: () {
                setState(() {
                  chat.category = newCategory;
                  _updateCategories();
                  _filterChats();
                  _saveChats();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chat: chat, onUpdate: _updateChat),
      ),
    );
  }

  void _updateChat(Chat updatedChat) {
    setState(() {
      final index = chats.indexWhere((chat) => chat.id == updatedChat.id);
      if (index != -1) {
        chats[index] = updatedChat;
        _filterChats();
        _saveChats();
      }
    });
  }

  void _renameChat(Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = chat.name;
        return AlertDialog(
          title: const Text('Renommer le chat'),
          content: TextField(
            onChanged: (value) {
              newName = value;
            },
            decoration: const InputDecoration(hintText: "Nouveau nom du chat"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Renommer'),
              onPressed: () {
                setState(() {
                  chat.name = newName;
                  chat.lastModified = DateTime.now();
                  _filterChats();
                  _saveChats();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteChat(Chat chat) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le chat'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${chat.name}" ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Supprimer'),
              onPressed: () {
                setState(() {
                  chats.removeWhere((c) => c.id == chat.id);
                  _filterChats();
                  _saveChats();
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats Gemini'),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: () {
              widget.toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCategory = newValue;
                    _filterChats();
                  });
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                final chat = filteredChats[index];
                return ListTile(
                  title: Text(chat.name),
                  subtitle: Text(
                    '${chat.messages.length} messages - ${chat.category}\nModifié le ${DateFormat('dd/MM/yyyy HH:mm').format(chat.lastModified)}',
                  ),
                  onTap: () => _openChat(chat),
                  trailing: PopupMenuButton<String>(
                    onSelected: (String result) {
                      if (result == 'rename') {
                        _renameChat(chat);
                      } else if (result == 'delete') {
                        _deleteChat(chat);
                      } else if (result == 'category') {
                        _changeChatCategory(chat);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'rename',
                        child: Text('Renommer'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'category',
                        child: Text('Changer la catégorie'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewChat,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Chat chat;
  final Function(Chat) onUpdate;

  const ChatScreen({Key? key, required this.chat, required this.onUpdate}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = 'AIzaSyD_Dh7Ea2QTyK3kl1MDFWz_4UWYw81JAGE';
  late List<ChatMessage> _messages;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.chat.messages);
  }

  Future<String> _getGeminiResponse(String prompt) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{"parts":[{"text": prompt}]}]
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Failed to get response: ${response.statusCode}\n${response.body}');
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = ChatMessage(
      text: _controller.text,
      isUser: true,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    String userMessageText = _controller.text;
    _controller.clear();

    try {
      String response = await _getGeminiResponse(userMessageText);
      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });

      widget.onUpdate(Chat(
        id: widget.chat.id,
        name: widget.chat.name,
        messages: _messages,
        lastModified: DateTime.now(),
      ));
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Erreur: ${e.toString()}",
          isUser: false,
        ));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat.name),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _messages[index];
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre message...',
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
  }) : super(key: key);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) 
            Container(
              margin: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                child: const Text('G'),
                backgroundColor: isDarkMode ? Colors.blueGrey : Colors.blue,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(isUser ? 'Vous' : 'Gemini',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isUser 
                      ? (isDarkMode ? Colors.blueGrey[700] : Colors.blue[100])
                      : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                child: const Text('V'),
                backgroundColor: isDarkMode ? Colors.blueGrey : Colors.blue,
              ),
            ),
        ],
      ),
    );
  }
}