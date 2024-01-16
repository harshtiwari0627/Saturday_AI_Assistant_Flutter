import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saturday/chat_history.dart';
import 'package:saturday/feature_box.dart';
import 'package:saturday/main.dart';
import 'package:saturday/openai_service.dart';
import 'package:saturday/pallette.dart';
import 'package:clipboard/clipboard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'feedback_service.dart';

class HomeController extends GetxController {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();

  String lastWords = '';
  int flag = 0;
  final OpenAIService openAIService = OpenAIService();

  RxString generatedContent = RxString('');
  RxString generatedImageUrl = RxString('');
  TextEditingController prompt = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech() async {
    await flutterTts.setSharedInstance(true);
  }

  Future<void> initSpeechToText() async {
    await speechToText.initialize();
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);
  }

  Future<void> stopListening() async {
    await speechToText.stop();
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    lastWords = result.recognizedWords;
    print(lastWords);
  }

  Future<void> systemSpeak(String content) async {
    await flutterTts.speak(content);
  }

  Future<void> _downloadImage() async {
    var status = await Permission.storage.request();
    print(status);
    if (status == PermissionStatus.granted) {
      if (generatedImageUrl.value.isNotEmpty) {
        final response = await http.get(Uri.parse(generatedImageUrl.value));
        final bytes = response.bodyBytes;

        final downloadsDirectory = await getDownloadsDirectory();
        print(downloadsDirectory);

        final file = File(
          '${downloadsDirectory!.path}/images/final.png',
        );

        await file.writeAsBytes(bytes);

        Get.snackbar(
          'Download Complete',
          'Image downloaded and saved in Downloads',
          duration: Duration(seconds: 2),
        );
      }
    } else {
      Get.snackbar(
        'Permission Denied',
        'Storage permission denied',
        duration: Duration(seconds: 2),
      );
    }
  }

  void _showPromptModal(int num) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // Add your desired background color here
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prompt,
              decoration: InputDecoration(labelText: num!=2 ? 'Write your prompt' : 'Paste JD or Topic'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (num == 0) {
                  generatedImageUrl.value = '';
                  generatedContent.value = await openAIService.chatGPTAPI(prompt.text);
                  print(generatedContent.value);
                  await systemSpeak(generatedContent.value);
                }
                else if(num == 1) {
                  generatedImageUrl.value =
                  await openAIService.dallEAPI(prompt.text);
                  generatedContent.value = '';
                  final directory = await getExternalStorageDirectory();
                  print(directory?.path);
                }
                else if(num == 2){
                  generatedImageUrl.value = '';
                  generatedContent.value = await openAIService.TopicAPI(
                      'Generate 20 best question for the interview according to the Job Description'
                          'or the topic or the job role.  '+prompt.text);
                  print(generatedContent.value);
                  await systemSpeak(generatedContent.value);
                }
                print(generatedImageUrl.value);
                Get.back();
              },
              child: Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> getUserId() async {
    // Check if the user is logged in with Google
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      return googleUser.id;
    }

    // Check if the user is logged in with email/password
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }

    // Return a default user ID if not logged in
    return 'defaultUserId';
  }
  Future<String?> getUserName() async {
    // Check if the user is logged in with Google
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      return googleUser.displayName;
    }

    // Check if the user is logged in with email/password
    User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.displayName;
    }

    // Return a default user ID if not logged in
    return 'GuestID';
  }

  void saveFeedback(String feedback) async{
    // Add your logic here to handle the feedback, for example, you can print it
    print('Feedback submitted: $feedback');
    String userId = await getUserId();
    String? userName = await getUserName();// Fetch the user ID
    FeedbackModel feedbackModel = FeedbackModel(
      userId: userId,
      userName: userName!,
      feedbackText: feedback,
      timestamp: Timestamp.now(),
    );

    // Submit feedback to Firestore
    FeedbackService().submitFeedback(feedbackModel);
    Get.snackbar(
      'Feedback Submitted',
      feedback,
      duration: Duration(seconds: 2),
    );
  }

  void refreshPage() {
    // Reset values or perform actions needed for refreshing
    generatedContent.value = '';
    generatedImageUrl.value = '';
    prompt.text = ''; // Clear the prompt text if needed
    speechToText.stop();
    flutterTts.stop();
    // You can add more logic here if necessary
  }

  @override
  void onClose() {
    super.onClose();
    speechToText.stop();
    flutterTts.stop();
  }
}

class HomePage extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  Future<void> _showFeedbackDialog(BuildContext context) async {
    TextEditingController feedbackController = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Submit Feedback'),
          content: TextFormField(
            controller: feedbackController,
            decoration: InputDecoration(
              hintText: 'Enter your feedback...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String feedback = feedbackController.text;
                // Add your logic to save feedback in the controller or perform any other actions
                controller.saveFeedback(feedback);
                Navigator.of(context).pop();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _signout()async{
    try {
      // Sign out from Google
      await GoogleSignIn().signOut();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Update the shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);

      // After signing out, navigate to the login/signup page
      Get.offAll(() => LoginSignupPage());
    } catch (e) {
      print("Error during logout: $e");
      // Handle error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Saturday'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Pallete.blackColor,
              ),
              child: FutureBuilder<User?>(
                future: FirebaseAuth.instance.authStateChanges().first,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Still loading user data
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // Handle the error if needed
                    return Text('Error loading user data');
                  } else if (snapshot.hasData && snapshot.data != null) {
                    // User is logged in
                    User user = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          // Use the user's photoURL if available, otherwise, provide a default image
                          backgroundImage: user.photoURL != null
                              ? NetworkImage(user.photoURL!)
                              : AssetImage('assets/images/virtualAssistant.png') as ImageProvider,
                        ),
                        SizedBox(height: 10),
                        Text(
                          // Display the user's name if available, otherwise, use the email
                          user.displayName ?? user.email ?? 'Guest ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  } else {
                    // User is not logged in
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage('assets/images/virtualAssistant.png'),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Guest ID',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: Text('Logout'),
              leading: Icon(Icons.logout),
              onTap: () {
                // Add your logout logic here
                _signout();
              },
            ),
            ListTile(
              title: Text('Submit Feedback'),
              leading: Icon(Icons.feedback_outlined),
              onTap: () {
                _showFeedbackDialog(context);

              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Pallete.assistantCircleColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Container(
                  height: 123,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                          image: AssetImage(
                              'assets/images/virtualAssistant.jpeg'))),
                )
              ],
            ),
            Obx(
                  () => Visibility(
                visible: controller.generatedImageUrl.isEmpty,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 40).copyWith(top: 20),
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Pallete.borderColor,
                      ),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        topLeft: Radius.zero,
                      )),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 1.0),
                    child: Text(
                      controller.generatedContent.isEmpty
                          ? 'Hello, What task can I do for you please ask?'
                          : controller.generatedContent.value,
                      style: TextStyle(
                        color: Pallete.mainFontColor,
                        fontSize:
                        controller.generatedContent.isEmpty ? 25 : 15,
                        fontFamily: 'Cera Pro',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Obx(
                  () =>Visibility(
                  visible: controller.generatedImageUrl.isNotEmpty && controller.generatedContent.isEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(controller.generatedImageUrl.value),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            FlutterClipboard.copy(
                                controller.generatedImageUrl.value)
                                .then((result) {
                              Get.snackbar(
                                'Link Copied',
                                'Link copied to clipboard',
                                duration: Duration(seconds: 2),
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.green,
                          ),
                          child: Text('Copy Link to Clipboard'),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Permission.storage.request();
                            controller._downloadImage();
                          },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.blue,
                          ),
                          child: Text('Download Image'),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            controller.refreshPage();
                          },
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.green,
                          ),
                          child: Text('Get back to home Screen'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Obx(
                  () => Visibility(
                visible: controller.generatedImageUrl.isEmpty &&
                    controller.generatedContent.isNotEmpty,
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        FlutterClipboard.copy(controller.generatedContent.value)
                            .then((result) {
                          Get.snackbar(
                            'Content Copied',
                            'Content copied to clipboard',
                            duration: Duration(seconds: 2),
                          );
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.green,
                      ),
                      child: Text('Copy Content to Clipboard'),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        controller.refreshPage();
                      },
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.green,
                      ),
                      child: Text('Get back to home Screen'),
                    ),
                  ],
                ),
              ),
            ),
            Obx(
                  () =>Visibility(
                visible: controller.generatedContent.isEmpty &&
                    controller.generatedImageUrl.isEmpty,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  alignment: Alignment.centerLeft,
                  margin: const EdgeInsets.only(
                    top: 10,
                    left: 22,
                  ),
                  child: const Text(
                    'Here are a few features',
                    style: TextStyle(
                      fontFamily: 'Cera Pro',
                      color: Pallete.mainFontColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Obx(
                  () => Visibility(
                visible: controller.generatedContent.isEmpty &&
                    controller.generatedImageUrl.isEmpty,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        controller._showPromptModal(0);
                      },
                      child: FeatureBox(
                        color: Pallete.firstSuggestionBoxColor,
                        headerText: 'Chat GPT',
                        descriptionText:
                        'A smarter way to stay organized and informed with ChatGPT',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        controller._showPromptModal(1);
                      },
                      child: FeatureBox(
                        color: Pallete.secondSuggestionBoxColor,
                        headerText: 'Dall-E',
                        descriptionText:
                        'Get inspired and stay creative with your personal assistant powered by Dall-E',
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (await controller.speechToText.hasPermission &&
                            controller.speechToText.isNotListening &&
                            controller.flag == 0) {
                          await controller.startListening();
                          controller.flag = 1;
                        } else if (controller.speechToText.isNotListening &&
                            controller.flag == 1) {
                          final speech = await controller.openAIService
                              .isArtPromptAPI(controller.lastWords);
                          if (speech.contains('https')) {
                            controller.generatedImageUrl.value = speech;
                            controller.generatedContent.value = '';
                          } else {
                            controller.generatedImageUrl.value = '';
                            controller.generatedContent.value = speech;
                            await controller.systemSpeak(speech);
                          }
                          await controller.stopListening();
                          controller.flag = 0;
                        } else {
                          controller.initSpeechToText();
                        }
                      },
                      child: FeatureBox(
                        color: Pallete.thirdSuggestionBoxColor,
                        headerText: 'Smart Voice Assistant',
                        descriptionText:
                        'Get the best of both worlds with a voice assistant powered by Dall-E and ChatGPT',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        controller._showPromptModal(2);
                      },
                      child: FeatureBox(
                        color: Pallete.secondSuggestionBoxColor,
                        headerText: 'Interview Questions',
                        descriptionText:
                        'Get the best question related to Job Description or topic',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => ChatHistoryWidget());
                      },
                      child: FeatureBox(
                        color: Pallete.firstSuggestionBoxColor,
                        headerText: 'Check History',
                        descriptionText:
                        'Access all previous prompts',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
