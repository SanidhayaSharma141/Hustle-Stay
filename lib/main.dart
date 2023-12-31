import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hustle_stay/models/complaint/complaint.dart';
import 'package:hustle_stay/models/requests/request.dart';
import 'package:hustle_stay/models/user/user.dart';
import 'package:hustle_stay/providers/settings.dart';
import 'package:hustle_stay/screens/auth/auth_screen.dart';
import 'package:hustle_stay/screens/intro/intro_screen.dart';
import 'package:hustle_stay/screens/main_screen.dart';
import 'package:hustle_stay/screens/requests/attendance/attendance_request_screen.dart';
import 'package:hustle_stay/screens/requests/mess/mess_request_screen.dart';
import 'package:hustle_stay/screens/requests/other/other_request_screen.dart';
import 'package:hustle_stay/screens/requests/vehicle/vehicle_requests_screen.dart';
import 'package:hustle_stay/tools.dart';
import 'package:hustle_stay/widgets/other/loading_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

/// Shared Preferences Object
/// Used for saving/loading settings
SharedPreferences? prefs;

/// Instead of creating multiple instances of the same object
/// I created then altogether here
final auth = FirebaseAuth.instance;
final firestore = FirebaseFirestore.instance;
final storage = FirebaseStorage.instance;
final firebaseMessaging = FirebaseMessaging.instance;

/// Main function
void main() async {
  /// Just to show errors not so rudely
  setErrorWidget();

  // Initializing Firebase SDK
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initializing prefs here in main to avoid any delay in activating settings
  prefs = await SharedPreferences.getInstance();
  try {
    if (auth.currentUser != null) {
      currentUser = await fetchUserData(
        auth.currentUser!.email!,
      );
    }
  } catch (e) {}
  // Correction code
  // if (kDebugMode && currentUser.isAdmin) {
  //   Query<Map<String, dynamic>> query = firestore.collection('categories');
  //   final response = await query.get();
  //   response.docs.map((doc) => Category(doc.id)..load(doc.data())).forEach(
  //     (element) async {
  //       debugPrint('Updating Category: ${element.id}');
  //       await updateCategory(element);
  //     },
  //   );
  // }
  runApp(const ProviderScope(child: HustleStayApp()));
}

void setErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          ':-( Something went wrong!',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
        Text(
          '\n${details.exception}',
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
        const Text(
          'Contact shivanshukgupta or sanidhayasharma141 on linkedin for support\n',
          textAlign: TextAlign.center,
        ),
      ],
    ));
  };
}

/// The main app widget
class HustleStayApp extends ConsumerWidget {
  const HustleStayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // the settings object
    final settings = ref.watch(settingsProvider);
    if (settings.autoDarkMode == true) {
      settings.darkMode =
          MediaQuery.of(context).platformBrightness == Brightness.dark;
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hustle Stay',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          brightness: settings.darkMode ? Brightness.dark : Brightness.light,
          seedColor: Colors.blue,
        ),
        textTheme: GoogleFonts.quicksandTextTheme().apply(
          bodyColor: settings.darkMode ? Colors.white : Colors.black,
          displayColor: settings.darkMode ? Colors.white : Colors.black,
        ),
      ),
      routes: {
        /// The app switches from Auth Screen to HomeScreen
        /// according to auth state
        '/': (context) => settings.introductionScreenVisited
            ? StreamBuilder(
                stream: auth.authStateChanges(),
                builder: (ctx, user) {
                  if (user.hasData) {
                    return currentUser.email != null
                        ? const MainScreen()
                        : Scaffold(
                            body: LoadingBuilder(
                              loadingWidgetBuilder: (context, value, child) {
                                return Center(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      circularProgressIndicator(),
                                      const Text('Fetching user details...'),
                                    ],
                                  ),
                                );
                              },
                              builder: (context, progress) async {
                                if (auth.currentUser != null) {
                                  currentUser = await fetchUserData(
                                    auth.currentUser!.email!,
                                    src: null,
                                  );
                                }
                                return const MainScreen();
                              },
                            ),
                          );
                  }
                  return const AuthScreen();
                },
              )
            : IntroScreen(
                done: () {
                  settings.introductionScreenVisited = true;
                  ref.read(settingsProvider.notifier).notifyListeners();
                },
              ),
        AttendanceRequestScreen.routeName: (context) =>
            const AttendanceRequestScreen(),
        VehicleRequestScreen.routeName: (context) =>
            const VehicleRequestScreen(),
        MessRequestScreen.routeName: (context) => const MessRequestScreen(),
        OtherRequestScreen.routeName: (context) => OtherRequestScreen(),
      },
    );
  }
}

ValueNotifier<String?> everythingInitialized = ValueNotifier(null);

Future<void> initializeEverything() async {
  if (currentUser.permissions.users.read == true) {
    everythingInitialized.value = "Fetching users";
    await initializeUsers();
  }
  everythingInitialized.value = "Fetching complaints";
  await initializeComplaints();
  everythingInitialized.value = "Fetching requests";
  await initializeRequests();

  if (currentUser.type == 'warden' ||
      currentUser.email == 'vehicle@iiitr.ac.in') {
    everythingInitialized.value = "Fetching vehicle requests";
    await initializeVehicleRequests();
  }
  everythingInitialized.value = null;
}

/// ON BACKGROUND MESSAGE
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint(message.notification!.body);
  // TODO: handle a background msg
  // if a complaint is updated/created/deleted then fetch it from server if it doesn't exists in cache
  // if a message is there and if the complaint/request doesn't exists then fetch it from the server
}

/// Initializes FCM token and saves it onto the cloud.
/// Also, sets a background handler for fcm
Future<void> initializeFCM() async {
  /// Requesting permission to show notifications is done in MainScreen init method
  /// ON TOKEN REFRESH METHOD
  firebaseMessaging.onTokenRefresh.listen((fcmToken) {
    if (currentUser.fcmToken != fcmToken) {
      debugPrint("FCM Token was refreshed. The new token is: $fcmToken");
      currentUser.fcmToken = fcmToken;
      updateUserData(currentUser).onError((error, stackTrace) {
        debugPrint('Failed to update fcmToken on Firebase: $error');
      });
    }
  }).onError((err) {
    debugPrint("Error Getting Firebase token: $err");
  });

  final fcmToken = await firebaseMessaging.getToken();
  if (fcmToken != null) {
    currentUser.fcmToken = fcmToken;
    updateUserData(currentUser).onError((error, stackTrace) {
      debugPrint('Failed to update fcmToken on Firebase: $error');
    });
  }
  debugPrint("fcmToken = $fcmToken");

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
