import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'dart:async';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';

class ReminderList extends StatefulWidget {
  ReminderList({Key key}) : super(key: key);

  @override
  _ReminderListState createState() => _ReminderListState();
}

enum UniLinksType { string, uri }

class _ReminderListState extends State<ReminderList> {
  final ScrollController controller = ScrollController();
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
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  SharedPreferences prefs;
  bool status = false;
  List reminderList = [];
  String now;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    initial();
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
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(235, 235, 255, 1),
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
              "Reminder List",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          header: MaterialClassicHeader(),
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: (status == false)
              ? Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        JumpingText('Loading...'),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02),
                        SpinKitRing(
                          lineWidth: 3,
                          color: Colors.blue,
                          size: 30.0,
                          duration: Duration(milliseconds: 600),
                        ),
                      ],
                    ),
                  ),
                )
              : (reminderList.length == 0)
                  ? Center(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: EmptyListWidget(
                            packageImage: PackageImage.Image_2,
                            // title: 'No Data',
                            subTitle: 'No Reminder',
                            titleTextStyle: Theme.of(context)
                                .typography
                                .dense
                                .display1
                                .copyWith(color: Color(0xff9da9c7)),
                            subtitleTextStyle: Theme.of(context)
                                .typography
                                .dense
                                .body2
                                .copyWith(color: Color(0xffabb8d6))),
                      ),
                    )
                  : ListView.builder(
                      itemCount: reminderList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return WidgetANimator(
                          InkWell(
                            onTap: () {
                              _reminderPage(index);
                            },
                            child: Container(
                              padding: EdgeInsets.fromLTRB(
                                ScreenUtil().setHeight(25),
                                ScreenUtil().setHeight(20),
                                ScreenUtil().setHeight(25),
                                ScreenUtil().setHeight(20),
                              ),
                              decoration: BoxDecoration(
                                color: (reminderList[index]['status'] ==
                                            'active' &&
                                        int.parse(reminderList[index]['time']) >
                                            DateTime.now()
                                                .millisecondsSinceEpoch)
                                    ? Color.fromRGBO(232, 244, 248, 1)
                                    : Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                      width: 1, color: Colors.grey.shade300),
                                ),
                              ),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Reminder: ' +
                                            reminderList[index]['datetime'],
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: font14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: ScreenUtil().setWidth(15),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Name: ' + reminderList[index]['name'],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: font13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: ScreenUtil().setWidth(5),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Contact Number: ' +
                                            reminderList[index]['phone'],
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: font13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: ScreenUtil().setWidth(5),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Flexible(
                                        child: Text(
                                          'Remark: ' +
                                              reminderList[index]['remark'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: font13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: ScreenUtil().setWidth(5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
        ),
      ),
    );
  }

  Future<void> _reminderPage(int index) async {
    Database db = await ReminderDB.instance.database;
    List reminderList1 = await db.rawQuery(
        "SELECT * FROM reminder where dataid = " +
            reminderList[index]['dataid']);
    if (reminderList1.length > 0) {
      Navigator.push(
        context,
        AwesomePageRoute(
          transitionDuration: Duration(milliseconds: 600),
          exitPage: widget,
          enterPage: Reminder(
            dataid: int.parse(reminderList[index]['dataid']),
            date: reminderList[index]['datetime'].toString().substring(0, 10),
            time: reminderList[index]['datetime'].toString().substring(12),
            name: reminderList[index]['name'],
            phone: reminderList[index]['phone'],
            remark: reminderList[index]['remark'],
            status: reminderList[index]['status'],
            datetime: int.parse(reminderList[index]['time']),
          ),
          transition: DepthTransition(),
        ),
      );
    } else {
      _toast('This reminder has been deleted, please refresh list');
    }
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

  Future<void> _onRefresh() async {
    if (this.mounted) {
      setState(() {
        status = false;
      });
    }
    Database db = await ReminderDB.instance.database;
    reminderList =
        await db.rawQuery("SELECT * FROM reminder order by time desc");
    if (this.mounted) {
      setState(() {
        status = true;
      });
    }
    _refreshController.refreshCompleted();
  }

  Future<void> initial() async {
    Database db = await ReminderDB.instance.database;
    reminderList =
        await db.rawQuery("SELECT * FROM reminder order by time desc");
    if (this.mounted) {
      setState(() {
        status = true;
      });
    }
  }

  Future<bool> _onBackPressAppBar() {
    Navigator.pop(context);
    return Future.value(false);
  }
}
