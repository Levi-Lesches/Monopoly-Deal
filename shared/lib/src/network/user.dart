// Users are considered equal based on name alone
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import "package:shared/utils.dart";
import "package:uuid/uuid.dart";

class User {
  final String name;
  String password;

  User(this.name) :
    password = const Uuid().v4();

  User.fromJson(Json json) :
    name = json["name"],
    password = json["password"];

  @override
  String toString() => name;

  Json toJson() => {
    "name": name,
    "password": password,
  };

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is User
    && other.name == name;
}
