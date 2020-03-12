import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:buffer/buffer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:preferences/preference_service.dart';
import 'package:redpanda/activities/preferences.dart';
import 'package:redpanda/redPanda/KademliaId.dart';
import 'package:redpanda/redPanda/Peer.dart';
import 'package:redpanda/redPanda/Utils.dart';
import 'package:redpanda/service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:redpanda_light_client/src/main/ConnectionService.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:path_provider/path_provider.dart';

import 'package:redpanda_light_client/export.dart';

Service service;

int _counter = 0;

GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: ['openid'],
);
final FirebaseAuth _auth = FirebaseAuth.instance;
GoogleSignInAccount googleSignInAccount;
String name = "unknown";

FirebaseUser user;

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

  await runService();

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

    final GoogleSignInAuthentication googleAuth =
        await googleSignInAccount.authentication;

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

    final DocumentReference postRef =
        Firestore.instance.collection('users').document(user.uid);
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

Future<void> runService() async {
//  SharedPreferences prefs = await SharedPreferences.getInstance();
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

  final dbFolder = await getApplicationDocumentsDirectory();

  String dataFolderPath = dbFolder.path;

  await RedPandaLightClient.init(dataFolderPath);
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

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
//    handleSignIn(setState);
    Utils.states.add(setState);
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

    if (ConnectionService.appDatabase != null) {
      print('test insert new channel');
      ChannelsCompanion channelsCompanion = ChannelsCompanion.insert(
          title: "Title" + new Random().nextInt(100).toString(),
          lastMessage_text: "what's up?",
          lastMessage_user: "james");
      ConnectionService.appDatabase.insertChannel(channelsCompanion);
    }

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
    final DocumentReference postRef =
        Firestore.instance.collection('global').document('counter');
    Firestore.instance.runTransaction((Transaction tx) async {
      DocumentSnapshot postSnapshot = await tx.get(postRef);
      if (postSnapshot.exists) {
//        setState(() {
//          _counter = postSnapshot.data['counter'] + 1;
//        });
        await tx.update(postRef,
            <String, dynamic>{'counter': postSnapshot.data['counter'] + 1});
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
                MaterialPageRoute(
                    builder: (context) => Preferences(googleSignIn)),
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
    var listView = ListView.builder(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(0),
        itemCount: service?.peerlist?.length ?? 0,
        itemBuilder: (BuildContext context, int index) {
          return makeCard(context, index);
//          return Container(
//            height: 50,
//            color: Colors.amber[colorCodes[index]],
//            child: Center(child: Text('Entry ${entries[index]}')),
//          );
        }).build(context);

    print('dggeer ' + ConnectionService.appDatabase.toString());

    /**
     * ConnectionService.appDatabase may be null in test cases where the
     * redpanda light client library was not initialized.
     * In this case we just display a waiting spinner.
     */
    if (ConnectionService.appDatabase != null) {
      Stream<List<Channel>> stream =
          ConnectionService.appDatabase.watchChannelEntries();
      print('channel stream: ' + stream.toString());

      StreamBuilder<List<Channel>> streamBuilder = StreamBuilder(
          stream: stream,
          builder: (context, AsyncSnapshot<List<Channel>> snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(57, 68, 87, 1.0)),
                ),
              );
            } else {
              return ListView.builder(
                padding: EdgeInsets.all(10.0),
                itemBuilder: (context, index) =>
                    makeCard2(context, snapshot, index),
                itemCount: snapshot.data.length,
              );
            }
          });

      return streamBuilder;
    } else {
      return Center(
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
  }

  Widget makeCard(BuildContext context, int index) {
    return Card(
      elevation: 1.0,
      margin: new EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(65, 74, 95, .9)),
        child: makeListTile(index),
      ),
    );
  }

  Widget makeCard2(
      BuildContext context, AsyncSnapshot<List<Channel>> snapshot, int index) {
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

  Widget makeListTile(int index) {
    return ListTile(
        onLongPress: () {
          chatLongPress(index);
        },
        onTap: () {
          chatOnTap(index);
        },
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        leading: Container(
          padding: EdgeInsets.only(right: 12.0),
          decoration: new BoxDecoration(
              border: new Border(
                  right: new BorderSide(width: 1.0, color: Colors.white24))),
          child: Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 55,
          ),
        ),
        title: Text(
//          "Friend $index/$_counter " + service?.peerlist[0].ip ?? "no ip",
          "" +
              (service?.peerlist[index].ip ?? "no ip ") +
              " " +
              (service?.peerlist[index].connecting.toString() ?? "no ip") +
              " $index/$_counter",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

        subtitle: Row(
          children: <Widget>[
            Icon(Icons.vpn_key, color: Colors.yellowAccent),
            Text(
                "Connected: " +
                    (service?.peerlist[index].connecting.toString() ?? "no"),
                style: TextStyle(color: Colors.white))
          ],
        ),
        trailing:
            Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0));
  }

  Widget makeListTile2(AsyncSnapshot<List<Channel>> snapshot, int index) {
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
          decoration: new BoxDecoration(
              border: new Border(
                  right: new BorderSide(width: 1.0, color: Colors.white24))),
          child: Icon(
            Icons.account_circle,
            color: Colors.white,
            size: 55,
          ),
        ),
        title: Text(
          snapshot.data[index].title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

        subtitle: Row(
          children: <Widget>[
//            Icon(Icons.vpn_key, color: Colors.yellowAccent),
            Text(
                snapshot.data[index].lastMessage_user +
                    ": " +
                    snapshot.data[index].lastMessage_text,
                style: TextStyle(color: Colors.white))
          ],
        ),
        trailing:
            Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0));
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

  void chatLongPress2(AsyncSnapshot<List<Channel>> snapshot, int index) {
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
              child: new Text("remove"),
              onPressed: () {
                Navigator.of(context).pop();
                ConnectionService.appDatabase
                    .removeChannel(snapshot.data[index].id);
              },
            ),
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

  void chatOnTap(AsyncSnapshot<List<Channel>> snapshot, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        ConnectionService.appDatabase.removeChannel(snapshot.data[index].id);
        // return object of type Dialog
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
      },
    );
  }
}
