import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../AllWidgets/progressDialog.dart';
import '../main.dart';
import 'mainscreen.dart';
import 'registrationScreen.dart';


// ignore: must_be_immutable
class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

  static const String idScreen = 'login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 45,
              ),
              const Image(
                image: AssetImage('assets/images/logo.png'),
                width: 350,
                height: 250,
                alignment: Alignment.center,
              ),
              const SizedBox(
                height: 1,
              ),
              const Text(
                'Войдите в систему как пассажир',
                style: TextStyle(fontSize: 24, fontFamily: 'Rowdies'),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 1,
                    ),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Эмаил',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                          TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 1,
                    ),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Пароль',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                          TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        if (emailController.text.isEmpty) {
                          displayToastMessage('Введите почту', context);
                          return;
                        } else if (!emailController.text.contains('@')) {
                          displayToastMessage(
                              'Адрес электронной почты недействителен',
                              context);
                          return;
                        } else if (passwordController.text.isEmpty) {
                          displayToastMessage('Введите пароль', context);
                          return;
                        }
                        loginAndAuthenticatUser(context);
                      },
                      child: Container(
                        height: 50,
                        child: const Center(
                          child: Text(
                            'Войти',
                            style:
                            TextStyle(fontSize: 20, fontFamily: 'Rowdies'),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const Text('У вас нет учетной записи?'),
              const SizedBox(
                height: 5,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, RegistrationScreen.idScreen, (route) => false);
                },
                child: const Text(
                  'Зарегистрируйтесь здесь',
                  style: TextStyle(fontSize: 20, fontFamily: 'Rowdies'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> checkInternetConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false; //нет подключения к интернету
    }
    return true; // есть подключения к интернету
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void loginAndAuthenticatUser(BuildContext context) async {

    bool connected = await checkInternetConnection();
    if (!connected) {
      return displayToastMessage('Нет подключение', context);
    }
    if (mounted) {
      try {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return ProgressDialog(
                message: 'Пожалуйста подождите...',
              );
            });
        final UserCredential userCredential =
        await _firebaseAuth.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim());
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null) {
          //  сохранить информацию о пользователе в базе данных
          final DatabaseEvent event = await usersRef.child(firebaseUser.uid).once();
          if (event.snapshot.value != null) {
            Navigator.pushNamedAndRemoveUntil(
                context, MainScreen.idScreen, (route) => false);
          }
        }
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        if (e.code == 'user-not-found') {
          displayToastMessage(
              'Почта неверна. Или вы не зарегистрированы!', context);
        } else if (e.code == 'wrong-password') {
          displayToastMessage('Неправильный пароль!', context);
        }
      }
    }

  }
}
