// Users are compared by passwords (userIDs), which don't change
// ignore_for_file: must_be_immutable

import "package:meta/meta.dart";
import "package:shared/utils.dart";
import "package:uuid/uuid.dart";

@immutable
class User {
  final String name;
  final String password;
  bool isConnected = false;

  User(this.name) :
    password = const Uuid().v4();

  User.fromJson(Json json) :
    name = json["name"],
    password = json["password"];

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) => other is User
    && other.password == password;

  @override
  int get hashCode => password.hashCode;

  Json toJson() => {
    "name": name,
    "password": password,
  };
}
