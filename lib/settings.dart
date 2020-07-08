import 'dart:async';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/data.dart';
import 'package:vvin/reminder.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';

class Settings extends StatefulWidget {
  final Setting setting;
  const Settings({Key key, this.setting}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

enum UniLinksType { string, uri }

class _SettingsState extends State<Settings> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  SharedPreferences prefs;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  final ScrollController controller = ScrollController();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  String urlNotiChangeStatus =
      "https://vvinoa.vvin.com/api/notificationAction.php";
  String assign, unassign, now, companyID, branchID, userID, userType;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    assign = widget.setting.assign;
    unassign = widget.setting.unassign;
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
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            ScreenUtil().setHeight(85),
          ),
          child: AppBar(
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            leading: IconButton(
              onPressed: _onBackPressAppBar,
              icon: Icon(
                Icons.arrow_back_ios,
                size: ScreenUtil().setWidth(30),
                color: Colors.grey,
              ),
            ),
            elevation: 1,
            centerTitle: true,
            title: Text(
              "Settings",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: controller,
          child: Container(
            padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Notifications",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: font12,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: ScreenUtil().setHeight(20),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "New Unassign Leads",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: font14),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenUtil().setHeight(10)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                    "Notifies you when a there is a new unassign lead in the system",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      alignment: Alignment.centerRight,
                      scale: ScreenUtil().setWidth(1.5),
                      child: CupertinoSwitch(
                        activeColor: Colors.blue,
                        value: checkStatus(unassign),
                        onChanged: (bool value) {
                          _changeStatus(value, "unassign");
                        },
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: ScreenUtil().setHeight(20),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Leads assigned to you",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: font14),
                              ),
                            ],
                          ),
                          SizedBox(height: ScreenUtil().setHeight(10)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                    "Notifies you when a lead is assigned to you",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      alignment: Alignment.centerRight,
                      scale: ScreenUtil().setWidth(1.5),
                      child: CupertinoSwitch(
                        activeColor: Colors.blue,
                        value: checkStatus(assign),
                        onChanged: (bool value) {
                          _changeStatus(value, "assign");
                        },
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeStatus(bool value, String type) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      String status;
      if (value == false) {
        status = "0";
      } else {
        status = "1";
      }
      if (type == "unassign") {
        http.post(urlNotiChangeStatus, body: {
          "userID": widget.setting.userID,
          "companyID": widget.setting.companyID,
          "branchID": widget.setting.branchID,
          "level": widget.setting.level,
          "user_type": widget.setting.userType,
          "actionType": "updateSetting",
          "unassign": status,
          "assign": assign,
        }).then((res) {
          if (res.body == "1") {
            if (this.mounted) {
              setState(() {
                unassign = status;
              });
            }
            _toast("Status changed");
          } else {
            _toast(
                "Status can't changed, please check you Internet connection");
          }
        }).catchError((err) {
          print("Change unassign error: " + (err).toString());
        });
      } else {
        http.post(urlNotiChangeStatus, body: {
          "userID": widget.setting.userID,
          "companyID": widget.setting.companyID,
          "branchID": widget.setting.branchID,
          "level": widget.setting.level,
          "user_type": widget.setting.userType,
          "actionType": "updateSetting",
          "unassign": unassign,
          "assign": status,
        }).then((res) {
          if (res.body == "1") {
            if (this.mounted) {
              setState(() {
                assign = status;
              });
            }
            _toast("Status changed");
          } else {
            _toast(
                "Status can't changed, please check you Internet connection");
          }
        }).catchError((err) {
          _toast(err.toString());
          print("Change assign error: " + err.toString());
        });
      }
    }
  }

  bool checkStatus(String checking) {
    bool status;
    if (checking == "1") {
      status = true;
    } else {
      status = false;
    }
    return status;
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  void _toast(String message) {
    showToast(
      message,
      context: context,
      animation: StyledToastAnimation.slideFromBottomFade,
      reverseAnimation: StyledToastAnimation.slideToBottom,
      position: StyledToastPosition.bottom,
      duration: Duration(milliseconds: 3500),
    );
  }
}
