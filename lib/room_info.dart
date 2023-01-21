class RoomInfo {
  UserWithId roomer;
  List<UserWithId> members;

  RoomInfo.fromJson(Map<String, dynamic> json)
      : roomer = UserWithId.fromJson(json['roomer']),
        members = json['members'].map<UserWithId>((v) {
          return UserWithId.fromJson(v);
        }).toList();

  RoomInfo(this.roomer, this.members);
}

class UserWithId {
  String id;
  String name;
  String avatar;

  UserWithId.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? "",
        avatar = json['avatar'] ?? "",
        id = json['id'].toString();

  UserWithId(this.id, this.name, this.avatar);
}
