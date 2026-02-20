import "package:shared/utils.dart";
import "package:uuid/uuid.dart";

extension type UserID(String value) {
  UserID.unique() : value = const Uuid().v4();
  UserID.fromJson(this.value);
}

class User {
  final String name;
  UserID id;
  bool isConnected = false;
  int roomCode = 0;

  User(this.name) :
    id = UserID.unique();

  User.fromJson(Json json) :
    name = json["name"],
    id = UserID.fromJson(json["id"]);

  @override
  String toString() => name;

  Json toJson() => {
    "name": name,
    "id": id,
  };
}
