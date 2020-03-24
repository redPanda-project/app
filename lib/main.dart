import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:buffer/buffer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:preferences/preference_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:redpanda/activities/ChatView.dart';
import 'package:redpanda/activities/preferences.dart';
import 'package:redpanda/service.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:path_provider/path_provider.dart';

import 'package:redpanda_light_client/export.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';

bool serviceCompletelyStarted = false;

Function mySetState;

bool serviceRunning = false;

int _counter = 0;

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['openid'],
);
final FirebaseAuth _auth = FirebaseAuth.instance;
GoogleSignInAccount googleSignInAccount;
String name = "unknown";

FirebaseUser user;
String myNick = "unknown";

AppLifecycleState _lastLifecycleState;

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
bool _isConfigured = false;

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings();
    var initializationSettings = InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Default, priority: Priority.Default, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    flutterLocalNotificationsPlugin.show(0, 'New Message', 'unknown ${data['data']}', platformChannelSpecifics,
        payload: 'item x');
    print(data.runtimeType);
    print(data);
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  print('obtained background message ${message}');

//  runService();

//  const oneSec = const Duration(seconds: 3);
//  new Timer(oneSec, () => RedPandaLightClient.shutdown());

  // Or do other work.

  return Future<void>.value();
}

void callbackDispatcher() {
  Workmanager.executeTask((task, inputData) async {
    print("Native called background task: $task"); //simpleTask will be emitted here.

//    runService();
//
//    const oneSec = const Duration(seconds: 20);
//    new Timer(oneSec, () => RedPandaLightClient.shutdown());

//

//    print("from worker22!");
    return new Future.delayed(const Duration(seconds: 22), shutdownNow);
//    return;
  });
}

bool shutdownNow() {
  print("shutdown 23123");
  RedPandaLightClient.shutdown();
  return true;
}

void main() async {
  // This captures errors reported by the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) {
    if (Service.isInDebugMode) {
      // In development mode, simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode, report to the application zone to report to
      // Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  WidgetsFlutterBinding.ensureInitialized();

  await flutterLocalNotificationsPlugin.cancelAll();

  await Workmanager.initialize(callbackDispatcher,
      // The top level function, aka callbackDispatcher
      isInDebugMode:
          true // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
      );
//  await Workmanager.cancelAll();
  await Workmanager.registerPeriodicTask("1", "task1",
//      constraints: Constraints(
//          networkType: NetworkType.connected,
//          requiresBatteryNotLow: true,
//          requiresCharging: false,
//          requiresDeviceIdle: false,
//          requiresStorageNotLow: true),
//      existingWorkPolicy: ExistingWorkPolicy.replace,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      initialDelay: Duration(minutes: 60),
      frequency: Duration(minutes: 15));

  await runService();

  if (mySetState != null) {
    mySetState(() {
      serviceCompletelyStarted = true;
      print("serviceCompletelyStarted: " + serviceCompletelyStarted.toString());
    });
  } else {
    serviceCompletelyStarted = true;
  }

//  NodeId nodeId = new NodeId.withNewKeyPair();
//  print('NodeId: ' + nodeId.toString());

  PrefService.init(prefix: 'pref_');

//  Service.sentry.captureException(exception: new Exception("test message"));

//  runApp(MyApp());
  runZoned<Future<void>>(() async {
    runApp(MyApp());
  }, onError: (error, stackTrace) {
    // Whenever an error occurs, call the `_reportError` function. This sends
    // Dart errors to the dev console or Sentry depending on the environment.
    Service.reportError(error, stackTrace);
  });
}

Future<void> handleSignIn(setState) async {
  try {
    /**
     * try to login without user interaction
     */
//    googleSignInAccount = await googleSignIn.signInSilently();

    if (googleSignInAccount == null) {
      // silent signin was not possible, show popup for login...
      googleSignInAccount = await googleSignIn.signIn();
    }
    print('signed in: ' + googleSignInAccount.toString());
    setState(() {
      name = googleSignInAccount.displayName;
    });

    final GoogleSignInAuthentication googleAuth = await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    user = (await _auth.signInWithCredential(credential)).user;
    print("signed in " + user.displayName);

//    Firestore.instance
//        .collection('global')
//        .document('counter')
//        .get()
//        .then((DocumentSnapshot ds) {
//      if (ds.exists) {
//        setState(() {
//          _counter = ds.data['counter'];
//        });
//      }
//    });

    final DocumentReference postRef = Firestore.instance.collection('users').document(user.uid);
    Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot postSnapshot = await tx.get(postRef);
      if (postSnapshot.exists) {
//        _counter = postSnapshot.data['likesCount'] + 1;
        await tx.update(postRef, <String, dynamic>{
          'likesCount': postSnapshot.data['likesCount'] + 1,
          'lastLogin': DateTime.now().millisecondsSinceEpoch
        });
      } else {
        await tx.set(postRef, <String, dynamic>{'likesCount': 0});
      }
    });

    CollectionReference reference = Firestore.instance.collection('global');
    reference.snapshots().listen((querySnapshot) {
      querySnapshot.documentChanges.forEach((DocumentChange change) {
        print('change: ' + change.document.data.toString());
        setState(() {
          _counter = change.document.data['counter'];
        });
        // Do something with change
      });
    });

//    await _googleSignIn.signOut();
  } catch (error) {
    print("error singning in..." + error.toString());
  }
}

onNewMessage(DBMessageWithFriend msg) {
  print("dkjahdnaueghruewrgjew new message: " + msg.message.content);

  if (msg.fromMe) {
    return;
  }

  // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(initializationSettingsAndroid, initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(initializationSettings, onSelectNotification: onSelectNotification);

  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name', 'your channel description',
      importance: Importance.Default, priority: Priority.Default, ticker: 'ticker');
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  flutterLocalNotificationsPlugin.show(
      0, 'New Message', '${msg?.friend?.name ?? "unknown"}: ${msg.message.content}', platformChannelSpecifics,
      payload: 'item x');
}

Future<void> runService() async {
  if (serviceRunning) {
    return;
  }

  serviceRunning = true;

  RedPandaLightClient.onNewMessage = onNewMessage;

//  SharedPreferences.setMockInitialValues({}); // set initial values here if desired

  SharedPreferences prefs = await SharedPreferences.getInstance();

  myNick = prefs.getString("pref_nickname");

  String dataFolderPath = prefs.getString("dbFolderPath");

  int port = prefs.getInt("myPort");
  if (port == null) {
    port = Utils.random.nextInt(300) + 5200;
    await prefs.setInt("myPort", port);
  }

//  print('obtained path from prefs: $dataFolderPath');

  if (prefs.getString("dbFolderPath") == null) {
    final dbFolder = await getApplicationDocumentsDirectory();
    dataFolderPath = dbFolder.path;
    prefs.setString("dbFolderPath", dataFolderPath);
  }

//  String dataFolderPath = "/data/user/0/im.redpanda/app_flutter";

//  String dataFolderPath = Directory.current.path;
//  print("path: " + dataFolderPath);

//  String nodeIdString = prefs.getString('nodeIdString');
//  KademliaId kademliaId;
//  if (nodeIdString == null) {
//    kademliaId = new KademliaId();
//    var string = kademliaId.toString();
//    await prefs.setString('nodeIdString', string);
//  } else {
//    kademliaId = KademliaId.fromString(nodeIdString);
//  }
//
//  service = new Service(kademliaId);
//  service.start();

  await RedPandaLightClient.init(dataFolderPath, port);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'redPanda',
      theme: ThemeData(
//        brightness: Brightness.dark,
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
//        primarySwatch: Colors.deepOrange,
//        primaryColor: Color.fromRGBO(57, 68, 87, 1.0),
        primaryColor: Color.fromRGBO(57, 68, 87, 1),
      ),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: MyHomePage(title: 'redPanda'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<void> onSelectNotification(String s) {}

class _MyHomePageState extends State<MyHomePage> implements WidgetsBindingObserver {
  String statusText = "Welcome, redpanda is loading...";

  @override
  void reassemble() {
//    print("shutdown reassemble");
//    RedPandaLightClient.shutdown();
    super.reassemble();
  }

  onNewStatus(String msg) {
    setState(() {
      statusText = msg;
    });
  }

  @override
  void initState() {
//    handleSignIn(setState);
    super.initState();

    RedPandaLightClient.onNewStatus = onNewStatus;

    mySetState = setState;

    WidgetsBinding.instance.addObserver(this);

    if (!_isConfigured) {
      _firebaseMessaging.requestNotificationPermissions();

      _firebaseMessaging.getToken().then((token) {
        print('token: ' + token.toString());
        //todo appDatabase
//        ConnectionService.appDatabase.insertFCMToken(token);
      });

      _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          print("onMessage: $message");
//      _showItemDialog(message);
        },
        onBackgroundMessage: myBackgroundMessageHandler,
        onLaunch: (Map<String, dynamic> message) async {
          print("onLaunch: $message");
//      _navigateToItemDetail(message);
        },
        onResume: (Map<String, dynamic> message) async {
          print("onResume: $message");
//      _navigateToItemDetail(message);
        },
      );
      _isConfigured = true;
    }
  }

  void _incrementCounter() {
    if (user != null) {
//      final DocumentReference postRef =
//          Firestore.instance.collection('users').document(user.uid);
//      Firestore.instance.runTransaction((Transaction tx) async {
//        DocumentSnapshot postSnapshot = await tx.get(postRef);
//        if (postSnapshot.exists) {
////          _counter = postSnapshot.data['likesCount'] + 1;
//          await tx.update(postRef, <String, dynamic>{
//            'likesCount': postSnapshot.data['likesCount'] + 1
//          });
//        } else {
//          await tx.set(postRef, <String, dynamic>{'likesCount': 0});
//        }
//      });
//      _incrementCounterGlobal();

    }

    print('test insert new channel');
//    for (int i = 0; i < 1; i++) {
//      RedPandaLightClient.createNewChannel("Name " + i.toString() + " " + new Random().nextInt(100).toString());
//    }

    scanQRCode();

//    setState(() {
//      // This call to setState tells the Flutter framework that something has
//      // changed in this State, which causes it to rerun the build method below
//      // so that the display can reflect the updated values. If we changed
//      // _counter without calling setState(), then the build method would not be
//      // called again, and so nothing would appear to happen.
//      _counter++;
//    });
  }

  void _incrementCounterGlobal() {
    final DocumentReference postRef = Firestore.instance.collection('global').document('counter');
    Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot postSnapshot = await tx.get(postRef);
      if (postSnapshot.exists) {
//        setState(() {
//          _counter = postSnapshot.data['counter'] + 1;
//        });
        await tx.update(postRef, <String, dynamic>{'counter': postSnapshot.data['counter'] + 1});
      } else {
        await tx.set(postRef, <String, dynamic>{'counter': 0});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Color.fromRGBO(57, 68, 87, 1.0),
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          new IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white,
              size: 40,
            ),
            onPressed: () => {
              Fluttertoast.showToast(
                  msg: "This is Center Short Toast",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIos: 1,
                  backgroundColor: Color.fromRGBO(87, 99, 107, 1.0),
                  textColor: Colors.white,
                  fontSize: 16.0),
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Preferences(googleSignIn)),
              )
            },
            padding: EdgeInsets.only(right: 30),
          )
        ],
      ),
      body: makeBody(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget makeBody(BuildContext context) {
//    var listView = ListView.builder(
//        scrollDirection: Axis.vertical,
//        padding: const EdgeInsets.all(0),
//        itemCount: service?.peerlist?.length ?? 0,
//        itemBuilder: (BuildContext context, int index) {
//          return makeCard(context, index);
////          return Container(
////            height: 50,
////            color: Colors.amber[colorCodes[index]],
////            child: Center(child: Text('Entry ${entries[index]}')),
////          );
//        }).build(context);

    Widget mainView;

    /**
     * ConnectionService.appDatabase may be null in test cases where the
     * redpanda light client library was not initialized.
     * In this case we just display a waiting spinner.
     */
    if (serviceCompletelyStarted) {
      StreamBuilder<List<DBChannel>> streamBuilder = StreamBuilder(
          stream: RedPandaLightClient.watchDBChannelEntries(),
          builder: (context, AsyncSnapshot<List<DBChannel>> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(57, 68, 87, 1.0)),
                ),
              );
            } else {
              return ListView.builder(
                padding: EdgeInsets.all(10.0),
                itemBuilder: (context, index) => makeCard2(context, snapshot, index),
                itemCount: snapshot.data.length,
              );
            }
          });

      mainView = streamBuilder;
    } else {
      mainView = Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(1, 1, 1, 1)),
        ),
      );

//      return Column(
//        // Center is a layout widget. It takes a single child and positions it
//        // in the middle of the parent.
//        // Column is also a layout widget. It takes a list of children and
//        // arranges them vertically. By default, it sizes itself to fit its
//        // children horizontally, and tries to be as tall as its parent.
//        //
//        // Invoke "debug painting" (press "p" in the console, choose the
//        // "Toggle Debug Paint" action from the Flutter Inspector in Android
//        // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
//        // to see the wireframe for each widget.
//        //
//        // Column has various properties to control how it sizes itself and
//        // how it positions its children. Here we use mainAxisAlignment to
//        // center the children vertically; the main axis here is the vertical
//        // axis because Columns are vertical (the cross axis would be
//        // horizontal).
//        mainAxisAlignment: MainAxisAlignment.start,
//        crossAxisAlignment: CrossAxisAlignment.start,
//        children: <Widget>[
//          Text(
//            'Hello $name: $_counter',
//          ),
////          Text(
////            '$_counter',
////            style: Theme.of(context).textTheme.display1,
////          ),
//          Expanded(child: listView)
//        ],
//      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.all(8.0).copyWith(bottom: 4).copyWith(left: 14),
          child: Text(statusText, style: Theme.of(context).textTheme.title.copyWith(color: Colors.white10)),
        ),

//          Text(
//            '$_counter',
//            style: Theme.of(context).textTheme.display1,
//          ),
        Expanded(child: mainView)
      ],
    );
  }

//  Widget makeCard(BuildContext context, int index) {
//    return Card(
//      elevation: 1.0,
//      margin: new EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
//      child: Container(
//        decoration: BoxDecoration(color: Color.fromRGBO(65, 74, 95, .9)),
//        child: makeListTile(index),
//      ),
//    );
//  }

  Widget makeCard2(BuildContext context, AsyncSnapshot<List<DBChannel>> snapshot, int index) {
    print('snapshot len: ' + snapshot.data.length.toString());

    return Card(
      elevation: 1.0,
      margin: new EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(65, 74, 95, .9)),
        child: makeListTile2(snapshot, index),
      ),
    );
  }

//  Widget makeListTile(int index) {
//    return ListTile(
//        onLongPress: () {
//          chatLongPress(index);
//        },
//        onTap: () {
//          chatOnTap(index);
//        },
//        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//        leading: Container(
//          padding: EdgeInsets.only(right: 12.0),
//          decoration: new BoxDecoration(
//              border: new Border(
//                  right: new BorderSide(width: 1.0, color: Colors.white24))),
//          child: Icon(
//            Icons.account_circle,
//            color: Colors.white,
//            size: 55,
//          ),
//        ),
//        title: Text(
////          "Friend $index/$_counter " + service?.peerlist[0].ip ?? "no ip",
//          "" +
//              (service?.peerlist[index].ip ?? "no ip ") +
//              " " +
//              (service?.peerlist[index].connecting.toString() ?? "no ip") +
//              " $index/$_counter",
//          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//        ),
//        // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),
//
//        subtitle: Row(
//          children: <Widget>[
//            Icon(Icons.vpn_key, color: Colors.yellowAccent),
//            Text(
//                "Connected: " +
//                    (service?.peerlist[index].connecting.toString() ?? "no"),
//                style: TextStyle(color: Colors.white))
//          ],
//        ),
//        trailing:
//            Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0));
//  }

  Widget makeListTile2(AsyncSnapshot<List<DBChannel>> snapshot, int index) {
    return ListTile(
        onLongPress: () {
          chatLongPress2(snapshot, index);
        },
        onTap: () {
          chatOnTap(snapshot, index);
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: new BoxDecoration(border: new Border(right: new BorderSide(width: 1.0, color: Colors.white24))),
          child: Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 55,
          ),
        ),
        title: Text(
          snapshot.data[index].name,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

        subtitle: Row(
          children: <Widget>[
//            Icon(Icons.vpn_key, color: Colors.yellowAccent),
            Text(
                (snapshot.data[index].lastMessage_user ?? "unknown") +
                    ": " +
                    (snapshot.data[index].lastMessage_text ?? "unknown"),
                style: TextStyle(color: Colors.white))
          ],
        ),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0));
  }

  void chatLongPress(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Clicked!"),
          content: new Text("Du hast auf nummer $index LAANGE geklickt!"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void chatLongPress2(AsyncSnapshot<List<DBChannel>> snapshot, int index) {
    String textValue;

    TextField textField = TextField(
      decoration: InputDecoration(hintText: 'new name for ${snapshot.data[index].name}'),
      onChanged: (String value) async {
        textValue = value;
      },
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog

        var qrdata = {};
        qrdata['sharedFromNick'] = myNick;
        qrdata['sharedSecret'] = Utils.base58encode(snapshot.data[index].sharedSecret);
        qrdata['privateSigningKey'] = Utils.base58encode(snapshot.data[index].nodeId);

        String message = jsonEncode(qrdata);

        var qrCodeImage = CustomPaint(
          size: Size.square(80),
          painter: QrPainter(
            data: message,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            version: QrVersions.auto,
            color: Colors.black,
            emptyColor: Colors.white,
            gapless: true,
            embeddedImageStyle: QrEmbeddedImageStyle(
              size: Size.square(60),
            ),
          ),
        );

        var qrCodeImageWithOnTap = GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: message));
            Fluttertoast.showToast(
                msg: "Channel copied to clipboard.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIos: 1,
                backgroundColor: Color.fromRGBO(87, 99, 107, 1.0),
                textColor: Colors.white,
                fontSize: 16.0);
          },
          child: qrCodeImage,
        );

        return AlertDialog(
          title: new Text("Settings [${snapshot.data[index].name}]"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 0).copyWith(bottom: 40),
                    child: qrCodeImageWithOnTap,
                  ),
                ),
                Text('Change name for Channel:'),
                textField
              ],
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("cancle"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("remove"),
              onPressed: () {
                Navigator.of(context).pop();
                RedPandaLightClient.removeChannel(snapshot.data[index].id);
              },
            ),
            new FlatButton(
              child: new Text("ok"),
              onPressed: () {
                Navigator.of(context).pop();

                if (textValue != null) {
                  RedPandaLightClient.renameChannel(snapshot.data[index].id, textValue);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void chatOnTap(AsyncSnapshot<List<DBChannel>> snapshot, int index) {
    DBChannel channel = snapshot.data[index];

    Navigator.push(context, MaterialPageRoute(builder: (context) => ChatView(channel.id, channel)));

//    RedPandaLightClient.removeChannel(snapshot.data[index].id);
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        return AlertDialog(
//          title: new Text("Clicked!"),
//          content: new Text("Du hast auf nummer $index getappt!!"),
//          actions: <Widget>[
//            // usually buttons at the bottom of the dialog
//            new FlatButton(
//              child: new Text("Close"),
//              onPressed: () {
//                Navigator.of(context).pop();
//              },
//            ),
//          ],
//        );
//      },
//    );
  }

  @override
  void dispose() {
    print("shutdown dispose");
    RedPandaLightClient.shutdown();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() {
    // TODO: implement didChangeAccessibilityFeatures
  }

  Timer shutdownTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
//      const timeRepeatConectionMaintain = Duration(minutes: 10);
//      shutdownTimer = new Timer(timeRepeatConectionMaintain, () {
//        RedPandaLightClient.shutdown();
//        serviceRunning = false;
//      });
    } else if (state == AppLifecycleState.resumed) {
      if (shutdownTimer != null) {
        shutdownTimer.cancel();
      }
//      runService();
      flutterLocalNotificationsPlugin.cancelAll();
    }

    print('new app state: ' + state.toString());
//    setState(() {
    _lastLifecycleState = state;
//    });
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
    return Future<bool>.value(false);
  }

  @override
  Future<bool> didPushRoute(String route) {
    return Future<bool>.value(false);
  }

  void scanQRCode() async {
    String barcode = await BarcodeScanner.scan();

    var qrdata = jsonDecode(barcode);

    RedPandaLightClient.channelFromData(qrdata['sharedFromNick'], Utils.base58decode(qrdata['sharedSecret']),
        Utils.base58decode(qrdata['privateSigningKey']));
  }
}