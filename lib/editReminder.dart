import 'dart:async';
import 'package:bouncing_widget/bouncing_widget.dart';
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
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';

class EditReminder extends StatefulWidget {
  final String datetime;
  final String name;
  final String phoneNo;
  final String remark;
  final int dataid;
  final int time;
  EditReminder(
      {Key key,
      this.datetime,
      this.name,
      this.phoneNo,
      this.remark,
      this.dataid,
      this.time})
      : super(key: key);

  @override
  _EditReminderState createState() => _EditReminderState();
}

enum UniLinksType { string, uri }

class _EditReminderState extends State<EditReminder> {
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
  final TextEditingController _remarkcontroller = TextEditingController();
  SharedPreferences prefs;
  String date, remark, now, active, companyID, userID, branchID, userType, level;
  double _scaleFactor = 1.0;
  DateTime dateTime;
  bool invalid, nameInvalid, phoneInvalid, remarkInvalid;
  List reminderList = [];

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    date = remark = '';
    date = widget.datetime;
    if (widget.time != null) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(widget.time);
    }
    _remarkcontroller.text = widget.remark;
    active = 'active';
    invalid = nameInvalid = phoneInvalid = remarkInvalid = false;
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
                color: Colors.black87,
              ),
            ),
            elevation: 1,
            centerTitle: true,
            title: Text(
              "Reminder",
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
            margin: EdgeInsets.fromLTRB(
              ScreenUtil().setHeight(30),
              ScreenUtil().setHeight(30),
              ScreenUtil().setHeight(30),
              ScreenUtil().setHeight(30),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Date and Time: ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: font14,
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
                      child: InkWell(
                        onTap: () {
                          FocusScope.of(context).requestFocus(new FocusNode());
                          _selectDate();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                                color: Colors.grey.shade400,
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  height: ScreenUtil().setHeight(60),
                                  padding: EdgeInsets.fromLTRB(
                                      ScreenUtil().setHeight(10),
                                      ScreenUtil().setHeight(16),
                                      0,
                                      0),
                                  child: Text(
                                    date,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: font14,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black,
                              ),
                              SizedBox(
                                width: ScreenUtil().setWidth(10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                (invalid == true)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Invalid date and time",
                            style:
                                TextStyle(color: Colors.red, fontSize: font12),
                          )
                        ],
                      )
                    : Row(),
                SizedBox(
                  height: ScreenUtil().setHeight(40),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Name: ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: ScreenUtil().setHeight(10),
                ),
                Container(
                  height: ScreenUtil().setHeight(60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.grey.shade400, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          " " + widget.name,
                          style: TextStyle(fontSize: font14),
                        ),
                      ),
                    ],
                  ),
                ),
                (nameInvalid == true)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Please enter the name",
                            style:
                                TextStyle(color: Colors.red, fontSize: font12),
                          )
                        ],
                      )
                    : Row(),
                SizedBox(
                  height: ScreenUtil().setHeight(40),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Phone Number: ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: ScreenUtil().setHeight(10),
                ),
                Container(
                  height: ScreenUtil().setHeight(60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.grey.shade400, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          " " + widget.phoneNo,
                          style: TextStyle(fontSize: font14),
                        ),
                      ),
                    ],
                  ),
                ),
                (phoneInvalid == true)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Please enter phone number",
                            style:
                                TextStyle(color: Colors.red, fontSize: font12),
                          )
                        ],
                      )
                    : Row(),
                SizedBox(
                  height: ScreenUtil().setHeight(40),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Remark: ",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: font14,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: ScreenUtil().setHeight(10),
                ),
                Container(
                  height: ScreenUtil().setHeight(60),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: Colors.grey.shade400, style: BorderStyle.solid),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          style: TextStyle(
                            fontSize: font14,
                          ),
                          controller: _remarkcontroller,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(
                                left: ScreenUtil().setHeight(10),
                                bottom: ScreenUtil().setHeight(20),
                                top: ScreenUtil().setHeight(-15),
                                right: ScreenUtil().setHeight(20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                (remarkInvalid == true)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Please enter remark",
                            style:
                                TextStyle(color: Colors.red, fontSize: font12),
                          )
                        ],
                      )
                    : Row(),
                SizedBox(
                  height: ScreenUtil().setHeight(60),
                ),
                BouncingWidget(
                  scaleFactor: _scaleFactor,
                  onPressed: _save,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: ScreenUtil().setHeight(80),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Color.fromRGBO(34, 175, 240, 1),
                    ),
                    child: Center(
                      child: Text(
                        'Save',
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
    );
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  void _selectDate() {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.3,
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
                            "Select Date",
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
                            try {
                              if (dateTime.millisecondsSinceEpoch <
                                  DateTime.now().millisecondsSinceEpoch) {
                                if (this.mounted) {
                                  setState(() {
                                    invalid = true;
                                  });
                                }
                              } else {
                                if (this.mounted) {
                                  setState(() {
                                    invalid = false;
                                  });
                                }
                              }
                            } catch (e) {}
                          },
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      SizedBox(
                        height: ScreenUtil().setHeight(200),
                        child: CupertinoDatePicker(
                          minimumDate:
                              DateTime.now().subtract(Duration(days: 1)),
                          mode: CupertinoDatePickerMode.dateAndTime,
                          backgroundColor: Colors.transparent,
                          initialDateTime: (widget.dataid == null)
                              ? DateTime.now()
                              : dateTime,
                          onDateTimeChanged: (startDate) {
                            setState(() {
                              dateTime = startDate;
                              date = _convertTime(startDate
                                  .toString()
                                  .substring(
                                      0, startDate.toString().length - 4));
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _convertTime(String time) {
    String converted;
    int hour = int.parse(time.substring(11, 13));
    if (hour < 12) {
      converted = time + ' AM';
    } else if (hour > 12) {
      if (hour - 12 < 10) {
        converted = time.substring(0, 11) +
            " 0" +
            (hour - 12).toString() +
            time.substring(13) +
            ' PM';
      } else {
        converted = time.substring(0, 11) +
            (hour - 12).toString() +
            time.substring(13) +
            ' PM';
      }
    } else {
      converted = time + ' PM';
    }
    return converted;
  }

  Future<void> _save() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (date == '') {
      if (this.mounted) {
        setState(() {
          invalid = true;
        });
      }
    } else {
      if (this.mounted) {
        setState(() {
          invalid = false;
        });
      }
    }
    if (_remarkcontroller.text == '') {
      if (this.mounted) {
        setState(() {
          remarkInvalid = true;
        });
      }
    } else {
      if (this.mounted) {
        setState(() {
          remarkInvalid = false;
        });
      }
    }
    if (date != '' && _remarkcontroller.text != '') {
      if (dateTime.millisecondsSinceEpoch <
          DateTime.now().millisecondsSinceEpoch) {
        if (this.mounted) {
          setState(() {
            invalid = true;
          });
        }
      } else {
        if (this.mounted) {
          setState(() {
            invalid = false;
          });
        }
        Database db = await ReminderDB.instance.database;
        int id = int.parse(
            DateTime.now().millisecondsSinceEpoch.toString().substring(6));
        if (widget.dataid == null) {
          await db.rawInsert(
              'INSERT INTO reminder (dataid, datetime, name, phone, remark, status, time) VALUES("' +
                  id.toString() +
                  '","' +
                  date +
                  '","' +
                  widget.name +
                  '","' +
                  widget.phoneNo +
                  '","' +
                  _remarkcontroller.text +
                  '","' +
                  active +
                  '","' +
                  dateTime.millisecondsSinceEpoch.toString() +
                  '")');
          String details = DateTime.now().millisecondsSinceEpoch.toString() +
              "~!" +
              date +
              "~!" +
              widget.name +
              "~!" +
              widget.phoneNo +
              "~!" +
              _remarkcontroller.text +
              "~!" +
              'not active' +
              "~!" +
              dateTime.millisecondsSinceEpoch.toString();
          _scheduleNotification(id, details);
          _toast('Saved reminder');
          Navigator.pop(context);
        } else {
          await flutterLocalNotificationsPlugin.cancel(widget.dataid);
          await db.rawInsert('UPDATE reminder SET datetime = "' +
              date +
              '", name = "' +
              widget.name +
              '", phone = "' +
              widget.phoneNo +
              '", remark = "' +
              _remarkcontroller.text +
              '", time = "' +
              dateTime.millisecondsSinceEpoch.toString() +
              '" WHERE dataid = ' +
              widget.dataid.toString());
          String details = widget.dataid.toString() +
              "~!" +
              date +
              "~!" +
              widget.name +
              "~!" +
              widget.phoneNo +
              "~!" +
              _remarkcontroller.text +
              "~!" +
              'not active' +
              "~!" +
              dateTime.millisecondsSinceEpoch.toString();
          _scheduleNotification(widget.dataid, details);
          _toast('Updated reminder');
          Navigator.pop(context);
          Navigator.pop(context);
        }
      }
    }
  }

  Future<void> _scheduleNotification(int id, String details) async {
    String name = 'Name: ' + widget.name + ' ';
    String phoneNo = 'Phone Number: ' + widget.phoneNo + ' ';
    String decription = 'Remark: ' + _remarkcontroller.text + ' ';
    var scheduledNotificationDateTime = dateTime;
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
