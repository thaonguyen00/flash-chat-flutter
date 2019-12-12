import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flutter/material.dart';

final _firestore = Firestore.instance;
final firestoreCollection = 'flashchat';
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = "ChatScreen";
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();

  final _auth = FirebaseAuth.instance;

  String messageText;
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void getMessages() async {
    final messages =
        await _firestore.collection(firestoreCollection).getDocuments();
    for (var message in messages.documents) {
      print(message.data);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection(firestoreCollection).add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                      });
                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(firestoreCollection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blue,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<BubbleText> msgBubbles = [];
        for (var msg in messages) {
          final msgText = msg.data['text'];
          final msgSender = msg.data['sender'];
          final currentUser = loggedInUser.email;

          final msgBubble = BubbleText(
            sender: msgSender,
            text: msgText,
            isMe: currentUser == msgSender,
          );
          msgBubbles.add(msgBubble);
        }
        return Expanded(
          child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              children: msgBubbles),
        );
      },
    );
  }
}

class BubbleText extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;

  BubbleText({this.sender, this.text, this.isMe});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 7,
            color: isMe ? Colors.white : Colors.blue,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 20,
                  color: isMe ? Colors.black54 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
