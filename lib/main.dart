import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:saturday/splash_screen.dart';
import 'firebase_options.dart';
import 'package:get/get.dart'; // Import GetX package
import 'package:saturday/home_page.dart';
import 'package:saturday/pallette.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        // Light mode theme
        scaffoldBackgroundColor: Pallete.whiteColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Pallete.whiteColor,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        // Dark mode theme
        scaffoldBackgroundColor: Colors.grey.shade900,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.grey,
        ),
      ),
      themeMode: Get.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/', // Set the initial route to either home or login based on login status
      getPages: [
        GetPage(
          name: '/',
          page: () => FutureBuilder<Widget>(
            future: _buildInitialWidget(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!;
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
        GetPage(
          name: '/home',
          page: () => HomePage(),
        ),
      ],
    );
  }

  Future<Widget> _buildInitialWidget() async {
    final isLoggedIn = await checkLoginStatus();
    if (isLoggedIn) {
      return PopScope(
        canPop: false,
        onPopInvoked: (_) async {
          final backNavigationAllowed = await showExitConfirmationDialog();
          if (backNavigationAllowed) {
            SystemNavigator.pop(); // Exit the app
          }
        },
        child: HomePage(),
      );
    } else {
      return LoginSignupPage();
    }
  }

  Future<bool> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    return isLoggedIn;
  }
  Future<bool> showExitConfirmationDialog() async {
    return await Get.dialog(
      AlertDialog(
        title: Text('Confirm Exit'),
        content: Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false), // No
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true), // Yes
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

}

class LoginSignupPage extends StatefulWidget {
  @override
  _LoginSignupPageState createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue.shade50, // You can customize the light blue color
              Colors.blue.shade900,      // Dark blue color at the bottom
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLogin ? 'Welcome back' : 'Create an Account',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: isLogin ? 32 : 30,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    isLogin ? 'Login to your account' : '',
                    style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _emailController,
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // You can add more email validation if needed
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.person, color: Colors.grey.shade900),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: _passwordController,
                      cursorColor: Colors.black,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        // You can add more password validation if needed
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock, color: Colors.grey.shade900),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if(_formKey.currentState!.validate()){
                        if (isLogin) {
                          // Add login logic here
                          signInWithEmailAndPassword();
                        } else {
                          // Add create account logic here
                          createUserWithEmailAndPassword();
                        }
                      }
                    },
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      elevation: MaterialStateProperty.all(5.0), // Add elevation
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                            (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed)) {
                            // Dark blue color when pressed
                            return Colors.blue;
                          }
                          // Light blue color by default
                          return Colors.lightBlue;
                        },
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 70),
                      child: Text(
                        isLogin ? 'Login' : 'Create Account',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? "Don't have an account?" : 'Already have an account?',style: TextStyle(
                        color: Colors.black,
                        fontSize: 15
                      ),),
                      GestureDetector(
                        onTap: () {
                          // Toggle between login and create account pages
                          setState(() {
                            isLogin = !isLogin;
                          });
                        },
                        child: Text(
                          isLogin ? '   Sign up' : '   Login',
                          style: TextStyle(color: Colors.black, fontSize: 16,fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 40.0,right: 40),
                    child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.black,
                          elevation: 10,
                          minimumSize: Size(double.infinity, 40)
                        ),
                        icon: FaIcon(FontAwesomeIcons.google,color: Colors.red,),
                        onPressed: (){
                          signInWithGoogle();
                        },
                        label: Text('Sign Up with Google')
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void signInWithEmailAndPassword()async{
    try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        );
        saveLoginStatus(); // Save login status upon successful login
        Get.offAll(() => HomePage()); // Replace the login page with the home page
      } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
        print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
        }
    }
  }
  void createUserWithEmailAndPassword() async{
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await saveLoginStatus(); // Save login status upon successful account creation
      Get.offAll(() => HomePage()); // Replace the login page with the home page
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }
  Future<void> saveLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
  }
  void signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser
          ?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // If sign-in is successful, navigate to the HomePage
      if (userCredential.user != null) {
        await saveLoginStatus();
        Get.offAll(() => HomePage()); // Replace the login page with the home page
      }
    } catch (e) {
      print("Error during Google sign-in: $e");
      // Handle the error as needed, e.g., show a snackbar or log the error
    }
  }
}