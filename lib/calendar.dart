import 'dart:async';
import 'dart:convert';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uni_links/uni_links.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/animator.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/calendarNew.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';

final Map<DateTime, List> _holidays = {
  DateTime(2019, 1, 1): ['New Year\'s Day'],
  DateTime(2019, 1, 25): ['	Chinese New Year'],
  DateTime(2019, 1, 26): ['	Chinese New Year'],
  DateTime(2019, 1, 27): ['	Chinese New Year'],
  DateTime(2019, 5, 1): ['Labour Day'],
  DateTime(2019, 5, 7): ['Wesak Day'],
  DateTime(2020, 5, 24): ['Hari Raya Aidilfitri'],
  DateTime(2020, 5, 25): ['Hari Raya Aidilfitri'],
  DateTime(2020, 6, 8): ['Yang Dipertuan Agong\'s Birthday'],
  DateTime(2020, 7, 31): ['Hari Raya Haji'],
  DateTime(2020, 8, 20): ['Awal Muharram'],
  DateTime(2020, 8, 31): ['Merdeka Day'],
  DateTime(2020, 9, 16): ['Malaysia Day'],
  DateTime(2020, 10, 29): ['Prophet Muhammad\'s Birthday'],
  DateTime(2020, 11, 14): ['Deepavali'],
  DateTime(2020, 12, 25): ['Christmas Day'],
};

class Calendar extends StatefulWidget {
  final List<UserData> userData;
  Calendar({Key key, this.userData}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

enum UniLinksType { string, uri }

class _CalendarState extends State<Calendar> with TickerProviderStateMixin {
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final ScrollController controller = ScrollController();
  final ScrollController dialogController = ScrollController();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  CalendarController _calendarController;
  Map<DateTime, List> _events;
  String urlHandler = ip + "getHandler.php";
  String urlBranches = ip + "getBranch.php";
  String urlGetDate = ip + "getDate.php";
  String urlEvents = ip + "getEvents.php";
  List<Handler> handlersBranch = [];
  List<Handler> handlersNoBranch = [];
  List<Handler> handlerList = [];
  List<Branch> branchList = [];
  List<DateTime> date = [];
  List title = [];
  List<List> title1 = [];
  List _selectedEvents;
  double _scaleFactor = 1.0;
  String now, dateSelected, executive, executiveID, branch, branchID;
  bool ready = false;
  bool branchReady, handlerReady, dateReady, listReady;

  @override
  void dispose() {
    if (_sub != null) _sub.cancel();
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    initial();
    listReady = dateReady = handlerReady = branchReady = false;
    executiveID = branchID = branch = executive = '';
    dateSelected = DateTime.now().toString().substring(0, 10);
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
    _calendarController = CalendarController();
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

  void _onDaySelected(DateTime day, List events) {
    if (ready == false) {
      setState(() {
        dateSelected = day.toString().substring(0, 10);
      });
    } else {
      setState(() {
        dateSelected = day.toString().substring(0, 10);
        _selectedEvents = events;
      });
    }
  }

  String _dateFormat(String fullDate) {
    String date, month, year;
    date = fullDate.substring(8, 10);
    month = fullDate.substring(5, 7);
    year = fullDate.substring(0, 4);
    switch (month) {
      case '01':
        month = 'Jan';
        break;
      case '02':
        month = 'Feb';
        break;
      case '03':
        month = 'Mar';
        break;
      case '04':
        month = 'Apr';
        break;
      case '05':
        month = 'May';
        break;
      case '06':
        month = 'Jun';
        break;
      case '07':
        month = 'July';
        break;
      case '08':
        month = 'Aug';
        break;
      case '09':
        month = 'Sep';
        break;
      case '10':
        month = 'Oct';
        break;
      case '11':
        month = 'Nov';
        break;
      default:
        month = 'Dec';
    }
    return date + " " + month + " " + year;
  }

  void _filter() {
    if (widget.userData[0].level == '4') {
      for (var handlerEach in handlersBranch) {
        for (var branchEach in handlerEach.branches) {
          if (branchEach['branch_id'] == widget.userData[0].branchID) {
            branchID = branchEach['branch_id'];
          }
        }
      }
    }
    showModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(width: 1, color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.fromLTRB(
                              ScreenUtil().setHeight(20),
                              ScreenUtil().setHeight(10),
                              ScreenUtil().setHeight(10),
                              ScreenUtil().setHeight(10)),
                          child: Text(
                            "Filter",
                            style: TextStyle(
                                fontSize: font14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          child: Row(
                            children: <Widget>[
                              InkWell(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  padding: EdgeInsets.all(
                                    ScreenUtil().setHeight(20),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: font14,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: ScrollPhysics(),
                      child: Container(
                        margin: EdgeInsets.all(ScreenUtil().setHeight(20)),
                        child: Column(
                          children: <Widget>[
                            (widget.userData[0].level == '0')
                                ? Column(
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Text(
                                            'By Branch',
                                            style: TextStyle(
                                              color:
                                                  Color.fromRGBO(20, 23, 32, 1),
                                              fontSize: font14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: ScreenUtil().setHeight(10),
                                      ),
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                _selection(
                                                    setModalState, 'branch');
                                              },
                                              child: Container(
                                                margin: EdgeInsets.fromLTRB(
                                                  0,
                                                  0,
                                                  0,
                                                  ScreenUtil().setHeight(20),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade400,
                                                      style: BorderStyle.solid),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Container(
                                                        height: ScreenUtil()
                                                            .setHeight(60),
                                                        padding:
                                                            EdgeInsets.fromLTRB(
                                                                ScreenUtil()
                                                                    .setHeight(
                                                                        10),
                                                                ScreenUtil()
                                                                    .setHeight(
                                                                        16),
                                                                0,
                                                                0),
                                                        child: Text(
                                                          (branch == '')
                                                              ? 'Please select'
                                                              : branch,
                                                          style: TextStyle(
                                                            fontSize: font14,
                                                            color: (branch ==
                                                                    '')
                                                                ? Color
                                                                    .fromRGBO(
                                                                        192,
                                                                        192,
                                                                        192,
                                                                        1)
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons.arrow_drop_down,
                                                      color: Colors.black,
                                                    ),
                                                    SizedBox(
                                                      width: ScreenUtil()
                                                          .setHeight(10),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width: ScreenUtil().setHeight(20),
                                      ),
                                    ],
                                  )
                                : Container(),
                            Row(
                              children: <Widget>[
                                Text(
                                  'By Executive',
                                  style: TextStyle(
                                    color: Color.fromRGBO(20, 23, 32, 1),
                                    fontSize: font14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: ScreenUtil().setHeight(10),
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _selection(setModalState, 'executive');
                                    },
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(
                                        0,
                                        0,
                                        0,
                                        ScreenUtil().setHeight(20),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: Colors.grey.shade400,
                                            style: BorderStyle.solid),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Expanded(
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              padding: EdgeInsets.fromLTRB(
                                                  ScreenUtil().setHeight(10),
                                                  ScreenUtil().setHeight(16),
                                                  0,
                                                  0),
                                              child: Text(
                                                (executive == '')
                                                    ? 'Please select'
                                                    : executive,
                                                style: TextStyle(
                                                  fontSize: font14,
                                                  color: (executive == '')
                                                      ? Color.fromRGBO(
                                                          192, 192, 192, 1)
                                                      : Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.black,
                                          ),
                                          SizedBox(
                                            width: ScreenUtil().setHeight(10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: ScreenUtil().setHeight(30),
                            ),
                            BouncingWidget(
                              scaleFactor: _scaleFactor,
                              onPressed: () {
                                Navigator.pop(context);
                                _filterProceed();
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.45,
                                height: ScreenUtil().setHeight(65),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Color.fromRGBO(31, 127, 194, 1),
                                ),
                                child: Center(
                                  child: Text(
                                    'Filter',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: font14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  void _filterProceed() {
    date.clear();
    title.clear();
    title1.clear();
    date.add(DateTime.parse('2020-07-27'));
    List detail = [
      'Kelvin Koon', //name
      '6423',
      'Long title here',
      'Long decription here',
      '2020-07-23',
      'allDay',
      'allDay',
      'Jason Koo',
      'JT Apps Sdn Bhd',
      '11:00 PM',
      '2020-06-12',
    ];
    title.add(detail);
    title1.add(title);
    _events = Map.fromIterables(date, title1);
    _selectedEvents = title;
    if (this.mounted) {
      setState(() {
        ready = true;
      });
    }
  }

  void _selection(StateSetter setModalState, String type) {
    int selected = 0;
    if (type == 'branch' && branchID != '') {
      for (int i = 0; i < branchList.length; i++) {
        if (branchID == branchList[i].branchID) {
          selected = i;
        }
      }
    } else if (type == 'executive') {
      handlerList.clear();
      if (branchID == '') {
        for (var handlerEach in handlersNoBranch) {
          handlerList.add(handlerEach);
        }
        if (executive != '') {
          for (int i = 0; i < handlersNoBranch.length; i++) {
            if (executiveID == handlersNoBranch[i].handlerID) {
              selected = i;
            }
          }
        }
      } else {
        print('object');
        for (var handlerEach in handlersBranch) {
          for (var branchEach in handlerEach.branches) {
            if (branchEach['branch_id'] == branchID) {
              handlerList.add(handlerEach);
            }
          }
        }
        if (executive != '') {
          for (int i = 0; i < handlerList.length; i++) {
            if (executiveID == handlerList[i].handlerID) {
              selected = i;
            }
          }
        }
      }
    }
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState1) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom:
                            BorderSide(width: 1, color: Colors.grey.shade300),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.all(
                            ScreenUtil().setHeight(20),
                          ),
                          child: Text(
                            "Select",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: font14,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: EdgeInsets.all(
                              ScreenUtil().setHeight(20),
                            ),
                            child: Text(
                              "Done",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: font14,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (type == 'branch') {
                              if (this.mounted) {
                                setModalState(() {
                                  branch = branchList[selected].branchName;
                                  branchID = branchList[selected].branchID;
                                  executive = '';
                                });
                              }
                            } else {
                              if (this.mounted) {
                                setModalState(() {
                                  executive = handlerList[selected].handler;
                                  executiveID = handlerList[selected].handlerID;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      color: Colors.white,
                      child: CupertinoPicker(
                        backgroundColor: Colors.white,
                        itemExtent: 28,
                        scrollController:
                            FixedExtentScrollController(initialItem: selected),
                        onSelectedItemChanged: (int index) {
                          if (this.mounted) {
                            setState(() {
                              selected = index;
                            });
                          }
                        },
                        children: (type == 'branch')
                            ? _text('branchList')
                            : _text('executiveList'),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _text(String type) {
    List widgetList = <Widget>[];
    switch (type) {
      case 'executiveList':
        List<Handler> list = handlerList;
        for (var each in list) {
          Widget widget1 = Text(
            each.handler,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      default:
        List<Branch> list = branchList;
        for (var each in list) {
          Widget widget1 = Text(
            each.branchName,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
    }
    return widgetList;
  }

  Widget popupMenuButton() {
    return PopupMenuButton<String>(
        icon: Icon(
          Icons.calendar_today,
          size: ScreenUtil().setWidth(40),
          color: Colors.grey,
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: "month",
                child: Text(
                  "Month",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: "week",
                child: Text(
                  "Week",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              ),
            ],
        onSelected: (selectedItem) {
          switch (selectedItem) {
            case 'month':
              {
                setState(() {
                  _calendarController.setCalendarFormat(CalendarFormat.month);
                });
              }
              break;
            default:
              {
                setState(() {
                  _calendarController.setCalendarFormat(CalendarFormat.week);
                });
              }
          }
        });
  }

  Future<void> showHoliday(DateTime date) async {
    List holidayEvents =
        _holidays[DateTime.parse(date.toString().substring(0, 10))];
    if (holidayEvents.length != 0) {
      String holiday = holidayEvents[0];
      YYProgressDialogNoBody(holiday);
    }
  }

  YYDialog YYProgressDialogNoBody(String holiday) {
    return YYDialog().build()
      ..width = ScreenUtil().setHeight(500)
      ..borderRadius = 4.0
      ..gravityAnimationEnable = true
      ..text(
          text: holiday,
          padding: EdgeInsets.all(ScreenUtil().setHeight(40)),
          alignment: Alignment.center)
      ..show();
  }

  List<Widget> _buildEventList() {
    List<Widget> widgetList = [];
    Widget widget1;
    for (int i = 0; i < _selectedEvents.length; i++) {
      widget1 = WidgetANimator(
        InkWell(
          onTap: () {
            Navigator.of(context).push(PageRouteTransition(
                animationType: AnimationType.scale,
                builder: (context) => CalendarEvent(
                      data: _selectedEvents[i],
                      userData: widget.userData,
                    )));
          },
          child: Card(
            child: Container(
              margin: EdgeInsets.fromLTRB(
                  ScreenUtil().setHeight(8), 0, ScreenUtil().setHeight(8), 0),
              padding: EdgeInsets.all(ScreenUtil().setHeight(10)),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _selectedEvents[i][2],
                          style: TextStyle(
                            color: Color.fromRGBO(46, 56, 77, 1),
                            fontSize: font14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      (_selectedEvents[i][1] == widget.userData[0].userID)
                          ? popupButton(_selectedEvents[i], i)
                          : Container(),
                    ],
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(10),
                  ),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _selectedEvents[i][3],
                          style: TextStyle(
                            color: Color.fromRGBO(105, 112, 127, 1),
                            fontSize: font12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(10),
                  ),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.access_time,
                              color: Color.fromRGBO(46, 56, 77, 1),
                              size: ScreenUtil().setHeight(30),
                            ),
                            SizedBox(
                              width: ScreenUtil().setHeight(5),
                            ),
                            Text(
                              (_selectedEvents[i][5] != 'allDay')
                                  ? _selectedEvents[i][5] +
                                      ' - ' +
                                      _selectedEvents[i][6]
                                  : 'Full day',
                              style: TextStyle(
                                color: Color.fromRGBO(46, 56, 77, 1),
                                fontSize: font14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.person,
                              size: ScreenUtil().setHeight(30),
                              color: Color.fromRGBO(46, 56, 77, 1),
                            ),
                            SizedBox(
                              width: ScreenUtil().setHeight(5),
                            ),
                            Flexible(
                              child: Text(
                                _selectedEvents[i][7],
                                style: TextStyle(
                                  color: Color.fromRGBO(46, 56, 77, 1),
                                  fontSize: font14,
                                ),
                                overflow: TextOverflow.ellipsis,
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
      widgetList.add(widget1);
    }
    return widgetList;
  }

  Widget popupButton(List data, int index) {
    return PopupMenuButton<String>(
        padding: EdgeInsets.all(0.1),
        child: Container(
          height: ScreenUtil().setHeight(40),
          width: ScreenUtil().setHeight(30),
          child: Icon(
            Icons.more_vert,
            size: ScreenUtil().setHeight(38),
            color: Colors.grey,
          ),
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: "edit",
                child: Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: font12,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                value: "delete",
                child: Text(
                  "Delete",
                  style: TextStyle(
                    fontSize: font12,
                  ),
                ),
              ),
            ],
        onSelected: (selectedItem) async {
          switch (selectedItem) {
            case "edit":
              Navigator.push(
                context,
                AwesomePageRoute(
                  transitionDuration: Duration(milliseconds: 600),
                  exitPage: widget,
                  enterPage: CalendarNewEvent(
                      data: data, isNew: false, userData: widget.userData),
                  transition: ZoomOutSlideTransition(),
                ),
              );
              break;
            default:
              setState(() {
                title.removeAt(index);
              });
          }
        });
  }

  void getBranches() {
    http.post(urlBranches, body: {
      "companyID": widget.userData[0].companyID,
      "branchID": widget.userData[0].branchID,
      "userID": widget.userData[0].userID,
      "user_type": widget.userData[0].userType,
      "level": widget.userData[0].level,
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        // print(jsonData);
        for (var data in jsonData) {
          Branch branch = Branch(
            branchID: data['id'],
            branchName: data['name'],
          );
          branchList.add(branch);
        }
      }
      Branch branch = Branch(
        branchID: '',
        branchName: '-',
      );
      branchList.insert(0, branch);
      if (this.mounted) {
        setState(() {
          branchReady = true;
        });
      }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Setup Data error: " + err.toString());
    });
  }

  void initial() {
    getEvents();
    getHandlerList();
    if (widget.userData[0].level == '0') {
      getBranches();
    }
  }

  // void getDate() {
  //   http.post(urlGetDate, body: {
  //     "companyID": widget.userData[0].companyID,
  //     "branchID": widget.userData[0].branchID,
  //     "userID": widget.userData[0].userID,
  //     "user_type": widget.userData[0].userType,
  //     "level": widget.userData[0].level,
  //   }).then((res) {
  //     if (res.body != "nodata") {
  //       var jsonData = json.decode(res.body);
  //       // print(jsonData);
  //       if (this.mounted) {
  //         setState(() {
  //           dateReady = true;
  //         });
  //       }
  //     }
  //   }).catchError((err) {
  //     _toast("No Internet Connection");
  //     print("Setup Data error: " + err.toString());
  //   });
  // }

  void getEvents() {
    for (int i = 0; i < 2; i++) {
      date.add(DateTime.parse('2020-07-' + (25 + i).toString()));
      List detail = [
        'Kelvin Koon', //name
        '6423',
        'Long title here',
        'Long decription here',
        '2020-07-23',
        'allDay',
        'allDay',
        'Jason Koo',
        'JT Apps Sdn Bhd',
        '11:00 PM',
        '2020-06-12',
      ];
      title.add(detail);
      title1.add(title);
    }
    _events = Map.fromIterables(date, title1);
    _selectedEvents = [];
    if (this.mounted) {
      setState(() {
        ready = true;
      });
    }
    http.post(urlEvents, body: {
      "companyID": widget.userData[0].companyID,
      "branchID": widget.userData[0].branchID,
      "userID": widget.userData[0].userID,
      "user_type": widget.userData[0].userType,
      "level": widget.userData[0].level,
    }).then((res) {
      print(res.body);
      // if (res.body != "nodata") {
      //   var jsonData = json.decode(res.body);
      //   print(jsonData);
      //   if (this.mounted) {
      //     setState(() {
      //       listReady = true;
      //     });
      //   }
      // }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Get events error: " + err.toString());
    });
  }

  void getHandlerList() {
    http.post(urlHandler, body: {
      "companyID": widget.userData[0].companyID,
      "branchID": widget.userData[0].branchID,
      "userID": widget.userData[0].userID,
      "user_type": widget.userData[0].userType,
      "level": widget.userData[0].level,
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        // print(jsonData);
        for (var data in jsonData) {
          Handler handler = Handler(
            handler: data["handler"],
            handlerID: data["handlerID"],
            branches: (data["branch"] != '') ? data["branch"] : [],
          );
          (data["branch"] == '')
              ? handlersNoBranch.add(handler)
              : handlersBranch.add(handler);
        }
      }
      if (this.mounted) {
        setState(() {
          handlerReady = true;
        });
      }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Setup Data error: " + err.toString());
    });
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
              "Calender",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[popupMenuButton()],
          ),
        ),
        body: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: TableCalendar(
                onDayLongPressed: (DateTime date, list) {
                  showHoliday(date);
                },
                calendarController: _calendarController,
                events: _events,
                holidays: _holidays,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                builders: CalendarBuilders(),
                calendarStyle: CalendarStyle(
                  canEventMarkersOverflow: true,
                  selectedColor: Color.fromRGBO(31, 127, 194, 1),
                  holidayStyle: TextStyle(color: Colors.yellow[700]),
                  todayStyle: TextStyle(color: Color.fromRGBO(31, 127, 194, 1)),
                  todayColor: null,
                  markersColor: Color.fromRGBO(255, 204, 2, 1),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  centerHeaderTitle: true,
                  formatButtonVisible: false,
                  formatButtonTextStyle:
                      TextStyle().copyWith(color: Colors.white, fontSize: 15.0),
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.deepOrange[400],
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                ),
                onDaySelected: _onDaySelected,
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(
                  ScreenUtil().setHeight(10), ScreenUtil().setHeight(6), 0, 0),
              width: MediaQuery.of(context).size.width,
              height: ScreenUtil().setHeight(80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    _dateFormat(dateSelected),
                    style: TextStyle(
                        fontSize: font16, fontWeight: FontWeight.bold),
                  ),
                  (widget.userData[0].level == '0')
                      ? (branchReady == true && handlerReady == true)
                          ? filter()
                          : Container()
                      : (widget.userData[0].level == '4')
                          ? (handlerReady == true) ? filter() : Container()
                          : Container(),
                ],
              ),
            ),
            (ready == false)
                ? Container(
                    child: Text('data'),
                  )
                : Flexible(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        children: _buildEventList(),
                      ),
                    ),
                  ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              AwesomePageRoute(
                transitionDuration: Duration(milliseconds: 600),
                exitPage: widget,
                enterPage: CalendarNewEvent(
                    isNew: true, userData: widget.userData, date: dateSelected),
                transition: ZoomOutSlideTransition(),
              ),
            );
          },
          child: Icon(
            Icons.add,
          ),
          shape: CircleBorder(),
        ),
      ),
    );
  }

  Widget filter() {
    Widget widget = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: _filter,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(
            ScreenUtil().setHeight(10),
          ),
          child: Icon(
            Icons.tune,
            size: ScreenUtil().setHeight(40),
          ),
        ),
      ),
    );
    return widget;
  }
}
