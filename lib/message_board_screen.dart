
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';
import 'board_service.dart';

class MessageBoardScreen extends StatefulWidget {
  final String uid;
  final String firstName;

  const MessageBoardScreen({
    super.key,
    required this.uid,
    required this.firstName,
  });

  @override
  State<MessageBoardScreen> createState() =>
      _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  final BoardService _board = BoardService();
  final AuthService _auth = AuthService();
  final TextEditingController _messageController =
      TextEditingController();

  late final Stream<List<BoardMessage>> _messages;

  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _messages = _board.messageBoard();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(Object error) {
    if (error is FirebaseException &&
        error.code == 'permission-denied') {
      _showMessage('Permission denied by Firestore.');
    } else {
      _showMessage('Operation failed: $error');
    }
  }

  // CREATE
  Future<void> _postMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _posting) return;

    setState(() => _posting = true);

    try {
      await _board.postMessage(
        authorUid: widget.uid,
        authorName: widget.firstName,
        text: text,
      );

      if (mounted) {
        _messageController.clear();
      }
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  
Future<void> _editMessage(BoardMessage message) async {
  String updatedText = message.text;

  final newText = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Edit Message'),
      content: TextFormField(
        initialValue: message.text,
        autofocus: true,
        maxLength: 500,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Message',
        ),
        onChanged: (value) {
          updatedText = value;
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              dialogContext,
              updatedText.trim(),
            );
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (!mounted || newText == null) return;

  if (newText.isEmpty) {
    _showMessage('Message cannot be empty.');
    return;
  }

  if (newText == message.text) return;

  try {
    await _board.editMessage(
      messageId: message.id,
      newText: newText,
    );
  } catch (error) {
    _showError(error);
  }
}

  // DELETE
  Future<void> _deleteMessage(BoardMessage message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text(
          'This message will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _board.deleteMessage(
        messageId: message.id,
      );
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              try {
                await _auth.signOut();
              } catch (error) {
                _showError(error);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Welcome, ${widget.firstName}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Live message list
          Expanded(
            child: StreamBuilder<List<BoardMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load messages: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Be the first to post!',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwner =
                        message.authorUid == widget.uid;

                    return Card(
                      child: ListTile(
                        title: Text(
                          message.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(message.text),
                            const SizedBox(height: 6),
                            Text(
                              message.editedAt != null
                                  ? 'Edited'
                                  : message.createdAt == null
                                      ? 'Sending...'
                                      : 'Posted',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                        trailing: isOwner
                            ? PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    await _editMessage(message);
                                  } else if (value == 'delete') {
                                    await _deleteMessage(message);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message composer
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLength: 500,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        _posting ? null : _postMessage,
                    child: Text(
                      _posting ? 'Posting...' : 'Post',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
