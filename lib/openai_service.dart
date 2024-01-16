import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:saturday/home_page.dart';
import 'package:saturday/secrets.dart';

class FirestoreService {

  final CollectionReference chatHistoryCollection = FirebaseFirestore.instance.collection('chatHistory');
  Future<void> savePrompt(String userId, String prompt) async {
    try {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        userId = googleUser.id;
      }

      // Check if the user is logged in with email/password
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
      }
      await chatHistoryCollection
          .doc(userId)
          .collection('prompts')
          .add({
        'content': prompt,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving prompt: $e');
    }
  }

  Future<void> saveResponse(String userId, String response) async {
    try {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        userId = googleUser.id;
      }

      // Check if the user is logged in with email/password
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        userId = firebaseUser.uid;
      }
      await chatHistoryCollection
          .doc(userId)
          .collection('responses')
          .add({
        'content': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving response: $e');
    }
  }
}

class OpenAIService {

  final FirestoreService firestoreService = FirestoreService();
  final List<Map<String, String>> messages = [];

  Future<String> isArtPromptAPI(String prompt) async {
    try{
      final res = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers:{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAIAPIKEY',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              'role': 'user',
              'content': 'Does given promp want to generate an AI picture, image, art or anything similar? $prompt. Simply answer with a yes or no. ',
            }
          ],
        }),
      );
      await firestoreService.savePrompt('userId', prompt);
      await firestoreService.saveResponse('userId', res.body);
      if(res.statusCode == 200){
        String content = jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        switch(content){
            case 'Yes':
          case 'yes':
          case 'Yes.':
            case 'yes.':
              final res = await dallEAPI(prompt);
              return res;
          default:
            final res = await chatGPTAPI(prompt);
            return res;

        }
      }
      return 'An internal error occurred';
    }catch (e){
      return e.toString();
    }
  }
  Future<String> chatGPTAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try{
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers:{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKEY',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }),
      );
      if(res.statusCode == 200){
        String content = jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        messages.add({
          'role':'assistant',
          'content': content,
        });
        await firestoreService.savePrompt('userId', prompt);
        await firestoreService.saveResponse('userId', content);
        return content;
      }
      return 'An internal error occurred';
    }catch (e){
      return e.toString();
    }
  }
  Future<String> dallEAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try{
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers:{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKEY',
        },
        body: jsonEncode({
         'prompt': prompt,
          'n': 1,
        }),
      );
      if(res.statusCode == 200){
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
        imageUrl = imageUrl.trim();

        messages.add({
          'role':'assistant',
          'content': imageUrl,
        });
        await firestoreService.savePrompt('userId', prompt);
        await firestoreService.saveResponse('userId', imageUrl);
        return imageUrl;
      }
      return 'An internal error occurred';
    }catch (e){
      return e.toString();
    }
  }
  Future<String> TopicAPI(String prompt) async {
    messages.add({
      'role': 'user',
      'content': prompt,
    });
    try{
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers:{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAIAPIKEY',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }),
      );
      if(res.statusCode == 200){
        String content = jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        messages.add({
          'role':'assistant',
          'content': content,
        });
        await firestoreService.savePrompt('userId', prompt);
        await firestoreService.saveResponse('userId', content);
        return content;
      }
      return 'An internal error occurred';
    }catch (e){
      return e.toString();
    }
  }
}