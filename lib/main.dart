import 'dart:async';
import 'dart:convert';
import 'package:bmine_slice/Utils/DeepLinkHandler.dart';
import 'package:bmine_slice/Utils/appassets.dart';
import 'package:bmine_slice/Utils/appstyle.dart';
import 'package:bmine_slice/Utils/colorutils.dart';
import 'package:bmine_slice/Utils/grediant_text.dart';
import 'package:bmine_slice/Utils/user_status_service.dart';
import 'package:bmine_slice/Utils/utils.dart';
import 'package:bmine_slice/localization/language/languages.dart';
import 'package:bmine_slice/localization/locale_constants.dart';
import 'package:bmine_slice/localization/localizations_delegate.dart';
import 'package:bmine_slice/screen/bottemnavbar.dart';
import 'package:bmine_slice/screen/login.dart';
import 'package:bmine_slice/viewmodels/eventfeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/forgotpasswordviewmodel.dart';
import 'package:bmine_slice/viewmodels/homefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/likefeedviewmodel.dart';
import 'package:bmine_slice/viewmodels/loginviewmodel.dart';
import 'package:bmine_slice/viewmodels/meetingviewmodel.dart';
import 'package:bmine_slice/viewmodels/notificationsviewmodel.dart';
import 'package:bmine_slice/viewmodels/profileviewmodel.dart';
import 'package:bmine_slice/viewmodels/purchaseviewmodel.dart';
import 'package:bmine_slice/viewmodels/signupviewmodel.dart';
import 'package:bmine_slice/viewmodels/userreportviewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_badge_manager/flutter_badge_manager.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({Key? key}) : super(key: key);

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  late DeepLinkHandler _deepLinkHandler;

  Future<void> _initializeDeepLinks() async {
    await _deepLinkHandler.initDeepLinks();
  }

  @override
  void initState() {
    super.initState();
    // Add a post-frame callback to ensure the context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkHandler = DeepLinkHandler(navigatorKey: navigatorKey);
      _initializeDeepLinks();
      _checkLoginAndNavigate();
    });
  }

  Future<void> _checkLoginAndNavigate() async {
    // Initialize Firebase and other necessary services
    await Firebase.initializeApp();

    // Get SharedPreferences instance
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clear some temporary preferences
    await prefs.setBool("IsLocationStart", false);
    await prefs.remove("last_feed_position");
    await prefs.remove("last_leave_page");

    // Check login status
    bool isLogin = prefs.getBool("isLogin") ?? false;
    String firebaseId = prefs.getString("firebaseId") ?? "";

    // Initialize user status if firebaseId exists
    if (firebaseId.isNotEmpty) {
      UserStatusService().init(firebaseId);
    }

    // Determine which screen to show
    Widget targetScreen = isLogin ? BottomNavBar() : const LoginScreen();

    // Remove native splash screen
    FlutterNativeSplash.remove();

    // Navigate to the appropriate screen
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => targetScreen));
  }

  @override
  Widget build(BuildContext context) {
    // This build method is for the initial splash screen before native splash is removed
    return Scaffold(
      backgroundColor: AppColors.whiteclr,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              AppAssets.applogo,
              width: 250,
              height: 195,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 25,
            child: Center(
              child: GradientText(
                text: Languages.of(context)!.bminetxt,
                style: Appstyle.marcellusSC45w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AndroidNotificationChannel channel = const AndroidNotificationChannel(
    '102030',
    'BMINE',
    importance: Importance.high,
    playSound: true,
  );

  Map<String, dynamic> pushData = message.data;
  print("pushData == $pushData");
  if (pushData.isNotEmpty) {
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      pushData['title'],
      pushData['body'],
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
    );
  }
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   setupFirebaseMessaging();
//   initializeNotifications();
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//   SystemChrome.setPreferredOrientations(
//       [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
//   runApp(const MyApp());
// }
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  setupFirebaseMessaging();
  initializeNotifications();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      Map valueMap = jsonDecode(response.payload!);
      openScreenFromNotitification({});
    },
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

void setupFirebaseMessaging() {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    '102030',
    'BMINE',
    importance: Importance.high,
    playSound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: 'BMINE Notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    Map data = message.toMap();
    openScreenFromNotitification(data);
  });
}

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) {
    var state = context.findAncestorStateOfType<_MyAppState>();
    state!.setLocale(newLocale);
  }

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  String isLanguage = "en";

  Locale? _locale;
  getLocalLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isLanguage = prefs.getString("SelectedLanguageCode") ?? "en";
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    getLocalLang();
  }

  @override
  void didChangeDependencies() async {
    getLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
    });
    super.didChangeDependencies();
  }

  bool isLogin = false;

  void getFirebaseIdandToken() async {
    FlutterBadgeManager.remove();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await prefs.setString('fcmToken', fcmToken);
      print("FCM Token: $fcmToken");
    }
    prefs.setBool("IsLocationStart", false);
    prefs.remove("last_feed_position");
    prefs.remove("last_leave_page");
    String firebaseId = "";
    setState(() {
      isLogin = prefs.getBool("isLogin") ?? false;
      firebaseId = prefs.getString("firebaseId") ?? "";
    });
    if (firebaseId.isNotEmpty) {
      UserStatusService().init(firebaseId);
    }
  }

  // Future<bool> checkLoginStatus() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     isLogin = prefs.getBool("isLogin") ?? false;
  //   });
  //   return isLogin;
  // }

  @override
  void initState() {
    super.initState();
    getFirebaseIdandToken();
    setupFirebaseMessaging();
    initializeNotifications();
  }

  void initializeNotifications() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);

    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is for important notifications.',
      importance: Importance.high,
    );
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SignUpViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotPassViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => HomeFeedViewModel()),
        ChangeNotifierProvider(create: (_) => LikeFeedViewModel()),
        ChangeNotifierProvider(create: (_) => EventFeedViewModel()),
        ChangeNotifierProvider(create: (_) => MeetingViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ChangeNotifierProvider(create: (_) => UserReportViewModel()),
        ChangeNotifierProvider(create: (_) => PurchaseViewModel()),
      ],
      child: MaterialApp(
        locale: _locale,
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (locale, supportedLocales) {
          for (var supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale?.languageCode &&
                supportedLocale.countryCode == locale?.countryCode) {
              return supportedLocale;
            }
          }
          return supportedLocales.first;
        },
        debugShowCheckedModeBanner: false,
        title: 'BMINE',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home:
            //  Platform.isIOS
            //     ? isLogin
            //         ? BottomNavBar()
            //         : const LoginScreen()
            //     :
            const Splashscreen(),
      ),
    );
  }
}

// class Splashscreen extends StatefulWidget {
//   const Splashscreen({super.key});

//   @override
//   State<Splashscreen> createState() => _SplashscreenState();
// }

// class _SplashscreenState extends State<Splashscreen>
//     with WidgetsBindingObserver {
//   bool isLogin = false;

//   @override
//   void initState() {
//     super.initState();
//     checkLoginStatus();
//   }

//   void checkLoginStatus() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     prefs.setBool("IsLocationStart", false);
//     prefs.remove("last_feed_position");
//     prefs.remove("last_leave_page");

//     String firebaseId = "";
//     setState(() {
//       isLogin = prefs.getBool("isLogin") ?? false;
//       firebaseId = prefs.getString("firebaseId") ?? "";
//     });
//     if (firebaseId.isNotEmpty) {
//       UserStatusService().init(firebaseId);
//     }
//     Future.delayed(const Duration(seconds: 3), () {
//       if (isLogin) {
//         navigateToScreen(BottomNavBar());
//       } else {
//         navigateToScreen(const LoginScreen());
//       }
//     });
//   }

//   void navigateToScreen(Widget screen) {
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (context) => screen),
//       (Route<dynamic> route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.whiteclr,
//       body: Stack(
//         children: [
//           Center(
//             child: Image.asset(
//               AppAssets.applogo,
//               width: 250,
//               height: 195,
//               fit: BoxFit.fill,
//             ),
//           ),
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 25,
//             child: Center(
//               child: GradientText(
//                 text: Languages.of(context)!.bminetxt,
//                 style: Appstyle.marcellusSC45w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
