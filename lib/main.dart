import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'config.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 35,
              height: 35,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    isUser ? 'Vous' : 'Gemini',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? (isDark ? Colors.blue.shade700 : Colors.blue.shade500)
                        : (isDark ? const Color(0xFF2D2D2D) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(!isUser ? 4 : 20),
                      topRight: Radius.circular(isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            Container(
              width: 35,
              height: 35,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'V',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
class ChatListScreen extends StatefulWidget {
  final void Function() toggleTheme;
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      _updateCategories();
    });
  }

  void _saveChats() {
    final chatList = chats.map((chat) => json.encode(chat.toJson())).toList();
    widget.prefs.setStringList('chats', chatList);
  }

  void _updateCategories() {
    Set<String> uniqueCategories = {'Toutes', 'Non classé'};
    for (var chat in chats) {
      uniqueCategories.add(chat.category);
    }
    setState(() {
      categories = uniqueCategories.toList();
    });
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

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chat: chat,
          onUpdate: _updateChat,
        ),
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
      builder: (context) => RenameChatDialog(
        currentName: chat.name,
        onRename: (String newName) {
          setState(() {
            chat.name = newName;
            chat.lastModified = DateTime.now();
            _filterChats();
            _saveChats();
          });
        },
      ),
    );
  }

  void _changeChatCategory(Chat chat) {
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(
        currentCategory: chat.category,
        categories: categories,
        onChangeCategory: (String newCategory) {
          setState(() {
            chat.category = newCategory;
            _updateCategories();
            _filterChats();
            _saveChats();
          });
        },
      ),
    );
  }

  void _deleteChat(Chat chat) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        chatName: chat.name,
        onConfirm: () {
          setState(() {
            chats.removeWhere((c) => c.id == chat.id);
            _filterChats();
            _saveChats();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          title: Text(
            'Gemini Chat',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              onPressed: widget.toggleTheme,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un chat...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF3D3D3D) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 16,
                      ),
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
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredChats.length,
                itemBuilder: (context, index) {
                  final chat = filteredChats[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openChat(chat),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          chat.name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                        onSelected: (String result) {
                                          if (result == 'rename') {
                                            _renameChat(chat);
                                          } else if (result == 'delete') {
                                            _deleteChat(chat);
                                          } else if (result == 'category') {
                                            _changeChatCategory(chat);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => [
                                          PopupMenuItem<String>(
                                            value: 'rename',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.edit, size: 20),
                                                SizedBox(width: 8),
                                                Text('Renommer'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'category',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.category, size: 20),
                                                SizedBox(width: 8),
                                                Text('Catégorie'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: const [
                                                Icon(Icons.delete, size: 20),
                                                SizedBox(width: 8),
                                                Text('Supprimer'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (chat.messages.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black.withOpacity(0.2)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                chat.messages.last.isUser ? Icons.person : Icons.smart_toy,
                                                size: 14,
                                                color: isDark ? Colors.white38 : Colors.black38,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                chat.messages.last.isUser ? 'Vous' : 'Gemini',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? Colors.white38 : Colors.black38,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chat.messages.last.text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.blue.withOpacity(0.2)
                                              : Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          chat.category,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.message,
                                        size: 16,
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${chat.messages.length}',
                                        style: TextStyle(
                                          color: isDark ? Colors.white38 : Colors.black38,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(chat.lastModified),
                                        style: TextStyle(
                                          color: isDark ? Colors.white38 : Colors.black38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewChat,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau chat'),
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
  final String apiKey = Config.apiKey;
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
        category: widget.chat.category,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.chat.name,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${_messages.length} messages',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white70 : Colors.blue,
                        ),
                      ),
                    ),
                  );
                }
                return _messages[index];
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre message...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class RenameChatDialog extends StatefulWidget {
  final String currentName;
  final Function(String) onRename;

  const RenameChatDialog({
    Key? key,
    required this.currentName,
    required this.onRename,
  }) : super(key: key);

  @override
  _RenameChatDialogState createState() => _RenameChatDialogState();
}

class _RenameChatDialogState extends State<RenameChatDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      title: Text(
        'Renommer le chat',
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Nouveau nom',
          hintStyle: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onRename(_controller.text);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Renommer'),
        ),
      ],
    );
  }
}

class CategoryDialog extends StatefulWidget {
  final String currentCategory;
  final List<String> categories;
  final Function(String) onChangeCategory;

  const CategoryDialog({
    Key? key,
    required this.currentCategory,
    required this.categories,
    required this.onChangeCategory,
  }) : super(key: key);

  @override
  _CategoryDialogState createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _controller;
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    selectedCategory = widget.currentCategory;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      title: Text(
        'Changer la catégorie',
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF3D3D3D) : Colors.white,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                items: widget.categories
                    .where((category) => category != 'Toutes')
                    .map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Ou créer une nouvelle catégorie',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF3D3D3D) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final newCategory = _controller.text.isNotEmpty
                ? _controller.text
                : selectedCategory;
            widget.onChangeCategory(newCategory);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Changer'),
        ),
      ],
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  final String chatName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    Key? key,
    required this.chatName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      title: Text(
        'Supprimer le chat',
        style: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Êtes-vous sûr de vouloir supprimer "$chatName" ?',
        style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Supprimer'),
        ),
      ],
    );
  }
}