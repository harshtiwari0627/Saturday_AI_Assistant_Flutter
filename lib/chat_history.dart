import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Prompt {
  final String id;
  final String content;

  Prompt({required this.id, required this.content});
}

class Response {
  final String content;

  Response({required this.content});
}

class ChatHistoryWidget extends StatefulWidget {
  @override
  _ChatHistoryWidgetState createState() => _ChatHistoryWidgetState();
}

class _ChatHistoryWidgetState extends State<ChatHistoryWidget> {
  final CollectionReference chatHistoryCollection = FirebaseFirestore.instance.collection('chatHistory');
  late String userId = ''; // Use late initialization
  late List<Prompt> prompts = [];
  late List<Response> responses = [];

  void getChatData(String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> promptsSnapshot = await chatHistoryCollection
          .doc(userId)
          .collection('prompts')
          .orderBy('timestamp', descending: true)
          .get();

      List<Prompt> fetchedPrompts = promptsSnapshot.docs
          .map((doc) => Prompt(id: doc.id, content: doc['content'] as String))
          .toList();

      QuerySnapshot<Map<String, dynamic>> responsesSnapshot = await chatHistoryCollection
          .doc(userId)
          .collection('responses')
          .orderBy('timestamp', descending: true)
          .get();

      List<Response> fetchedResponses = responsesSnapshot.docs
          .map((doc) => Response(content: doc['content'] as String))
          .toList();

      setState(() {
        prompts = fetchedPrompts;
        responses = fetchedResponses;
      });
    } catch (e) {
      print('Error getting chat data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserId();
    print(userId);
  }

  Future<void> getUserId() async {
    // Check if the user is logged in with Google
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      userId = googleUser.id;
    }

    // Check if the user is logged in with email/password
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      userId = firebaseUser.uid;
    }

    // Return a default user ID if not logged in
    userId ??= 'defaultUserId';

    // Now call getChatData after userId is determined
    getChatData(userId);

    setState(() {}); // Trigger a rebuild after setting the user ID
  }

  void deleteChatHistory() async {
    try {
      // Delete prompts
      await chatHistoryCollection
          .doc(userId)
          .collection('prompts')
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      // Delete responses
      await chatHistoryCollection
          .doc(userId)
          .collection('responses')
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      // Show a snackbar or other feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All chat history deleted.'),
        ),
      );
    } catch (e) {
      print('Error deleting chat history: $e');
      // Handle the error, show an error message, or log it
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat history.'),
        ),
      );
      setState(() {
        prompts = [];
        responses = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
      ),
      body:
      prompts.isEmpty
          ? Center(
        child: Text('No chats available.'),
      )
      : ListView.builder(
        itemCount: prompts.length,
        itemBuilder: (context, index) {
          // Ensure that the index is within bounds of the responses list
          if (index < responses.length) {
            return Column(
              children: [
                // Display Prompt
                GestureDetector(
                  onLongPress:() {
                    Get.snackbar(
                      'Copied prompt',
                      prompts[index].content,
                      duration: Duration(seconds: 2),
                    );
                  },
                  child: Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      title: Text('Prompt: ${prompts[index].content}'),
                    ),
                  ),
                ),
                // Display Response
                GestureDetector(
                  onLongPress:() {
                    Get.snackbar(
                      'Copied response',
                      '',
                      duration: Duration(seconds: 2),
                    );
                  },
                  child: Card(
                    color: Colors.green.shade50,
                    child: ListTile(
                      title: Text('Response: ${responses[index].content}'),
                    ),
                  ),
                ),
              ],
            );
          }
          // If the index is beyond the responses list, only display the Prompt
          return GestureDetector(
            onLongPress:() {
              Get.snackbar(
                'Copied prompt',
                '',
                duration: Duration(seconds: 2),
              );
            },
            child: Card(
              color: Colors.blue.shade50,
              child: ListTile(
                title: Text('Prompt: ${prompts[index].content}'),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Show confirmation dialog
          bool deleteConfirmed = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Delete Chat History'),
                content: Text('Are you sure you want to delete your chat history?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false); // No, do not delete
                    },
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true); // Yes, delete
                    },
                    child: Text('Yes'),
                  ),
                ],
              );
            },
          );

          // Handle user's choice
          if (deleteConfirmed == true) {
            deleteChatHistory();
            Get.back();
          }
        },
        child: Icon(Icons.delete),
      ),
    );
  }
}
