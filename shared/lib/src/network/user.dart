import "package:meta/meta.dart";
import "package:shared/utils.dart";
import "package:uuid/uuid.dart";

@immutable
class User {
  final String name;
  final String password;

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
    && other.name == name
    && other.password == password;
}
