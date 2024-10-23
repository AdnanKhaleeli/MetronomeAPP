import 'package:mongo_dart/mongo_dart.dart';

class User {
  final ObjectId userId;
  final String username;
  final String password;
  final String profileName;

  User({
    required this.userId,
    required this.username,
    required this.password,
    required this.profileName,
  });

  String getUsername() {
    return this.username;
  }

  String getPWD() {
    return this.password;
  }

  String getProfileName() {
    return this.profileName;
  }

  ObjectId getUserId() {
    return this.userId;
  }


  
}
