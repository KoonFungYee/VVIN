import 'dart:async';
import 'dart:typed_data';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slide_countdown_clock/slide_countdown_clock.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/data.dart';
import 'package:vvin/editReminder.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';

class Reminder extends StatefulWidget {
  final int dataid;
  final String date;
  final String time;
  final String name;
  final String phone;
  final String remark;
  final String status;
  final int datetime;
  Reminder(
      {Key key,
      this.dataid,
      this.date,
      this.time,
      this.name,
      this.phone,
      this.remark,
      this.status,
      this.datetime})
      : super(key: key);

  @override
  _ReminderState createState() => _ReminderState();
}

enum UniLinksType { string, uri }

class _ReminderState extends State<Reminder> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  double font20 = ScreenUtil().setSp(46.0, allowFontScalingSelf: false);
  Duration _duration;
  Database db;
  String cancel, active, now, companyID, userID, branchID, userType, level;
  int reminderTime;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    cancel = 'cancel';
    active = 'active';
    if (widget.datetime > DateTime.now().millisecondsSinceEpoch) {
      int seconds =
          ((widget.datetime - DateTime.now().millisecondsSinceEpoch) / 1000)
              .floor();
      _duration = Duration(seconds: seconds);
    } else {
      _duration = Duration(seconds: 0);
    }
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
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

  Future<void> _init() async {
    db = await ReminderDB.instance.database;
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
          String time = list[1].toString().substring(11);
          String name = list[2];
          String phone = list[3];
          String remark = list[4];
          String status = list[5];
          int datetime = int.parse(list[6]);
          Database db = await ReminderDB.instance.database;
          await db.rawInsert(
              'UPDATE reminder SET status = "cancel" WHERE dataid = ' +
                  dataid.toString());
          Navigator.of(context).pushReplacement(PageTransition(
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
      } else if (payload.substring(0, 8) == 'calendar') {
        if (prefs.getString('calendar') != payload) {
          companyID = prefs.getString('companyID');
          branchID = prefs.getString('branchID');
          userID = prefs.getString('userID');
          level = prefs.getString('level');
          userType = prefs.getString('user_type');
          UserData userdata = UserData(
            companyID: companyID,
            userID: userID,
            branchID: branchID,
            userType: userType,
            level: level,
          );
          List<UserData> userData = [];
          userData.add(userdata);
          List list = payload.substring(8).split('~!');
          List data = [];
          String handler = list[5];
          data.add(handler);
          data.add(userData[0].userID);
          String title = list[1];
          data.add(title);
          String description = list[2];
          data.add(description);
          String date = list[3];
          data.add(date);
          String startTime = (list[4] == 'Full Day') ? 'allDay' : list[4].toString().split(' - ')[0];
          data.add(startTime);
          String endTime = (list[4] == 'Full Day') ? 'allDay' : list[4].toString().split(' - ')[1];
          data.add(endTime);
          String person = list[6];
          data.add(person);
          String location = list[7];
          data.add(location);
          String notificationTime = list[8];
          data.add(notificationTime);
          String createdTime = list[0].toString().substring(0, 19);
          data.add(createdTime);
          Navigator.of(context).push(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: CalendarEvent(
              data: data,
              userData: userData,
            ),
          ));
          prefs.setString('calendar', payload);
        }
      } else {
        if (prefs.getString('onMessage') != payload) {
          Navigator.of(context).pushReplacement(PageTransition(
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

  void check() async {
    if (_type == UniLinksType.string) {
      _sub = getLinksStream().listen((String link) {
        // FlutterWebBrowser.openWebPage(
        //   url: "https://" + link.substring(12),
        // );
      }, onError: (err) {});
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
              "Reminder Detail",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[popupMenuButton()],
          ),
        ),
        body: Container(
          margin: EdgeInsets.fromLTRB(ScreenUtil().setWidth(30),
              ScreenUtil().setWidth(100), ScreenUtil().setWidth(30), 0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Reminder on',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: font16,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SlideCountdownClock(
                    duration: _duration,
                    slideDirection: SlideDirection.Down,
                    separator: ":",
                    textStyle: TextStyle(
                      fontSize: font20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: ScreenUtil().setWidth(100),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Status: ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: font14,
                      ),
                    ),
                    Text(
                      (widget.datetime >
                                  DateTime.now().millisecondsSinceEpoch &&
                              widget.status == 'active')
                          ? 'Active'
                          : "Not active",
                      style: TextStyle(
                        color: (widget.datetime >
                                    DateTime.now().millisecondsSinceEpoch &&
                                widget.status == 'active')
                            ? Colors.green
                            : Colors.red,
                        fontSize: font14,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: ScreenUtil().setWidth(20),
              ),
              Container(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Date : ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: font14,
                      ),
                    ),
                    Text(
                      widget.date,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: font14,
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: ScreenUtil().setWidth(20),
              ),
              Row(
                children: <Widget>[
                  Text(
                    'Time: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: font14,
                    ),
                  ),
                  Text(
                    widget.time,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: font14,
                    ),
                  )
                ],
              ),
              SizedBox(
                height: ScreenUtil().setWidth(20),
              ),
              Row(
                children: <Widget>[
                  Text(
                    'Name: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: font14,
                    ),
                  ),
                  Text(
                    widget.name,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: font14,
                    ),
                  )
                ],
              ),
              SizedBox(
                height: ScreenUtil().setWidth(20),
              ),
              Row(
                children: <Widget>[
                  Text(
                    'Phone Number: ',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: font14,
                    ),
                  ),
                  Text(
                    widget.phone,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: font14,
                    ),
                  )
                ],
              ),
              SizedBox(
                height: ScreenUtil().setWidth(20),
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Remark: ',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: font16,
                            ),
                          ),
                          TextSpan(
                            text: widget.remark,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: font16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget popupMenuButton() {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        size: ScreenUtil().setWidth(40),
        color: Colors.grey,
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        (widget.datetime > DateTime.now().millisecondsSinceEpoch &&
                widget.status == 'active')
            ? PopupMenuItem<String>(
                value: "edit",
                child: Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              )
            : null,
        (widget.datetime > DateTime.now().millisecondsSinceEpoch &&
                widget.status == 'active')
            ? PopupMenuItem<String>(
                value: "cancel",
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              )
            : null,
        (widget.datetime > DateTime.now().millisecondsSinceEpoch &&
                widget.status != 'active')
            ? PopupMenuItem<String>(
                value: "reactive",
                child: Text(
                  "Re-active",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              )
            : null,
        (widget.datetime < DateTime.now().millisecondsSinceEpoch)
            ? PopupMenuItem<String>(
                value: "delete",
                child: Text(
                  "Delete",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              )
            : null,
      ],
      onSelected: (selectedItem) {
        switch (selectedItem) {
          case "cancel":
            {
              _cancel();
            }
            break;
          case "edit":
            {
              _edit();
            }
            break;
          case "delete":
            {
              _delete();
            }
            break;
          case "reactive":
            {
              _reactive();
            }
            break;
        }
      },
    );
  }

  Future<void> _reactive() async {
    await db.rawInsert('UPDATE reminder SET status = "' +
        active +
        '" WHERE dataid = ' +
        widget.dataid.toString());
    String details = widget.dataid.toString() +
        "~!" +
        widget.date +
        " " +
        widget.time +
        "~!" +
        widget.name +
        "~!" +
        widget.phone +
        "~!" +
        widget.remark +
        "~!" +
        'not active' +
        "~!" +
        widget.datetime.toString();
    _scheduleNotification(widget.dataid, details);
    _toast('Re-activited');
    _onBackPressAppBar();
  }

  Future<void> _scheduleNotification(int id, String details) async {
    String name = 'Name: ' + widget.name + ' ';
    String phoneNo = 'Phone Number: ' + widget.phone + ' ';
    String decription = 'Remark: ' + widget.remark + ' ';
    var scheduledNotificationDateTime =
        DateTime.fromMillisecondsSinceEpoch(widget.datetime);
    var vibrationPattern = Int64List(1);
    vibrationPattern[0] = 0;

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your other channel id',
      'your other channel name',
      'your other channel description',
      icon: 'secondary_icon',
      largeIcon: DrawableResourceAndroidBitmap(''),
      vibrationPattern: vibrationPattern,
      enableLights: true,
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(''),
    );
    var iOSPlatformChannelSpecifics =
        IOSNotificationDetails(sound: 'slow_spring_board.aiff');
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.schedule(
        id,
        'Reminder',
        name + '\n' + phoneNo + '\n' + decription,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        payload: 'reminder' + details);
  }

  Future<void> _delete() async {
    await db.rawInsert(
        'DELETE FROM reminder WHERE dataid = ' + widget.dataid.toString());
    await flutterLocalNotificationsPlugin.cancel(widget.dataid);
    _toast('Deleted');
    _onBackPressAppBar();
  }

  void _edit() {
    Navigator.push(
      context,
      AwesomePageRoute(
        transitionDuration: Duration(milliseconds: 600),
        exitPage: widget,
        enterPage: EditReminder(
          datetime: widget.date + ' ' + widget.time,
          name: widget.name,
          phoneNo: widget.phone,
          remark: widget.remark,
          dataid: widget.dataid,
          time: widget.datetime,
        ),
        transition: DefaultTransition(),
      ),
    );
  }

  Future<void> _cancel() async {
    await db.rawInsert('UPDATE reminder SET status = "' +
        cancel +
        '" WHERE dataid = ' +
        widget.dataid.toString());
    await flutterLocalNotificationsPlugin.cancel(widget.dataid);
    _toast('Reminder cancelled');
    _onBackPressAppBar();
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

  Future<bool> _onBackPressAppBar() {
    Navigator.pop(context);
    return Future.value(false);
  }
}
