/**
 * The base for this code was used from https://github.com/duytq94/flutter-chat-demo and here is the license.
 * Thank you very much for that demo and the medium post:
 * https://medium.com/@duytq94/building-a-chat-app-with-flutter-and-firebase-from-scratch-9eaa7f41782e
 * The code here is mostly modified from the original.
 * MIT License

    Copyright (c) 2019 Duy Tran

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
 */

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:date_format/date_format.dart' show formatDate, HH, nn, ss, dd, mm, yy, yyyy;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:redpanda/activities/const.dart';
import 'package:redpanda/main.dart';
import 'package:redpanda_light_client/export.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

class ChatView extends StatelessWidget {
  final int channelId;
  DBChannel channel;
  final String channelName;

  ChatView(this.channelId, {this.channel, this.channelName}) : super();

  @override
  Widget build(BuildContext context) {
    print(channelName);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          channel?.name ?? channelName,
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: new ChatScreen(channelId, channel),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int channelId;
  DBChannel channel;

  ChatScreen(this.channelId, this.channel) : super();

  @override
  State createState() => new ChatScreenState(this.channelId, this.channel);
}

class ChatScreenState extends State<ChatScreen> implements WidgetsBindingObserver {
  ChatScreenState(this.channelId, this.channel);

  static final player = AudioCache();
  var oldOnNewMessageListener;

  final int channelId;
  DBChannel channel;

//  String peerId;
//  String peerAvatar;
//  String id;
//
  var listMessage;

//  String groupChatId;
//  SharedPreferences prefs;

//  File imageFile;
  bool isLoading;
  bool isShowSticker;

//  String imageUrl;

  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();
  Stream<List<DBMessageWithFriend>> messageStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    focusNode.addListener(onFocusChange);

    isLoading = false;
    isShowSticker = false;

    messageStream = RedPandaLightClient.watchDBMessageEntries(channelId);

    readLocal();
    oldOnNewMessageListener = RedPandaLightClient.onNewMessage;
    RedPandaLightClient.onNewMessage = onNewMessage;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RedPandaLightClient.onNewMessage = oldOnNewMessageListener;
    super.dispose();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
//    prefs = await SharedPreferences.getInstance();
//    id = prefs.getString('id') ?? '';
//    if (id.hashCode <= peerId.hashCode) {
//      groupChatId = '$id-$peerId';
//    } else {
//      groupChatId = '$peerId-$id';
//    }
//
//    Firestore.instance.collection('users').document(id).updateData({'chattingWith': peerId});

    await runService();
    var channelById = await RedPandaLightClient.getChannelById(channelId);

    if (channelById == null) {
      throw new Exception('no channel found with id: $channelId ....');
    }

    setState(() {
      messageStream = RedPandaLightClient.watchDBMessageEntries(channelId);
      channel = channelById;
    });

    flutterLocalNotificationsPlugin.cancel(channelId);
  }

  onNewMessage(DBMessageWithFriend msg, String channelName) {
    print("dkjahdnaueghruewrgjew new message: " + msg.message.content);

    if (msg.message.channelId != channelId) {
      print("redirecting onNewMessage to old method since it is not for our channel...");
      oldOnNewMessageListener(msg, channelName);
      return;
    }

    if (msg.fromMe) {
      return;
    }

    player.play("inChatNotification.mp3");
  }

  Future getImage() async {
//    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
//
//    if (imageFile != null) {
//      setState(() {
//        isLoading = true;
//      });
//      uploadFile();
//    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
//    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
//    StorageUploadTask uploadTask = reference.putFile(imageFile);
//    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
//    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
//      imageUrl = downloadUrl;
//      setState(() {
//        isLoading = false;
//        onSendMessage(imageUrl, 1);
//      });
//    }, onError: (err) {
//      setState(() {
//        isLoading = false;
//      });
//      Fluttertoast.showToast(msg: 'This file is not an image');
//    });
  }

  void onSendMessage(String text, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (text.trim() != '') {
      textEditingController.clear();

      RedPandaLightClient.writeMessage(channelId, text);
//      var documentReference = Firestore.instance
//          .collection('messages')
//          .document(groupChatId)
//          .collection(groupChatId)
//          .document(DateTime.now().millisecondsSinceEpoch.toString());
//
//      Firestore.instance.runTransaction((transaction) async {
//        await transaction.set(
//          documentReference,
//          {
//            'idFrom': id,
//            'idTo': peerId,
//            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
//            'content': content,
//            'type': type
//          },
//        );
//      });
      listScrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
//      Fluttertoast.showToast(msg: 'Nothing to send');
      RedPandaLightClient.writeMessage(channelId, Utils.randomString(16));
    }
  }

  Widget buildItem(int index, DBMessageWithFriend message) {
//    print('${message.friend?.name}: ${message.message.content}');
    if (message.fromMe) {
      // Right (my message)

      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                message.message.type == 0
                    // Text
                    ? Container(
                        child: Text(
                          message.message.content,
                          style: TextStyle(color: primaryColor),
                        ),
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                        width: 200.0,
                        decoration: BoxDecoration(color: greyColor2, borderRadius: BorderRadius.circular(8.0)),
                        margin: EdgeInsets.only(right: 10.0),
                      )
                    : message.message.type == 1
                        // Image
                        ? Container(
                            child: FlatButton(
                              child: Material(
                                child: new Text("images not supported rn 1"),
//                          CachedNetworkImage(
//                            placeholder: (context, url) => Container(
//                              child: CircularProgressIndicator(
//                                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
//                              ),
//                              width: 200.0,
//                              height: 200.0,
//                              padding: EdgeInsets.all(70.0),
//                              decoration: BoxDecoration(
//                                color: greyColor2,
//                                borderRadius: BorderRadius.all(
//                                  Radius.circular(8.0),
//                                ),
//                              ),
//                            ),
//                            errorWidget: (context, url, error) => Material(
//                              child: Image.asset(
//                                'images/img_not_available.jpeg',
//                                width: 200.0,
//                                height: 200.0,
//                                fit: BoxFit.cover,
//                              ),
//                              borderRadius: BorderRadius.all(
//                                Radius.circular(8.0),
//                              ),
//                              clipBehavior: Clip.hardEdge,
//                            ),
//                            imageUrl: document['content'],
//                            width: 200.0,
//                            height: 200.0,
//                            fit: BoxFit.cover,
//                          ),
                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                              onPressed: () {
//                          Navigator.push(
//                              context, MaterialPageRoute(builder: (context) => FullPhoto(url: document['content'])));
                              },
                              padding: EdgeInsets.all(0),
                            ),
                            margin: EdgeInsets.only(bottom: isNextMessageLeft(index) ? 20.0 : 10.0, right: 10.0),
                          )
                        // Sticker
                        : Container(
                            child: Text(
                              "Content Type not found",
                              style: TextStyle(color: primaryColor),
                            ),
                            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                            width: 200.0,
                            decoration: BoxDecoration(color: greyColor2, borderRadius: BorderRadius.circular(8.0)),
                            margin: EdgeInsets.only(bottom: isNextMessageLeft(index) ? 20.0 : 10.0, right: 10.0),
                          )

//          Container(
//                      child: new Image.asset(
//                        'images/${document['content']}.gif',
//                        width: 100.0,
//                        height: 100.0,
//                        fit: BoxFit.cover,
//                      ),
//                      margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
//                    ),
              ],
              mainAxisAlignment: MainAxisAlignment.end,
            ),

            // Time
            isNextMessageLeft(index)
                ? Container(
                    child: Text(
//                      DateFormat('dd MMM kk:mm')
//                          .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),

                      "${formatDate(DateTime.fromMillisecondsSinceEpoch(
                            message.message.timestamp,
                          ), [HH, ':', nn, ':', ss])} - ${formatDate(DateTime.fromMillisecondsSinceEpoch(
                            message.message.timestamp,
                          ), [dd, '.', mm, '.', yy])}",
                      style: TextStyle(color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(
                      top: 5.0,
                      bottom: 5.0,
                      right: 10.0,
                    ),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.end,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageNotFromSameUser(index)
                    ? Material(
                        child: new CircleAvatar(
                          child: new Text(generateDisplayName(message)),
                          radius: 35 / 2,
                          backgroundColor: generateUserColor(message),
                          foregroundColor: Colors.white70,
                        ),

//                        new Text("images not supported rn 2"),
//                            CachedNetworkImage(
//                          placeholder: (context, url) => Container(
//                            child: CircularProgressIndicator(
//                              strokeWidth: 1.0,
//                              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
//                            ),
//                            width: 35.0,
//                            height: 35.0,
//                            padding: EdgeInsets.all(10.0),
//                          ),
//                          imageUrl: "http://via.placeholder.com/150x150",
//                          width: 35.0,
//                          height: 35.0,
//                          fit: BoxFit.cover,
//                        ),

                        borderRadius: BorderRadius.all(
                          Radius.circular(18.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(width: 35.0),
                message.message.type == 0
                    ? Container(
                        child: Text(
                          message.message.content,
                          style: TextStyle(color: Colors.white),
                        ),
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                        width: 200.0,
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8.0)),
                        margin: EdgeInsets.only(left: 10.0),
                      )
                    : message.message.type == 1
                        ? Container(
                            child: FlatButton(
                              child: Material(
                                child: new Text("images not supported rn 4"),
//                                CachedNetworkImage(
//                                  placeholder: (context, url) => Container(
//                                    child: CircularProgressIndicator(
//                                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
//                                    ),
//                                    width: 200.0,
//                                    height: 200.0,
//                                    padding: EdgeInsets.all(70.0),
//                                    decoration: BoxDecoration(
//                                      color: greyColor2,
//                                      borderRadius: BorderRadius.all(
//                                        Radius.circular(8.0),
//                                      ),
//                                    ),
//                                  ),
//                                  errorWidget: (context, url, error) => Material(
//                                    child: Image.asset(
//                                      'images/img_not_available.jpeg',
//                                      width: 200.0,
//                                      height: 200.0,
//                                      fit: BoxFit.cover,
//                                    ),
//                                    borderRadius: BorderRadius.all(
//                                      Radius.circular(8.0),
//                                    ),
//                                    clipBehavior: Clip.hardEdge,
//                                  ),
//                                  imageUrl: document['content'],
//                                  width: 200.0,
//                                  height: 200.0,
//                                  fit: BoxFit.cover,
//                                ),

                                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                              onPressed: () {
//                                Navigator.push(context,
//                                    MaterialPageRoute(builder: (context) => FullPhoto(url: document['content'])));
                              },
                              padding: EdgeInsets.all(0),
                            ),
                            margin: EdgeInsets.only(left: 10.0),
                          )
                        : Container(
                            child: Text(
                              "Content Type not found",
                              style: TextStyle(color: primaryColor),
                            ),
                            padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                            width: 200.0,
                            decoration: BoxDecoration(color: greyColor2, borderRadius: BorderRadius.circular(8.0)),
                            margin: EdgeInsets.only(bottom: isNextMessageRight(index) ? 20.0 : 10.0, right: 10.0),
                          )
//                Container(
//                            child: new Image.asset(
//                              'images/${document['content']}.gif',
//                              width: 100.0,
//                              height: 100.0,
//                              fit: BoxFit.cover,
//                            ),
//                            margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
//                          ),
              ],
            ),

            // Time
            isNextMessageRight(index)
                ? Container(
                    child: Text(
//                      DateFormat('dd MMM kk:mm')
//                          .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),

                      "${formatDate(DateTime.fromMillisecondsSinceEpoch(
                            message.message.timestamp,
                          ), [HH, ':', nn, ':', ss])} - ${formatDate(DateTime.fromMillisecondsSinceEpoch(
                            message.message.timestamp,
                          ), [dd, '.', mm, '.', yy])}",
                      style: TextStyle(color: greyColor, fontSize: 12.0, fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  Color generateUserColor(DBMessageWithFriend message) {
    if (message.friend?.id == null) {
      return Colors.black54;
    }
    return Color(message.friend.id);
  }

  String generateDisplayName(DBMessageWithFriend message) {
    if (message.friend?.name == null) {
      return "?";
    }
    if (message.friend?.name?.length > 3) {
      return message.friend?.name?.substring(0, 3);
    } else {
      return message.friend?.name;
    }
  }

  bool isNextMessageLeft(int index) {
    print('index: $index');
    if ((index > 0 && listMessage != null && !listMessage[index - 1].fromMe) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isNextMessageRight(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1].fromMe) || index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageNotFromSameUser(int index) {
    if ((index > 0 && listMessage != null && listMessage[index - 1].message.from != listMessage[index].message.from) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      //todo disable watcher...
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              // Sticker
              (isShowSticker ? buildSticker() : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: new Image.asset(
                  'images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: new Image.asset(
                  'images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: new Image.asset(
                  'images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: new Image.asset(
                  'images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: new Image.asset(
                  'images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: new Image.asset(
                  'images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: new Image.asset(
                  'images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: new Image.asset(
                  'images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: new Image.asset(
                  'images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: greyColor2, width: 0.5)), color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImage,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.face),
                onPressed: getSticker,
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: greyColor2, width: 0.5)), color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: false
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: messageStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) => buildItem(index, snapshot.data[index]),
                    itemCount: snapshot.data.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      RedPandaLightClient.onNewMessage = oldOnNewMessageListener;
    } else if (state == AppLifecycleState.resumed) {
      RedPandaLightClient.onNewMessage = onNewMessage;
      new Timer(Duration(seconds: 1), () {
        readLocal();
//        setState(() {
//          messageStream = RedPandaLightClient.watchDBMessageEntries(channelId);
//        });
      });
    }

    print('new app state: ' + state.toString() + " ####################################");
  }

  @override
  void didChangeAccessibilityFeatures() {
    // TODO: implement didChangeAccessibilityFeatures
  }

  @override
  void didChangeLocales(List<Locale> locale) {
    // TODO: implement didChangeLocales
  }

  @override
  void didChangeMetrics() {
    // TODO: implement didChangeMetrics
  }

  @override
  void didChangePlatformBrightness() {
    // TODO: implement didChangePlatformBrightness
  }

  @override
  void didChangeTextScaleFactor() {
    // TODO: implement didChangeTextScaleFactor
  }

  @override
  void didHaveMemoryPressure() {
    // TODO: implement didHaveMemoryPressure
  }

  @override
  Future<bool> didPopRoute() {
    // TODO: implement didPopRoute
    return null;
  }

  @override
  Future<bool> didPushRoute(String route) {
    // TODO: implement didPushRoute
    return null;
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    // TODO: implement didPushRouteInformation
    throw UnimplementedError();
  }
}
