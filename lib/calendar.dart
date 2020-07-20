import 'dart:async';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:menu_button/menu_button.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/calendarEvent.dart';
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
  Calendar({Key key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

enum UniLinksType { string, uri }

class _CalendarState extends State<Calendar> with TickerProviderStateMixin {
  final ScrollController controller = ScrollController();
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
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Map<DateTime, List> _events;
  List<DateTime> date = [];
  List title = [];
  List<List> title1 = [];
  List _selectedEvents;
  CalendarController _calendarController;
  bool click = false;
  String now, staff;
  List<String> staffs = [
    "All",
    "Kelvin",
    "Staff 1",
    "Mohammad Sabinya bin Abdullah",
  ];

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    staff = '';
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
    var _selectedDay = DateTime.now();
    for (int i = 0; i < 2; i++) {
      date.add(DateTime.parse('2020-07-' + (20 + i).toString()));
      List detail = [
        'Thursday, July 16',
        '01:00',
        '02:00',
        'Kelvin',
        'JT Apps Sdn Bhd JT Apps Sdn Bhd JT Apps Sdn Bhd',
        false
      ];
      title.add(detail);
      title.add(detail);
      title1.add(title);
    }
    _events = Map.fromIterables(date, title1);
    _selectedEvents = _events[_selectedDay] ?? [];
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
    _calendarController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime day, List events) {
    setState(() {
      _selectedEvents = events;
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    final Widget button = SizedBox(
      width: ScreenUtil().setWidth(490),
      height: ScreenUtil().setHeight(60),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                staff,
                style: TextStyle(fontSize: font12),
              ),
            ),
            SizedBox(
              width: ScreenUtil().setWidth(30),
              height: ScreenUtil().setWidth(50),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              "Calender events",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            _buildTableCalendar(),
            Container(
              width: MediaQuery.of(context).size.width,
              height: ScreenUtil().setHeight(80),
              color: Colors.grey[300],
              child: Stack(
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      if (click == false) {
                        _calendarController
                            .setCalendarFormat(CalendarFormat.twoWeeks);
                        setState(() {
                          click = true;
                        });
                      } else {
                        _calendarController
                            .setCalendarFormat(CalendarFormat.month);
                        setState(() {
                          click = false;
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text('Event   '),
                        Center(
                          child: (click == false)
                              ? Image.asset(
                                  'assets/images/up.gif',
                                  width: ScreenUtil().setWidth(40),
                                  height: ScreenUtil().setWidth(40),
                                )
                              : Image.asset(
                                  'assets/images/down.gif',
                                  width: ScreenUtil().setWidth(60),
                                  height: ScreenUtil().setWidth(60),
                                ),
                        ),
                        SizedBox(
                          width: ScreenUtil().setWidth(40),
                        )
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SizedBox(width: ScreenUtil().setWidth(20)),
                          MenuButton(
                            child: button,
                            items: staffs,
                            scrollPhysics: AlwaysScrollableScrollPhysics(),
                            topDivider: true,
                            itemBuilder: (value) => Container(
                              height: ScreenUtil().setHeight(60),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 0.0, horizontal: 10),
                              child: Text(value,
                                  style: TextStyle(fontSize: font12)),
                            ),
                            toggledChild: Container(
                              color: Colors.white,
                              child: button,
                            ),
                            divider: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                            onItemSelected: (value1) {
                              setState(() {
                                staff = value1;
                              });
                            },
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(3.0)),
                                color: Colors.white),
                            onMenuButtonToggle: (isToggle) {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Flexible(
              child: Scaffold(
                backgroundColor: Color.fromRGBO(235, 235, 255, 1),
                body: SingleChildScrollView(
                    controller: controller,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 2.0),
                        Column(children: _buildEventList()),
                      ],
                    )),
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
                enterPage: CalendarEvent(),
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

  Widget _buildTableCalendar() {
    return TableCalendar(
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
        selectedColor: Colors.deepOrange[400],
        holidayStyle: TextStyle(color: Colors.yellow[700]),
        todayColor: Colors.deepOrange[200],
        markersColor: Colors.blue,
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
    );
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
    Widget widget;
    for (var data in _selectedEvents) {
      widget = WidgetANimator(
        InkWell(
          onTap: _basicEasyDialog,
          child: Card(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.98,
              padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 8,
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Time: ' + data[1] + ' - ' + data[2] + 'PM',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: font14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: "Sales person: ",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: font16),
                                  ),
                                  TextSpan(
                                    text: data[3],
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: font16),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: "Deal with: ",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: font16),
                                  ),
                                  TextSpan(
                                    text: 'Vincent',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: font16),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: "Location: ",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: font16),
                                  ),
                                  TextSpan(
                                    text: 'Kuchai Lama',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: font16),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 3,
                        ),
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: "Description: ",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: font16),
                                  ),
                                  TextSpan(
                                    text: data[4],
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: font16),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  (data[5] == true)
                      ? Expanded(
                          flex: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                data[5] = false;
                              });
                            },
                            child: Center(
                                child: Icon(
                              Icons.notifications,
                              color: Colors.yellow[600],
                            )),
                          ),
                        )
                      : Expanded(
                          flex: 1,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                data[5] = true;
                              });
                            },
                            child: Center(
                                child: Icon(Icons.notifications_off,
                                    color: Colors.grey[400])),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      );
      widgetList.add(widget);
    }
    return widgetList;
  }

  void _basicEasyDialog() {
    EasyDialog(
      height: MediaQuery.of(context).size.height * 0.6,
      contentList: _listWidget(),
    ).show(context);
  }

  List<Widget> _listWidget() {
    List<Widget> list = [];
    Widget widget = Column(
      children: <Widget>[
        Text('data'),
        Text('data'),
        Text('data'),
        Text('data'),
        Text('data'),
      ],
    );
    list.add(widget);
    return list;
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.of(context).pop();
    return Future.value(false);
  }
}
