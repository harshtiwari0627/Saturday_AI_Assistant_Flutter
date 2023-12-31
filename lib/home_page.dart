import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:saturday/feature_box.dart';
import 'package:saturday/openai_service.dart';
import 'package:saturday/pallette.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final speechToText = SpeechToText();
  final flutterTts = FlutterTts();

  String lastWords = '';
  int flag = 0;
  final OpenAIService openAIService = OpenAIService();

  String? generatedContent;
  String? generatedImageUrl;

  @override
  void initState(){
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  Future<void> initTextToSpeech()async{
    await flutterTts.setSharedInstance(true);
    setState(() {

    });
  }

  Future<void> initSpeechToText() async {
   await speechToText.initialize();
   setState(() {});
  }

  Future<void> startListening() async {
    await speechToText.listen(onResult: onSpeechResult);

    setState(() {});
  }

  Future<void> stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      lastWords = result.recognizedWords;
    });
    print(lastWords);
  }

  Future<void> systemSpeak(String content) async{
    await flutterTts.speak(content);
  }

  @override
  void dispose(){
    super.dispose();
    speechToText.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saturday'),
        leading: const Icon(Icons.menu),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Virtual Assistant Picture
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 120,
                    width: 120,
                    margin: const EdgeInsets.only(top:4),
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
                    image: DecorationImage(image: AssetImage('assets/images/virtualAssistant.png'))
                  ),
                )
              ],
            ),
            // Chat bubble
            Visibility(
              visible:  generatedImageUrl==null,
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
                  )
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 1.0),
                  child: Text(
                    generatedContent == null
                    ? 'Good Morning, What task can i do for you?'
                    : generatedContent!,
                  style: TextStyle(
                    color: Pallete.mainFontColor,
                    fontSize: generatedContent == null ? 25 : 18,
                    fontFamily: 'Cera Pro',
                  ),
                  ),
                ),
              ),
            ),
            
            if(generatedImageUrl!=null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ClipRRect
                  ( borderRadius: BorderRadius.circular(20),
                    child: Image.network(generatedImageUrl!)
                ),
            ),
            Visibility(
              visible:  generatedContent==null && generatedImageUrl==null,
              child: Container(
                padding: const EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.only(
                  top: 10,
                  left: 22,
                ),
                child: const Text('Here are a few features',
                  style: TextStyle(
                    fontFamily: 'Cera Pro',
                    color: Pallete.mainFontColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Features List
            Visibility(
              visible: generatedContent==null && generatedImageUrl==null,
              child: Column(
                children: const [
                    FeatureBox(color: Pallete.firstSuggestionBoxColor,
                    headerText: 'Chat GPT',
                    descriptionText:
                      'A smarter way to stay organized and informed with ChatGPT'
                      ,),

                    FeatureBox(color: Pallete.secondSuggestionBoxColor,
                    headerText: 'Dall-E',
                    descriptionText:
                    'Get inspired and stay creative with your personal assistant powered by Dall-E'
                    ,),

                  FeatureBox(color: Pallete.thirdSuggestionBoxColor,
                    headerText: 'Smart Voice Assistant',
                    descriptionText:
                    'Get the best of both worlds with a voice assistant powered by Dall-E and ChatGPT'
                    ,),
                ],
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Pallete.firstSuggestionBoxColor,
        onPressed: ()async{
          if(await speechToText.hasPermission && speechToText.isNotListening && flag == 0){
            await startListening();
            flag = 1;
          }
          else if(speechToText.isNotListening && flag ==1){
            final speech = await openAIService.isArtPromptAPI(lastWords);
            if(speech.contains('https')){
              generatedImageUrl = speech;
              generatedContent = null;
              setState(() {
              });
            }
            else{
              generatedImageUrl = null;
              generatedContent = speech;
              setState(() {
              });
              await systemSpeak(speech);
            }
            await stopListening();
            flag = 0;
          }
          else{
            initSpeechToText();
          }
        } ,
        child: const Icon(Icons.mic),
      ),
    );
  }
}