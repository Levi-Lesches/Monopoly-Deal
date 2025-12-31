import "package:uuid/uuid.dart";

class User {
  final String name;
  final String password;

  User(this.name) :
    password = const Uuid().v4();
}
