import 'package:hustle_stay/main.dart';
import 'package:hustle_stay/models/message.dart';
import 'package:hustle_stay/models/user.dart';

class ChatData {
  String title;
  String? description;
  List<UserData> receivers;
  UserData owner;

  /// the path where chat collection is present
  String path;
  List<MessageData> messages = [];

  ChatData({
    required this.owner,
    required this.receivers,
    this.description,
    required this.title,
    required this.path,
  });
}

Future<ChatData> fetchChatData(ChatData chat) async {
  final response = await firestore.collection("${chat.path}/chat").get();
  chat.messages =
      response.docs.map((e) => MessageData.load(e.id, e.data())).toList();
  return chat;
}