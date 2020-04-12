package im.redpanda;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService;
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin;
import io.flutter.plugins.firebase.firebaseremoteconfig.FirebaseRemoteConfigPlugin;

import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin;

import com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin;

//public class Application extends FlutterApplication implements PluginRegistrantCallback {
//    @Override
//    public void onCreate() {
//        super.onCreate();
//        FlutterFirebaseMessagingService.setPluginRegistrant(this);
//    }
//
//    @Override
//    public void registerWith(PluginRegistry registry) {
//        GeneratedPluginRegistrant.registerWith(registry);
//    }
//}

public class Application extends FlutterApplication implements PluginRegistrantCallback {
    @Override
    public void onCreate() {
        super.onCreate();
        FlutterFirebaseMessagingService.setPluginRegistrant(this);
    }

    @Override
    public void registerWith(PluginRegistry registry) {
        /**
         * Here we have to add all plugins which should be available in the background method!
         *
         * Only for the MainActivity the Plugins are automatically loaded via io.flutter.plugins.GeneratedPluginRegistrant,
         * see this file for the available plugins and options.
         *
         * See for help: https://stackoverflow.com/questions/54759121/android-alarm-manager-is-not-working-for-flutter-project-app/55834355#55834355
         */
        FirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
        SharedPreferencesPlugin.registerWith(registry.registrarFor("io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin"));

        FlutterLocalNotificationsPlugin.registerWith(registry.registrarFor("com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin"));

        FirebaseRemoteConfigPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebaseremoteconfig.FirebaseRemoteConfigPlugin"));

    }
}