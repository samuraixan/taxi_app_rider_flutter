import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../AllWidgets/progressDialog.dart';
import '../main.dart';
import 'loginScreen.dart';
import 'mainscreen.dart';


// ignore: must_be_immutable
class RegistrationScreen extends StatelessWidget {
  RegistrationScreen({super.key});

  static const String idScreen = 'register';

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // const SizedBox(
              //   height: 20,
              // ),
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
                'Зарегистрируйтесь как пассажир',
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
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                          labelText: 'Имя',
                          labelStyle: TextStyle(fontSize: 14),
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 10)),
                      style: const TextStyle(fontSize: 14),
                    ),
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
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Телефон',
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
                        if (nameController.text.length < 3) {
                          displayToastMessage(
                              'Имя должно содержать не менее 3 символов',
                              context);
                        } else if (!emailController.text.contains('@')) {
                          displayToastMessage(
                              'Адрес электронной почты недействителен',
                              context);
                        } else if (phoneController.text.isEmpty) {
                          displayToastMessage(
                              'Номер телефона является обязательным', context);
                        } else if (passwordController.text.length < 6) {
                          displayToastMessage(
                              'Пароль должен содержать не менее 6 символов',
                              context);
                        } else {
                          registerNewUser(context);
                        }
                      },
                      child: Container(
                        height: 50,
                        child: const Center(
                          child: Text(
                            'Создать аккаунт',
                            style:
                            TextStyle(fontSize: 20, fontFamily: 'Rowdies'),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const Text('У вас уже есть учетная запись?'),
              const SizedBox(
                height: 5,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: const Text(
                  'Войти',
                  style: TextStyle(fontSize: 20, fontFamily: 'Rowdies'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return ProgressDialog(message: 'Регистрация, Пожалуйста подождите');
        });
    final User? firebaseUser = (await _firebaseAuth
            .createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text.trim())
            .catchError((e) {
      return displayToastMessage('Ошибка:$e', context);
    })).user;
    if (firebaseUser != null) {
      //  сохранить информацию о пользователе в базе данных
      Map userDataMap = {
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'password': passwordController.text,
      };
      usersRef.child(firebaseUser.uid).set(userDataMap);
      displayToastMessage('Поздравляю, Ваша учетная запись создана.', context);
      Navigator.pushNamedAndRemoveUntil(
          context, MainScreen.idScreen, (route) => false);
    } else {
      //  произошла ошибка - отображение сообщений об ошибках
      displayToastMessage(
          'Новая учетная запись пользователя не была создана', context);
    }
  }
}

displayToastMessage(String message, BuildContext context) {
  Fluttertoast.showToast(msg: message);
}
