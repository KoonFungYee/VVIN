import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:badges/badges.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/companyDB.dart';
import 'package:vvin/data.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/leadsDB.dart';
import 'package:vvin/mainscreenNotiDB.dart';
import 'package:vvin/myworks.dart';
import 'package:vvin/myworksDB.dart';
import 'package:vvin/notiDB.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/profile.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/reminderList.dart';
import 'package:vvin/settings.dart';
import 'package:vvin/topViewDB.dart';
import 'package:vvin/vDataDB.dart';
import 'package:vvin/vanalytics.dart';
import 'package:vvin/vanalyticsDB.dart';
import 'package:vvin/vdata.dart';
import 'login.dart';

class More extends StatefulWidget {
  More({Key key}) : super(key: key);

  @override
  _MoreState createState() => _MoreState();
}

enum UniLinksType { string, uri }

class _MoreState extends State<More> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  final ScrollController controller = ScrollController();
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool start, connection, ready;
  int currentTabIndex;
  SharedPreferences prefs;
  String urlNoti = "https://vvinoa.vvin.com/api/notiTotalNumber.php";
  String companyURL = "https://vvinoa.vvin.com/api/companyProfile.php";
  String urlLogout = "https://vvinoa.vvin.com/api/logout.php";
  String urlReminder = "https://vvinoa.vvin.com/api/reminder.php";
  String level,
      companyID,
      userID,
      userType,
      name,
      phone,
      email,
      website,
      address,
      image,
      unassign,
      assign,
      nameLocal,
      location,
      now,
      totalNotification;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    totalNotification = "0";
    currentTabIndex = 4;
    connection = false;
    checkConnection();
    initialize();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        prefs = await SharedPreferences.getInstance();
        _showNotification();
      },
      onResume: (Map<String, dynamic> message) async {
        List time = message.toString().split('google.sent_time: ');
        String noti = time[1].toString().substring(0, 13);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (prefs.getString('newNoti') != noti) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => Notifications(),
            ),
          );
        }
      },
    );
    super.initState();
  }

  void check() async {
    if (_type == UniLinksType.string) {
      _sub = getLinksStream().listen((String link) {
        // FlutterWebBrowser.openWebPage(
        //   url: "https://" + link.substring(12),
        // );
      }, onError: (err) {});
    }
  }

  Future<void> _init() async {
    WidgetsFlutterBinding.ensureInitialized();
    notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    var initializationSettingsAndroid = AndroidInitializationSettings('vvin');
    var initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification:
            (int id, String title, String body, String payload) async {
          didReceiveLocalNotificationSubject.add(ReceivedNotification(
              id: id, title: title, body: body, payload: payload));
        });
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String payload) async {
      selectNotificationSubject.add(payload);
    });
    _requestIOSPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Ok'),
              onPressed: () async {},
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (payload.substring(0, 8) == 'reminder') {
        if (prefs.getString('reminder') != payload) {
          List list = payload.substring(8).split('~!');
          int dataid = int.parse(list[0]);
          String date = list[1].toString().substring(0, 10);
          String time = list[1].toString().substring(12);
          String name = list[2];
          String phone = list[3];
          String remark = list[4];
          String status = list[5];
          int datetime = int.parse(list[6]);
          Database db = await ReminderDB.instance.database;
          await db.rawInsert(
              'UPDATE reminder SET status = "cancel" WHERE dataid = ' +
                  dataid.toString());
          Navigator.of(context).push(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: Reminder(
                dataid: dataid,
                date: date,
                time: time,
                name: name,
                phone: phone,
                remark: remark,
                status: status,
                datetime: datetime),
          ));
          prefs.setString('reminder', payload);
        }
      } else {
        if (prefs.getString('onMessage') != payload) {
          Navigator.of(context).push(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: Notifications(),
          ));
        }
        prefs.setString('onMessage', payload);
      }
    });
  }

  Future<void> _showNotification() async {
    now = DateTime.now().millisecondsSinceEpoch.toString();
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        "You've received a new lead from ...",
        'Click here to view now',
        platformChannelSpecifics,
        payload: now);
  }

  void onTapped(int index) {
    if (index != 4) {
      switch (index) {
        case 0:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: VAnalytics(),
          ));
          break;
        case 1:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: VData(),
          ));
          break;
        case 2:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: MyWorks(),
          ));
          break;
        case 3:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: Notifications(),
          ));
          break;
      }
    }
  }

  @override
  void dispose() {
    if (_sub != null) _sub.cancel();
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    YYDialog.init(context);
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          onTap: onTapped,
          currentIndex: currentTabIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.trending_up,
                size: ScreenUtil().setHeight(40),
              ),
              title: Text(
                "VAnalytics",
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false),
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.insert_chart,
                size: ScreenUtil().setHeight(40),
              ),
              title: Text(
                "VData",
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false),
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.assignment,
                size: ScreenUtil().setHeight(40),
              ),
              title: Text(
                "My Works",
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false),
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: (totalNotification != "0")
                  ? Badge(
                      position: BadgePosition.topRight(top: -8, right: -5),
                      animationDuration: Duration(milliseconds: 300),
                      animationType: BadgeAnimationType.slide,
                      badgeContent: Text(
                        '$totalNotification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ScreenUtil()
                              .setSp(20, allowFontScalingSelf: false),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      child: Icon(
                        Icons.notifications,
                        size: ScreenUtil().setHeight(40),
                      ),
                    )
                  : Icon(
                      Icons.notifications,
                      size: ScreenUtil().setHeight(40),
                    ),
              title: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false),
                ),
              ),
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.menu,
                size: ScreenUtil().setHeight(40),
              ),
              title: Text(
                "More",
                style: TextStyle(
                  fontSize: ScreenUtil().setSp(24, allowFontScalingSelf: false),
                ),
              ),
            )
          ],
        ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            ScreenUtil().setHeight(85),
          ),
          child: AppBar(
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            elevation: 1,
            centerTitle: true,
            title: Text(
              "More",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.fromLTRB(
                    ScreenUtil().setWidth(20), ScreenUtil().setWidth(20), 0, 0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        width: ScreenUtil().setHeight(2),
                        color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            Container(
                              width: ScreenUtil().setWidth(200),
                              height: ScreenUtil().setHeight(200),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(100, 220, 220, 220),
                                shape: BoxShape.rectangle,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                              ),
                            ),
                            (connection == true)
                                ? Positioned(
                                    top: ScreenUtil().setHeight(20),
                                    left: ScreenUtil().setWidth(20),
                                    child: Container(
                                      padding: EdgeInsets.all(160.0),
                                      width: ScreenUtil().setWidth(160),
                                      height: ScreenUtil().setHeight(160),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10.0)),
                                        image: DecorationImage(
                                          fit: BoxFit.fill,
                                          image:
                                              CachedNetworkImageProvider(image),
                                        ),
                                      ),
                                    ),
                                  )
                                : Positioned(
                                    top: ScreenUtil().setHeight(20),
                                    left: ScreenUtil().setWidth(20),
                                    child: Container(
                                      width: ScreenUtil().setWidth(160),
                                      height: ScreenUtil().setHeight(160),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10.0)),
                                      ),
                                      child: Image.file(
                                        File((location == null)
                                            ? "/data/user/0/com.my.jtapps.vvin/app_flutter/company/profile.jpg"
                                            : location +
                                                "/company/profile.jpg"),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(
                              ScreenUtil().setHeight(220),
                              ScreenUtil().setHeight(50),
                              0,
                              0),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Flexible(
                                    child: (connection == true)
                                        ? (nameLocal != null)
                                            ? Text(
                                                nameLocal,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: font14,
                                                ),
                                              )
                                            : (name == null)
                                                ? Text("")
                                                : Text(
                                                    "$name",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: font14,
                                                    ),
                                                  )
                                        : (nameLocal != null)
                                            ? Text(
                                                nameLocal,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: font14,
                                                ),
                                              )
                                            : Text(""),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(20),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          AwesomePageRoute(
                                            transitionDuration:
                                                Duration(milliseconds: 600),
                                            exitPage: widget,
                                            enterPage: Profile(),
                                            transition: CubeTransition(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "View Profile",
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: font14),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: ScreenUtil().setWidth(20),
                    )
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    AwesomePageRoute(
                      transitionDuration: Duration(milliseconds: 600),
                      exitPage: widget,
                      enterPage: ReminderList(),
                      transition: ParallaxTransition(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(30)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: ScreenUtil().setWidth(40),
                            child: Icon(
                              Icons.notifications_active,
                              color: Colors.grey,
                              size: ScreenUtil().setWidth(40),
                            ),
                          ),
                          SizedBox(
                            width: ScreenUtil().setWidth(20),
                          ),
                          Expanded(
                            child: Text(
                              "Reminders",
                              style: TextStyle(
                                  fontSize: font14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: ScreenUtil().setWidth(60),
                          ),
                          Flexible(
                            child: Text(
                              "View all your reminders here",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: font14,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setting();
                },
                child: Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(30)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: ScreenUtil().setWidth(40),
                            child: Icon(
                              Icons.settings,
                              color: Colors.grey,
                              size: ScreenUtil().setWidth(40),
                            ),
                          ),
                          SizedBox(
                            width: ScreenUtil().setWidth(20),
                          ),
                          Expanded(
                            child: Text(
                              "Settings",
                              style: TextStyle(
                                  fontSize: font14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: ScreenUtil().setWidth(60),
                          ),
                          Flexible(
                            child: Text(
                              "View all settings for notifications here",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: font14,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _vbusiness,
                child: Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(30)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: ScreenUtil().setWidth(40),
                            child: Icon(
                              FontAwesomeIcons.graduationCap,
                              color: Colors.grey,
                              size: ScreenUtil().setWidth(35),
                            ),
                          ),
                          SizedBox(
                            width: ScreenUtil().setWidth(20),
                          ),
                          Expanded(
                            child: Text(
                              "VBusiness Academy",
                              style: TextStyle(
                                  fontSize: font14,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(
                            width: ScreenUtil().setWidth(60),
                          ),
                          Flexible(
                            child: Text(
                              "Learn more on how you can improve your business",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: font14,
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _logout,
                child: Container(
                  padding: EdgeInsets.all(ScreenUtil().setWidth(30)),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: ScreenUtil().setWidth(40),
                        child: Icon(
                          FontAwesomeIcons.signOutAlt,
                          color: Colors.grey,
                          size: ScreenUtil().setWidth(35),
                        ),
                      ),
                      SizedBox(
                        width: ScreenUtil().setWidth(20),
                      ),
                      Expanded(
                        child: Text(
                          "Log Out",
                          style: TextStyle(
                              fontSize: font14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void setting() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (connection == true) {
        Setting setting = Setting(
            companyID: companyID,
            userID: userID,
            level: level,
            userType: userType,
            assign: assign,
            unassign: unassign);
        Navigator.push(
          context,
          AwesomePageRoute(
            transitionDuration: Duration(milliseconds: 600),
            exitPage: widget,
            enterPage: Settings(setting: setting),
            transition: AccordionTransition(),
          ),
        );
      } else {
        _toast("Data is loading. Please try again.");
      }
    } else {
      _toast("No Internet Connection");
    }
  }

  void _vbusiness() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      FlutterWebBrowser.openWebPage(
        url: "http://cyps.wgxscn.com/mlxy/index/index",
      );
    } else {
      _toast("No Internet Connection");
    }
  }

  void checkConnection() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString("noti") != null) {
      if (this.mounted) {
        setState(() {
          totalNotification = prefs.getString("noti");
        });
      }
      FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      loadData();
      notification();
    } else {
      if (this.mounted) {
        setState(() {
          start = true;
        });
      }
      _toast("No Internet, the data shown is not up to date");
    }
  }

  void notification() {
    http.post(urlNoti, body: {
      "userID": userID,
      "companyID": companyID,
      "level": level,
      "user_type": userType,
    }).then((res) async {
      if (this.mounted) {
        setState(() {
          totalNotification = res.body;
        });
      }
      FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
    }).catchError((err) {
      print("Notification error: " + err.toString());
    });
  }

  Future<void> loadData() async {
    companyID = prefs.getString('companyID');
    userID = prefs.getString('userID');
    level = prefs.getString('level');
    userType = prefs.getString('user_type');
    http.post(companyURL, body: {
      "companyID": companyID,
      "userID": userID,
      "level": level,
      "user_type": userType
    }).then((res) async {
      // print("Company details:" + res.body);
      try {
        final dir = Directory(location + "/company/profile.jpg");
        dir.deleteSync(recursive: true);
      } catch (err) {}
      var jsonData = json.decode(res.body);
      for (var data in jsonData) {
        name = data["name"];
        phone = data["phone"];
        email = data["email"];
        website = data["website"];
        address = data["address"];
        image = data["image"];
        unassign = data["unassign"].toString();
        assign = data["assign"].toString();
      }
      if (this.mounted) {
        setState(() {
          start = true;
          connection = true;
        });
      }
      setData();
      final _devicePath = await getApplicationDocumentsDirectory();
      location = _devicePath.path.toString();
      try {
        final dir = Directory(location + "/company/profile.jpg");
        dir.deleteSync(recursive: true);
      } catch (err) {}
      _downloadImage(image, "company", "profile");
    }).catchError((err) {
      print("Load data error: " + (err).toString());
    });
  }

  Future<void> setData() async {
    Database db = await CompanyDB.instance.database;
    await db.rawInsert('DELETE FROM details WHERE id > 0');
    await db.rawInsert(
        'INSERT INTO details (name, phone, email, website, address) VALUES("' +
            name +
            '","' +
            phone +
            '","' +
            email +
            '","' +
            website +
            '","' +
            address +
            '")');
  }

  Future<void> initialize() async {
    final _devicePath = await getApplicationDocumentsDirectory();
    if (this.mounted) {
      setState(() {
        location = _devicePath.path.toString();
      });
    }
    try {
      Database db = await CompanyDB.instance.database;
      List<Map> result = await db.query(CompanyDB.table);
      if (this.mounted) {
        setState(() {
          nameLocal = result[0]['name'];
        });
      }
    } catch (e) {}
  }

  Future<void> _logout() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      Database db1 = await ReminderDB.instance.database;
      List reminders = await db1.query(ReminderDB.table);
      String sendtime = DateTime.now().millisecondsSinceEpoch.toString();
      for (int i = 0; i < reminders.length; i++) {
        http.post(urlReminder, body: {
          "companyID": companyID,
          "userID": userID,
          "level": level,
          "user_type": userType,
          "id": reminders[i]['dataid'].toString(),
          "datetime": reminders[i]['datetime'].toString(),
          "name": reminders[i]['name'],
          "phone": reminders[i]['phone'].toString(),
          "remark": reminders[i]['remark'],
          "status": reminders[i]['status'],
          "time": reminders[i]['time'].toString(),
          "sendtime": sendtime,
        }).then((res) async {
        }).catchError((err) {
          _toast("Something wrong on save reminder");
          print("Reminder error: " + (err).toString());
        });
      }
      db1.rawInsert('DELETE FROM reminder WHERE id > 0');
      await flutterLocalNotificationsPlugin.cancelAll();
      final _devicePath = await getApplicationDocumentsDirectory();
      location = _devicePath.path.toString();
      try {
        final dir = Directory(location + "/company/profile.jpg");
        dir.deleteSync(recursive: true);
      } catch (err) {}

      Database db = await MyWorksDB.instance.database;
      List<Map> offlineLink = await db.query(MyWorksDB.table);
      for (int i = 0; i < offlineLink.length; i++) {
        try {
          final dir = Directory(location +
              "/" +
              offlineLink[i]['type'] +
              offlineLink[i]['linkid'] +
              "/VVIN.html");
          dir.deleteSync(recursive: true);
        } catch (err) {}
        try {
          final dir = Directory(location +
              "/" +
              offlineLink[i]['type'] +
              offlineLink[i]['linkid'] +
              "/VVIN.jpg");
          dir.deleteSync(recursive: true);
        } catch (err) {}
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('companyID', null);
      prefs.setString('userID', null);
      prefs.setString('level', null);
      prefs.setString('user_type', null);
      prefs.setString('totalQR', null);
      prefs.setString('totalLink', null);
      prefs.setString('noti', null);
      prefs.setString('newNoti', null);
      prefs.setString("getreminder", null);

      _clearToken();

      Database companyDB = await CompanyDB.instance.database;
      companyDB.rawInsert('DELETE FROM details WHERE id > 0');
      Database leadsDB = await LeadsDB.instance.database;
      leadsDB.rawInsert('DELETE FROM leads WHERE id > 0');
      Database mainscreenNotiDB = await MainScreenNotiDB.instance.database;
      mainscreenNotiDB.rawInsert('DELETE FROM mainnoti WHERE id > 0');
      Database myWorksDB = await MyWorksDB.instance.database;
      myWorksDB.rawInsert('DELETE FROM myworks WHERE id > 0');
      Database notiDB = await NotiDB.instance.database;
      notiDB.rawInsert('DELETE FROM noti WHERE id > 0');
      Database topViewDB = await TopViewDB.instance.database;
      topViewDB.rawInsert('DELETE FROM topview WHERE id > 0');
      Database vanalyticsDB = await VAnalyticsDB.instance.database;
      vanalyticsDB.rawInsert('DELETE FROM analytics WHERE id > 0');
      Database vdataDB = await VDataDB.instance.database;
      vdataDB.rawInsert('DELETE FROM vdata WHERE id > 0');
      Navigator.pushReplacement(
        context,
        AwesomePageRoute(
          transitionDuration: Duration(milliseconds: 600),
          exitPage: widget,
          enterPage: Login(),
          transition: ParallaxTransition(),
        ),
      );
    } else {
      _toast("Please connect to Internet");
    }
  }

  void _clearToken() {
    http.post(urlLogout, body: {
      "companyID": companyID,
      "userID": userID,
      "level": level,
      "user_type": userType,
    }).then((res) async {
      if (res.body == "success") {
      } else {
        _toast("Something wrong, please contact VVIN sales support");
      }
    }).catchError((err) {
      _toast("Something wrong, please contact VVIN help desk");
      print("Logout error: " + (err).toString());
    });
  }

  Future<String> get _localDevicePath async {
    final _devicePath = await getApplicationDocumentsDirectory();
    return _devicePath.path;
  }

  Future _downloadImage(String url, String path, String name) async {
    final _response = await http.get(url);
    if (_response.statusCode == 200) {
      final _file = await _localImage(path: path, name: name);
      await _file.writeAsBytes(_response.bodyBytes);
    }
  }

  Future<File> _localImage({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.jpg");
  }

  Future<bool> _onBackPressAppBar() async {
    YYAlertDialogWithScaleIn();
    return Future.value(false);
  }

  void _toast(String message) {
    BotToast.showText(
      text: message,
      wrapToastAnimation: (controller, cancel, Widget child) =>
          CustomAnimationWidget(
        controller: controller,
        child: child,
      ),
    );
  }
}
