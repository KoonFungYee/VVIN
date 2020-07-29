import 'dart:async';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/calendar.dart';
import 'package:vvin/calendarNew.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';

class CalendarEvent extends StatefulWidget {
  final bool edit;
  final List data;
  final List<UserData> userData;
  CalendarEvent({Key key, this.edit, this.data, this.userData})
      : super(key: key);

  @override
  _CalendarEventState createState() => _CalendarEventState();
}

enum UniLinksType { string, uri }

class _CalendarEventState extends State<CalendarEvent> {
  StreamSubscription _sub;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  final ScrollController controller = ScrollController();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  UniLinksType _type = UniLinksType.string;
  String urlDelete = ip + "deleteCalendar.php";
  String now;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    print(widget.edit);
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
      } else if (payload.substring(0, 8) == 'calendar') {
        if (prefs.getString('calendar') != payload) {
          List list = payload.substring(8).split('~!');
          List data = [];
          String handler = list[5];
          data.add(handler);
          data.add(widget.userData[0].userID);
          String title = list[1];
          data.add(title);
          String description = list[2];
          data.add(description);
          String date = list[3];
          data.add(date);
          String startTime = (list[4] == 'Full Day')
              ? 'allDay'
              : list[4].toString().split(' - ')[0];
          data.add(startTime);
          String endTime = (list[4] == 'Full Day')
              ? 'allDay'
              : list[4].toString().split(' - ')[1];
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
              userData: widget.userData,
            ),
          ));
          prefs.setString('calendar', payload);
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
              "Event Details",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
            actions: (widget.data[1] == widget.userData[0].userID) ? <Widget>[popupMenuButton()] : null,
          ),
        ),
        body: SingleChildScrollView(
          controller: controller,
          child: Container(
            padding: EdgeInsets.all(ScreenUtil().setHeight(10)),
            child: Column(
              children: <Widget>[
                Container(
                  margin: EdgeInsets.fromLTRB(0, ScreenUtil().setHeight(10), 0,
                      ScreenUtil().setHeight(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Created on ' + widget.data[10],
                        style: TextStyle(
                            color: Color.fromRGBO(135, 152, 173, 1),
                            fontSize: font12),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: ScreenUtil().setHeight(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          widget.data[2],
                          style: TextStyle(
                              color: Color.fromRGBO(46, 56, 77, 1),
                              fontSize: font18,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: ScreenUtil().setHeight(40)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          (widget.data[3] == '') ? ' -' : widget.data[3],
                          style: TextStyle(
                            color: Color.fromRGBO(105, 112, 127, 1),
                            fontSize: font14,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          color: Color.fromRGBO(105, 112, 127, 1),
                          fontSize: font14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              widget.data[4],
                              style: TextStyle(
                                color: Color.fromRGBO(90, 90, 90, 1),
                                fontSize: font14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Time',
                        style: TextStyle(
                          color: Color.fromRGBO(105, 112, 127, 1),
                          fontSize: font14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              (widget.data[5] == 'allDay')
                                  ? 'Full day'
                                  : widget.data[5] + ' - ' + widget.data[6],
                              style: TextStyle(
                                color: Color.fromRGBO(90, 90, 90, 1),
                                fontSize: font14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Handler',
                        style: TextStyle(
                          color: Color.fromRGBO(105, 112, 127, 1),
                          fontSize: font14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              widget.data[0],
                              style: TextStyle(
                                color: Color.fromRGBO(90, 90, 90, 1),
                                fontSize: font14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Meeting with',
                        style: TextStyle(
                          color: Color.fromRGBO(105, 112, 127, 1),
                          fontSize: font14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              (widget.data[7] == '') ? ' -' : widget.data[7],
                              style: TextStyle(
                                color: Color.fromRGBO(90, 90, 90, 1),
                                fontSize: font14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Location',
                        style: TextStyle(
                          color: Color.fromRGBO(105, 112, 127, 1),
                          fontSize: font14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              (widget.data[8] == '') ? ' -' : widget.data[8],
                              style: TextStyle(
                                color: Color.fromRGBO(90, 90, 90, 1),
                                fontSize: font14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Notification',
                        style: TextStyle(
                          color: Color.fromRGBO(105, 112, 127, 1),
                          fontSize: font14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              widget.data[9],
                              style: TextStyle(
                                color: Color.fromRGBO(90, 90, 90, 1),
                                fontSize: font14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        (widget.edit == true)
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
        PopupMenuItem<String>(
          value: "delete",
          child: Text(
            "Delete",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
      ],
      onSelected: (selectedItem) {
        switch (selectedItem) {
          case "edit":
            Navigator.push(
              context,
              AwesomePageRoute(
                transitionDuration: Duration(milliseconds: 600),
                exitPage: widget,
                enterPage: CalendarNewEvent(
                    data: widget.data, isNew: false, userData: widget.userData),
                transition: ZoomOutSlideTransition(),
              ),
            );
            break;
          default:
            _delete(widget.data[11]);
        }
      },
    );
  }

  void _delete(String id) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      _onLoading();
      http.post(urlDelete, body: {
        "companyID": widget.userData[0].companyID,
        "branchID": widget.userData[0].branchID,
        "userID": widget.userData[0].userID,
        "user_type": widget.userData[0].userType,
        "level": widget.userData[0].level,
        "id": id,
      }).then((res) {
        if (res.body == "success") {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.push(
            context,
            AwesomePageRoute(
              transitionDuration: Duration(milliseconds: 600),
              exitPage: widget,
              enterPage: Calendar(userData: widget.userData),
              transition: ZoomOutSlideTransition(),
            ),
          );
        }
      }).catchError((err) {
        _toast(err.toString());
        print("Delete calendar error: " + err.toString());
      });
    } else {
      _toast('No Internet Connection');
    }
  }

  void _onLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () {},
        child: Dialog(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.1,
            width: MediaQuery.of(context).size.width * 0.1,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('Deleting...'),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  SpinKitRing(
                    lineWidth: 3,
                    color: Colors.blue,
                    size: 30.0,
                    duration: Duration(milliseconds: 600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  Future<bool> _onBackPressAppBar() async {
    Navigator.of(context).pop();
    return Future.value(false);
  }
}
