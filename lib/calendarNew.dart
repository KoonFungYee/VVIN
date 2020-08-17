import 'dart:async';
import 'dart:typed_data';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttericon/linecons_icons.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/calendar.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';

class CalendarNewEvent extends StatefulWidget {
  final List data;
  final bool isNew;
  final String date;
  final List<UserData> userData;
  CalendarNewEvent({Key key, this.data, this.isNew, this.date, this.userData})
      : super(key: key);

  @override
  _CalendarNewEventState createState() => _CalendarNewEventState();
}

enum UniLinksType { string, uri }

class _CalendarNewEventState extends State<CalendarNewEvent> {
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
  final ScrollController dialogController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _meetWithController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  var _timeController = MaskedTextController(mask: '000');
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  UniLinksType _type = UniLinksType.string;
  SharedPreferences prefs;
  String urlSaveCalendar = ip + "saveCalendar.php";
  List<String> notiList = [];
  double _scaleFactor = 1.0;
  int _radioValue = 0;
  String now, date, startTime, endTime, notificationTime;
  DateTime start, end;
  bool allDay;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    _timeController.text = '10';
    if (widget.isNew == false) {
      _titleController.text = widget.data[2];
      _descriptionController.text = widget.data[3];
      _meetWithController.text = widget.data[7];
      _locationController.text = widget.data[8];
      date = widget.data[4];
      startTime = widget.data[5];
      endTime = widget.data[6];
      if (widget.data[5] != 'allDay') {
        start = _timeFormat(widget.data[5]);
        end = _timeFormat(widget.data[6]);
      }
      notificationTime = widget.data[9];
      (widget.data[5] == 'allDay') ? allDay = true : allDay = false;
    } else {
      _titleController.text = '';
      _descriptionController.text = '';
      _meetWithController.text = '';
      _locationController.text = '';
      date = widget.date;
      startTime = '';
      endTime = '';
      allDay = false;
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
    prefs = await SharedPreferences.getInstance();
    setState(() {
      notiList = prefs.getStringList('notiList') ?? [];
    });
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
              (widget.isNew == true) ? "Create Event" : "Event",
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
            padding: EdgeInsets.all(ScreenUtil().setHeight(10)),
            child: Column(
              children: <Widget>[
                SizedBox(height: ScreenUtil().setHeight(20)),
                Row(
                  children: <Widget>[
                    Text(
                      'Title',
                      style: TextStyle(
                        color: Color.fromRGBO(20, 23, 32, 1),
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenUtil().setHeight(5)),
                Container(
                  height: ScreenUtil().setHeight(60),
                  color: Colors.white,
                  child: TextField(
                    style: TextStyle(
                      height: 1,
                      fontSize: font14,
                    ),
                    controller: _titleController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Title',
                      contentPadding:
                          EdgeInsets.only(left: ScreenUtil().setHeight(10)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(20)),
                Row(
                  children: <Widget>[
                    Text(
                      'Description',
                      style: TextStyle(
                        color: Color.fromRGBO(20, 23, 32, 1),
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenUtil().setHeight(5)),
                Container(
                  color: Colors.white,
                  child: TextField(
                    maxLines: 3,
                    style: TextStyle(
                      height: 1,
                      fontSize: font14,
                    ),
                    controller: _descriptionController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Add description here',
                      contentPadding: EdgeInsets.only(
                          left: ScreenUtil().setHeight(10),
                          top: ScreenUtil().setHeight(20)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(20)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Date',
                      style: TextStyle(
                        color: Color.fromRGBO(46, 56, 77, 1),
                        fontSize: font14,
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'All day event',
                          style: TextStyle(
                            color: Color.fromRGBO(135, 152, 173, 1),
                            fontSize: font14,
                          ),
                        ),
                        Transform.scale(
                          alignment: Alignment.centerRight,
                          scale: ScreenUtil().setWidth(1.5),
                          child: CupertinoSwitch(
                            activeColor: Color.fromRGBO(0, 174, 239, 1),
                            value: allDay,
                            onChanged: (bool value) {
                              if (this.mounted) {
                                if (value == false) {
                                  setState(() {
                                    startTime = '';
                                    endTime = '';
                                    allDay = value;
                                    notificationTime = null;
                                  });
                                } else {
                                  setState(() {
                                    allDay = value;
                                    notificationTime = null;
                                  });
                                }
                              }
                            },
                          ),
                        )
                      ],
                    )
                  ],
                ),
                Container(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: ScreenUtil().setHeight(20)),
                      Row(
                        children: <Widget>[
                          Text(
                            'Start',
                            style: TextStyle(
                              color: Color.fromRGBO(135, 152, 173, 1),
                              fontSize: font14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ScreenUtil().setHeight(5)),
                      InkWell(
                        onTap: () {
                          if (allDay == false) {
                            _notiType('startTime');
                          }
                        },
                        child: Container(
                          height: ScreenUtil().setHeight(60),
                          padding: EdgeInsets.all(0.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                date,
                                style: TextStyle(
                                  color: Color.fromRGBO(46, 56, 77, 1),
                                  fontSize: font14,
                                ),
                              ),
                              Text(
                                (allDay == false)
                                    ? (startTime == '') ? '- ' : startTime
                                    : 'Full day',
                                style: TextStyle(
                                  color: Color.fromRGBO(46, 56, 77, 1),
                                  fontSize: font14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(),
                      SizedBox(height: ScreenUtil().setHeight(20)),
                      Row(
                        children: <Widget>[
                          Text(
                            'End',
                            style: TextStyle(
                              color: Color.fromRGBO(135, 152, 173, 1),
                              fontSize: font14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ScreenUtil().setHeight(5)),
                      InkWell(
                        onTap: () {
                          if (allDay == false) {
                            _notiType('endTime');
                          }
                        },
                        child: Container(
                          height: ScreenUtil().setHeight(60),
                          padding: EdgeInsets.all(0.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                date,
                                style: TextStyle(
                                  color: Color.fromRGBO(46, 56, 77, 1),
                                  fontSize: font14,
                                ),
                              ),
                              Text(
                                (allDay == false)
                                    ? (endTime == '') ? '- ' : endTime
                                    : 'Full day',
                                style: TextStyle(
                                  color: Color.fromRGBO(46, 56, 77, 1),
                                  fontSize: font14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(),
                    ],
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(20)),
                Row(
                  children: <Widget>[
                    Text(
                      'Meeting with',
                      style: TextStyle(
                        color: Color.fromRGBO(20, 23, 32, 1),
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenUtil().setHeight(5)),
                Container(
                  height: ScreenUtil().setHeight(60),
                  color: Colors.white,
                  child: TextField(
                    style: TextStyle(
                      height: 1,
                      fontSize: font14,
                    ),
                    controller: _meetWithController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Client\'s Name',
                      contentPadding:
                          EdgeInsets.only(left: ScreenUtil().setHeight(10)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(20)),
                Row(
                  children: <Widget>[
                    Text(
                      'Location',
                      style: TextStyle(
                        color: Color.fromRGBO(20, 23, 32, 1),
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenUtil().setHeight(5)),
                Container(
                  height: ScreenUtil().setHeight(60),
                  color: Colors.white,
                  child: TextField(
                    style: TextStyle(
                      height: 1,
                      fontSize: font14,
                    ),
                    controller: _locationController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Location',
                      contentPadding:
                          EdgeInsets.only(left: ScreenUtil().setHeight(10)),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(20)),
                Row(
                  children: <Widget>[
                    Text(
                      'Notification',
                      style: TextStyle(
                        color: Color.fromRGBO(46, 56, 77, 1),
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ScreenUtil().setHeight(10)),
                (widget.isNew == false)
                    ? (notificationTime == null)
                        ? _notification()
                        : Row(
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  if (this.mounted) {
                                    setState(() {
                                      notificationTime = null;
                                    });
                                  }
                                },
                                child: Container(
                                  width: ScreenUtil().setWidth(
                                      (notificationTime.length * 16.8) + 62.8),
                                  margin:
                                      EdgeInsets.all(ScreenUtil().setHeight(5)),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(235, 235, 255, 1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  padding: EdgeInsets.all(
                                    ScreenUtil().setHeight(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        notificationTime,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(
                                        width: ScreenUtil().setHeight(5),
                                      ),
                                      Icon(
                                        FontAwesomeIcons.timesCircle,
                                        size: ScreenUtil().setHeight(30),
                                        color: Colors.grey,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                    : (notificationTime == null)
                        ? _notification()
                        : Row(
                            children: <Widget>[
                              InkWell(
                                onTap: () {
                                  if (this.mounted) {
                                    setState(() {
                                      notificationTime = null;
                                    });
                                  }
                                },
                                child: Container(
                                  width: ScreenUtil().setWidth(
                                      (notificationTime.length * 16.8) + 62.8),
                                  margin:
                                      EdgeInsets.all(ScreenUtil().setHeight(5)),
                                  decoration: BoxDecoration(
                                    color: Color.fromRGBO(235, 235, 255, 1),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  padding: EdgeInsets.all(
                                    ScreenUtil().setHeight(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        notificationTime,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                        ),
                                      ),
                                      SizedBox(
                                        width: ScreenUtil().setHeight(5),
                                      ),
                                      Icon(
                                        FontAwesomeIcons.timesCircle,
                                        size: ScreenUtil().setHeight(30),
                                        color: Colors.grey,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                SizedBox(height: ScreenUtil().setHeight(60)),
                BouncingWidget(
                  scaleFactor: _scaleFactor,
                  onPressed: _createEvent,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.45,
                    height: ScreenUtil().setHeight(65),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Color.fromRGBO(31, 127, 194, 1),
                    ),
                    child: Center(
                      child: Text(
                        (widget.isNew == true) ? "Create Event" : "Save Event",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: font14,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ScreenUtil().setHeight(60)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createEvent() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (allDay == true) {
      startTime = 'allDay';
      endTime = 'allDay';
    }
    if (_titleController.text == '') {
      _toast('Please fill in title column');
    } else if (notificationTime == null) {
      _toast('Please select one notification');
    } else if (startTime == '') {
      _toast('Please select start time');
    } else if (endTime == '') {
      _toast('Please select end time');
    } else if (allDay == false && end.isBefore(start)) {
      _toast('Invalid time');
    } else if (date == DateTime.now().toString().substring(0, 10)) {
      if (allDay == false && DateTime.now().isAfter(start)) {
        _toast('Invalid time');
      } else if (allDay == true &&
          _timeFormat(notificationTime).isBefore(DateTime.now())) {
        _toast('Invalid time');
      } else {
        String id = (widget.data == null)
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : widget.data[11];
        if (widget.isNew == false) {
          int id = int.parse(
              widget.data[11].substring(3, widget.data[11].length - 3));
          await flutterLocalNotificationsPlugin.cancel(id);
        }
        _saveEvent(id);
        setTime(id);
      }
    } else {
      String id = (widget.data == null)
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : widget.data[11];
      if (widget.isNew == false) {
        int id =
            int.parse(widget.data[11].substring(3, widget.data[11].length - 3));
        await flutterLocalNotificationsPlugin.cancel(id);
      }
      _saveEvent(id);
      setTime(id);
    }
  }

  void setTime(String dataID) {
    DateTime notiTime;
    String time, startEndTime, createdTime, handler, type;
    int id;
    if (startTime != 'allDay') {
      time = date + ' ' + _timeFormat(startTime).toString().substring(11);
      type = notificationTime.split(' ')[1];
      switch (type) {
        case 'minutes':
          notiTime = DateTime.parse(time).subtract(
              Duration(minutes: int.parse(notificationTime.split(' ')[0])));
          break;
        case 'hours':
          notiTime = DateTime.parse(time).subtract(
              Duration(hours: int.parse(notificationTime.split(' ')[0])));
          break;
        default:
          notiTime = DateTime.parse(time).subtract(
              Duration(days: int.parse(notificationTime.split(' ')[0])));
      }
      id = int.parse(dataID.substring(
          3, notiTime.millisecondsSinceEpoch.toString().length - 3));
      startEndTime = startTime + ' - ' + endTime;
    } else {
      time =
          date + ' ' + _timeFormat(notificationTime).toString().substring(11);
      notiTime = DateTime.parse(time);
      id = int.parse(dataID.substring(
          3, notiTime.millisecondsSinceEpoch.toString().length - 3));
      startEndTime = 'Full Day';
    }
    if (widget.isNew == true) {
      createdTime = DateTime.now().toString();
      handler = widget.userData[0].name;
    } else {
      createdTime = widget.data[10];
      handler = widget.data[0];
    }
    String details = createdTime +
        "~!" +
        _titleController.text +
        "~!" +
        _descriptionController.text +
        "~!" +
        date +
        "~!" +
        startEndTime +
        "~!" +
        handler +
        "~!" +
        _meetWithController.text +
        "~!" +
        _locationController.text +
        "~!" +
        notificationTime;
    _scheduleNotification(id, details, notiTime);
  }

  void _saveEvent(String id) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      _onLoading();
      http.post(urlSaveCalendar, body: {
        "id": id,
        "companyID": widget.userData[0].companyID,
        "branchID": widget.userData[0].branchID,
        "level": widget.userData[0].level,
        "userID": widget.userData[0].userID,
        "user_type": widget.userData[0].userType,
        "handler": widget.userData[0].name,
        "title": _titleController.text,
        "description": _descriptionController.text,
        "meet_with": _meetWithController.text,
        "location": _locationController.text,
        "date": date,
        "start_time": startTime,
        "end_time": endTime,
        "notification": notificationTime,
        "created_date": DateTime.now().toString().substring(0, 19),
      }).then((res) {
        if (res.body == 'success') {
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
        print("Save calendar error: " + err.toString());
      });
    } else {
      _toast('No Internet');
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
                  Text('Saving...'),
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

  Widget _notification() {
    Widget widget = Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            BouncingWidget(
              scaleFactor: _scaleFactor,
              onPressed: () {
                (allDay == false) ? _addNoti() : _notiType('noti');
              },
              child: Container(
                width: ScreenUtil().setHeight(280),
                height: ScreenUtil().setHeight(65),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Color.fromRGBO(238, 243, 245, 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.add,
                        size: ScreenUtil().setHeight(22),
                        color: Color.fromRGBO(105, 112, 127, 1)),
                    Text(
                      'Add Notification',
                      style: TextStyle(
                        color: Color.fromRGBO(105, 112, 127, 1),
                        fontSize: font12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ScreenUtil().setHeight(20)),
        (allDay == true)
            ? Container()
            : Column(
                children: _notiList(),
              ),
      ],
    );
    return widget;
  }

  void _addNoti() {
    showModalBottomSheet(
        isDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
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
                            "Add Notification",
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
                  Container(
                    margin: EdgeInsets.all(ScreenUtil().setHeight(20)),
                    child: Column(
                      children: <Widget>[
                        Container(
                          height: ScreenUtil().setHeight(60),
                          color: Colors.white,
                          child: TextField(
                            style: TextStyle(
                              height: 1,
                              fontSize: font14,
                            ),
                            controller: _timeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              suffix: IconButton(
                                iconSize: ScreenUtil().setHeight(35),
                                icon: Icon(Icons.keyboard_hide),
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
                                },
                              ),
                              contentPadding: EdgeInsets.only(
                                left: ScreenUtil().setHeight(10),
                                bottom: ScreenUtil().setHeight(5),
                              ),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: ScreenUtil().setHeight(20)),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 0,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ),
                            Text('Minutes before'),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 1,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ),
                            Text('Hours before'),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Radio(
                              value: 2,
                              groupValue: _radioValue,
                              onChanged: _handleRadioValueChange,
                            ),
                            Text('Days before'),
                          ],
                        ),
                        SizedBox(height: ScreenUtil().setHeight(60)),
                        BouncingWidget(
                          scaleFactor: _scaleFactor,
                          onPressed: _newNotiRemind,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.45,
                            height: ScreenUtil().setHeight(65),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: Color.fromRGBO(31, 127, 194, 1),
                            ),
                            child: Center(
                              child: Text(
                                'Add Notification',
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
                ],
              ),
            );
          });
        });
  }

  void _notiType(String type) {
    String selectedTime = DateTime.now().toString().substring(11, 16);
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
                            _title(type),
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
                  Container(
                    margin: EdgeInsets.all(ScreenUtil().setHeight(20)),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: ScreenUtil().setHeight(200),
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            backgroundColor: Colors.transparent,
                            initialDateTime: _initialTime(type),
                            onDateTimeChanged: (time) {
                              selectedTime = time.toString().substring(11, 16);
                              switch (type) {
                                case 'startTime':
                                  start = time;
                                  break;
                                default:
                                  end = time;
                              }
                            },
                          ),
                        ),
                        SizedBox(height: ScreenUtil().setHeight(60)),
                        BouncingWidget(
                          scaleFactor: _scaleFactor,
                          onPressed: () {
                            switch (type) {
                              case 'startTime':
                                setState(() {
                                  startTime = _time(selectedTime);
                                });
                                if (start == null) {
                                  start = _initialTime(type);
                                }
                                break;
                              case 'endTime':
                                setState(() {
                                  endTime = _time(selectedTime);
                                });
                                if (end == null) {
                                  end = _initialTime(type);
                                }
                                break;
                              default:
                                setState(() {
                                  notificationTime = _time(selectedTime);
                                });
                            }
                            Navigator.pop(context);
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
                                'Done',
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
                ],
              ),
            );
          });
        });
  }

  String _title(String type) {
    String title;
    switch (type) {
      case 'startTime':
        title = 'Start Time';
        break;
      case 'endTime':
        title = 'End Time';
        break;
      default:
        title = 'Add Notification';
    }
    return title;
  }

  DateTime _initialTime(String type) {
    DateTime time;
    switch (type) {
      case 'startTime':
        if (startTime == '') {
          time = DateTime.now();
        } else {
          time = _timeFormat(startTime);
        }
        break;
      case 'endTime':
        if (endTime == '') {
          time = DateTime.now();
        } else {
          time = _timeFormat(endTime);
        }
        break;
      default:
        time = DateTime.now();
    }
    return time;
  }

  DateTime _timeFormat(String time) {
    DateTime actual;
    if (time.substring(time.length - 2) == 'PM') {
      if (time.substring(0, 2) != '12') {
        actual = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(time.substring(0, 2)) + 12,
            int.parse(time.substring(3, 5)));
      } else {
        actual = DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
            int.parse(time.substring(0, 2)),
            int.parse(time.substring(3, 5)));
      }
    } else {
      actual = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
          int.parse(time.substring(0, 2)),
          int.parse(time.substring(3, 5)));
    }
    return actual;
  }

  String _time(String time) {
    int hour = int.parse(time.substring(0, 2));
    if (hour < 12) {
      time = time + ' AM';
    } else if (hour == 12) {
      time = time + ' PM';
    } else {
      if (hour - 12 < 10) {
        time = '0' + (hour - 12).toString() + time.substring(2) + ' PM';
      } else {
        time = (hour - 12).toString() + time.substring(2) + ' PM';
      }
    }
    return time;
  }

  void _newNotiRemind() {
    switch (_radioValue) {
      case 0:
        {
          if (int.parse(_timeController.text) < 60 &&
              _timeController.text != '0') {
            setState(() {
              notiList.add(_timeController.text + ' minutes before');
            });
            prefs.setStringList('notiList', notiList);
          } else {
            _toast("Must be bigger than 0 and smaller than 60");
          }
        }
        break;
      case 1:
        {
          if (int.parse(_timeController.text) < 24 &&
              _timeController.text != '0') {
            setState(() {
              notiList.add(_timeController.text + ' hours before');
            });
            prefs.setStringList('notiList', notiList);
          } else {
            _toast("Must be bigger than 0 and smaller than 24");
          }
        }
        break;
      default:
        {
          if (int.parse(_timeController.text) < 365 &&
              _timeController.text != '0') {
            setState(() {
              notiList.add(_timeController.text + ' days before');
            });
            prefs.setStringList('notiList', notiList);
          } else {
            _toast("Must be bigger than 0 and smaller than 365");
          }
        }
    }
    Navigator.pop(context);
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

  void _handleRadioValueChange(int value) {
    setState(() {
      _radioValue = value;
    });
    Navigator.pop(context);
    _addNoti();
  }

  List<Widget> _notiList() {
    List<Widget> notificationList = [];
    Widget widget;
    for (int i = 0; i < notiList.length; i++) {
      widget = Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: ScreenUtil().setHeight(60),
                padding: EdgeInsets.all(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          setState(() {
                            notificationTime = notiList[i];
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              0,
                              ScreenUtil().setHeight(16),
                              ScreenUtil().setHeight(16),
                              0),
                          child: Text(
                            notiList[i],
                            style: TextStyle(
                              color: Color.fromRGBO(46, 56, 77, 1),
                              fontSize: font14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          notiList.removeAt(i);
                        });
                        prefs.setStringList('notiList', notiList);
                      },
                      child: Padding(
                        padding: EdgeInsets.all(ScreenUtil().setHeight(16)),
                        child: Icon(Linecons.trash,
                            size: ScreenUtil().setHeight(30),
                            color: Color.fromRGBO(135, 152, 173, 1)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(),
        ],
      );
      notificationList.add(widget);
    }
    return notificationList;
  }

  Future<bool> _onBackPressAppBar() async {
    _popup();
    return Future.value(false);
  }

  void _popup() {
    showModalBottomSheet(
        isScrollControlled: true,
        isDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.97,
              margin: EdgeInsets.fromLTRB(
                  ScreenUtil().setHeight(30),
                  ScreenUtil().setHeight(60),
                  ScreenUtil().setHeight(30),
                  ScreenUtil().setHeight(30)),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        child: Icon(
                          FontAwesomeIcons.timesCircle,
                          color: Colors.blue,
                          size: ScreenUtil().setHeight(40),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(30)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Unsaved Changes',
                        style: TextStyle(
                          color: Color.fromRGBO(46, 56, 77, 1),
                          fontSize: font18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          'You have unsaved changes, are you sure you want to discard the unsaved changes?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromRGBO(46, 56, 77, 1),
                            fontSize: font14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ScreenUtil().setHeight(60)),
                  BouncingWidget(
                    scaleFactor: _scaleFactor,
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
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
                          'Discard',
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
            );
          });
        });
  }

  Future<void> _scheduleNotification(
      int id, String details, DateTime notiTime) async {
    String description = 'Description: ' + _descriptionController.text + ' ';
    String time = (startTime != 'allDay')
        ? 'Time: ' + startTime + ' - ' + endTime + ' '
        : 'Time: Full Day';
    String person = 'Person: ' + _meetWithController.text + ' ';
    var scheduledNotificationDateTime = notiTime;
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
        _titleController.text,
        description + '\n' + time + '\n' + person,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        payload: 'calendar' + details);
  }
}
