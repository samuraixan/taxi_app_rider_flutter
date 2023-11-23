import 'package:firebase_database/firebase_database.dart';

class Users {
  String? id;
  String? email;
  String? name;
  String? password;
  String? phone;

  Users({this.id, this.email, this.name, this.password, this.phone});

  Users.fromSnapshot(DataSnapshot dataSnapshot) {
    id = dataSnapshot.key;
    email = (dataSnapshot.value as Map)['email'] ?? '';
    name = (dataSnapshot.value as Map)['name'] ?? '';
    password = (dataSnapshot.value as Map)['password'] ?? '';
    phone = (dataSnapshot.value as Map)['phone'] ?? '';
  }
}