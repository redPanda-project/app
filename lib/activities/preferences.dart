import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:preferences/preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';

class Preferences extends StatelessWidget {
  GoogleSignIn googleSignIn;

  Preferences(this.googleSignIn);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preferences Demo'),
      ),
      body: PreferencePage([
        PreferenceTitle('General'),
        DropdownPreference(
          'Start Page',
          'start_page',
          defaultVal: 'Timeline',
          values: ['Posts', 'Timeline', 'Private Messages'],
        ),
        PreferenceTitle('Personalization'),
        RadioPreference(
          'Light Theme',
          'light',
          'ui_theme',
          isDefault: true,
        ),
        RadioPreference(
          'Dark Theme',
          'dark',
          'ui_theme',
        ),
        PreferenceTitle('Google SignIn'),
        SwitchPreference('Log out', 'logout',
            onEnable: () => {
                  googleSignIn.signOut(),
                  Fluttertoast.showToast(
                      msg: "logged out",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIos: 1,
                      backgroundColor: Color.fromRGBO(87, 99, 107, 1.0),
                      textColor: Colors.white,
                      fontSize: 16.0)
                },
            onDisable: () => {
                  googleSignIn.signOut(),
                  Fluttertoast.showToast(
                      msg: "logged out",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                      timeInSecForIos: 1,
                      backgroundColor: Color.fromRGBO(87, 99, 107, 1.0),
                      textColor: Colors.white,
                      fontSize: 16.0)
                }),
      ]),
    );
  }
}
