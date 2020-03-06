import 'package:flutter/material.dart';
import 'package:buffer/buffer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:redpanda/redPanda/KademliaId.dart';
import 'package:redpanda/redPanda/Peer.dart';
import 'package:redpanda/redPanda/Utils.dart';
import 'package:redpanda/service.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';

Service service;

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['openid'],
);

void main() async {
  _handleSignIn();

  runApp(MyApp());
  runService();
}

Future<void> _handleSignIn() async {
  try {
    await _googleSignIn.signIn();
  } catch (error) {
    print(error);
  }
}

void runService() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String nodeIdString = prefs.getString('nodeIdString');
  KademliaId kademliaId;
  if (nodeIdString == null) {
    kademliaId = new KademliaId();
    var string = kademliaId.toString();
    await prefs.setString('nodeIdString', string);
  } else {
    kademliaId = KademliaId.fromString(nodeIdString);
  }

  service = new Service(kademliaId);
  service.start();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'redPanda',
      theme: ThemeData(
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
        primaryColor: Color.fromRGBO(57, 68, 87, 1.0),
      ),
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    Utils.states.add(setState);

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
                  fontSize: 16.0)
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

    return Column(
      // Center is a layout widget. It takes a single child and positions it
      // in the middle of the parent.
      // Column is also a layout widget. It takes a list of children and
      // arranges them vertically. By default, it sizes itself to fit its
      // children horizontally, and tries to be as tall as its parent.
      //
      // Invoke "debug painting" (press "p" in the console, choose the
      // "Toggle Debug Paint" action from the Flutter Inspector in Android
      // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
      // to see the wireframe for each widget.
      //
      // Column has various properties to control how it sizes itself and
      // how it positions its children. Here we use mainAxisAlignment to
      // center the children vertically; the main axis here is the vertical
      // axis because Columns are vertical (the cross axis would be
      // horizontal).
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'You have pushed the button this many times: $_counter',
        ),
//          Text(
//            '$_counter',
//            style: Theme.of(context).textTheme.display1,
//          ),
        Expanded(child: listView)
      ],
    );
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

  void chatOnTap(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Clicked!"),
          content: new Text("Du hast auf nummer $index getappt!!"),
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
}
