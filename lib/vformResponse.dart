import 'dart:async';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:floating_menu/floating_menu.dart';
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ndialog/ndialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vform.dart';
import 'package:vvin/viewPDF.dart';

_VFormResponseState pageState;

class Item1 {
  PermissionGroup group;
  PermissionStatus status;

  Item1(this.group, this.status);
}

class VFormResponse extends StatefulWidget {
  final String id;
  final String vformID;
  final String reponseID;
  final String companyID;
  final String branchID;
  final String userID;
  final String level;
  final String userType;
  final String title;
  var data;
  VFormResponse(
      {Key key,
      this.id,
      this.vformID,
      this.companyID,
      this.branchID,
      this.userID,
      this.level,
      this.reponseID,
      this.userType,
      this.title,
      this.data})
      : super(key: key);

  @override
  _VFormResponseState createState() {
    pageState = _VFormResponseState();
    return pageState;
  }
}

enum UniLinksType { string, uri }

class _VFormResponseState extends State<VFormResponse> {
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
  String urlDelete = ip + "deleteResponse.php";
  List<Item1> list1 = List<Item1>();
  String now, phoneNo, name, company, email, area, state, country, industry, companyID, userID, branchID, userType, level;
  int length;
  bool isPhone = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    name = company = email = area = state = country = industry = '';
    list1.add(Item1(PermissionGroup.values[2], PermissionStatus.denied));
    List list = widget.data.toString().split(':');
    length = int.parse(list[0].toString().substring(1));
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
            elevation: 1,
            leading: IconButton(
              onPressed: _onBackPressAppBar,
              icon: Icon(
                Icons.arrow_back_ios,
                size: ScreenUtil().setWidth(30),
                color: Colors.grey,
              ),
            ),
            centerTitle: true,
            title: Text(
              (widget.id == '') ? "Response" : "Response #" + widget.id,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[popupMenuButton()],
          ),
        ),
        body: Container(
          color: Colors.white,
          padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Created on ' +
                        widget.data[length.toString()]['1']['date'].toString(),
                    style: TextStyle(
                      color: Color.fromRGBO(135, 152, 173, 1),
                      fontSize: font12,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: ScreenUtil().setHeight(20),
              ),
              Flexible(
                child: SingleChildScrollView(
                  physics: ScrollPhysics(),
                  child: Column(
                    children: _list(),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: (isPhone == false)
            ? null
            : FloatingMenu(
                isMainButton: true,
                mainButtonColor: Colors.blueAccent,
                mainButtonIcon: Icons.share,
                mainButtonShape: BoxShape.circle,
                floatingType: FloatingType.RightCurve,
                floatingButtonShape: BoxShape.circle,
                floatingButtons: [
                  FloatingButtonModel(
                    locationDegree: 270,
                    locationDistance: 70,
                    shape: BoxShape.circle,
                    color: Colors.orangeAccent,
                    label: "Save Contact",
                    icon: Icons.contact_phone,
                    size: Size(45, 45),
                    onPress: () {
                      requestPermission();
                    },
                  ),
                  FloatingButtonModel(
                    locationDegree: 270,
                    locationDistance: 130,
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(37, 211, 102, 1),
                    label: "WhatsApp",
                    icon: FontAwesomeIcons.whatsapp,
                    size: Size(45, 45),
                    onPress: () async {
                      var connectivityResult =
                          await (Connectivity().checkConnectivity());
                      if (connectivityResult == ConnectivityResult.wifi ||
                          connectivityResult == ConnectivityResult.mobile) {
                        FlutterOpenWhatsapp.sendSingleMessage(phoneNo, "");
                      } else {
                        _toast("This feature need Internet connection");
                      }
                    },
                  ),
                  FloatingButtonModel(
                    locationDegree: 270,
                    locationDistance: 190,
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    label: "Call",
                    icon: Icons.call,
                    size: Size(45, 45),
                    onPress: () {
                      launch("tel:+" + phoneNo);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _list() {
    List widgetList = <Widget>[];
    for (var i = 1; i <= length; i++) {
      String title = widget.data[length.toString()][i.toString()]['title'];
      if (title == 'Phone' || title == '联络号码' || title == 'Nombor Hubungan') {
        if (this.mounted) {
          setState(() {
            phoneNo = widget.data[length.toString()][i.toString()]['answer'];
            isPhone = true;
            _phoneFormat();
          });
        }
      }
      if (title == 'Name' || title == '姓名' || title == 'Nama') {
        if (this.mounted) {
          setState(() {
            name = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      if (title == 'Company Name' ||
          title == '公司名称' ||
          title == 'Nama Syarikat') {
        if (this.mounted) {
          setState(() {
            company = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      if (title == 'Email' || title == '电邮' || title == 'Emel') {
        if (this.mounted) {
          setState(() {
            email = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      if (title == 'Area' || title == '地区' || title == 'Bandar') {
        if (this.mounted) {
          setState(() {
            area = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      if (title == 'State' || title == '州属' || title == 'Negeri') {
        if (this.mounted) {
          setState(() {
            state = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      if (title == 'Country' || title == '国家' || title == 'Negara') {
        if (this.mounted) {
          setState(() {
            country = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      if (title == 'Industry' || title == '行业' || title == 'Industri') {
        if (this.mounted) {
          setState(() {
            industry = widget.data[length.toString()][i.toString()]['answer'];
          });
        }
      }
      String type = 'text';
      if (widget.data[length.toString()][i.toString()]['answer'] != null) {
        if (widget.data[length.toString()][i.toString()]['answer'].length > 5) {
          if (widget.data[length.toString()][i.toString()]['answer']
                  .toString()
                  .substring(0, 5) ==
              'https') {
            List list = widget.data[length.toString()][i.toString()]['answer']
                .toString()
                .split('.');
            if (list[list.length - 1] == 'pdf') {
              type = 'pdf';
            } else {
              type = 'image';
            }
          }
        }
      }
      Widget widget1;
      (i != length)
          ? widget1 = Container(
              padding: EdgeInsets.only(
                top: ScreenUtil().setWidth(10),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Color.fromRGBO(120, 120, 120, 1),
                            fontSize: font16,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(5),
                  ),
                  (type != 'text')
                      ? (type == 'image')
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Center(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (_) {
                                        return ImageScreen(
                                          title: widget.data[length.toString()]
                                              [i.toString()]['title'],
                                          image: widget.data[length.toString()]
                                              [i.toString()]['answer'],
                                        );
                                      }));
                                    },
                                    child: Hero(
                                      tag: 'imageHero',
                                      child: Container(
                                        height: 250,
                                        width: 250,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                  widget.data[length.toString()]
                                                      [i.toString()]['answer']),
                                              fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) {
                                      return ViewPDF(
                                        url: widget.data[length.toString()]
                                            [i.toString()]['answer'],
                                      );
                                    }));
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.picture_as_pdf,
                                        size: ScreenUtil().setHeight(80),
                                        color: Colors.red,
                                      ),
                                      Text(
                                        'Click to view PDF',
                                        style: TextStyle(
                                          color: Color.fromRGBO(20, 23, 32, 1),
                                          fontSize: font16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                (widget.data[length.toString()][i.toString()]
                                                ['answer'] ==
                                            '' ||
                                        widget.data[length.toString()]
                                                [i.toString()]['answer'] ==
                                            null)
                                    ? ' -'
                                    : widget.data[length.toString()]
                                        [i.toString()]['answer'],
                                style: TextStyle(
                                  color: Color.fromRGBO(20, 23, 32, 1),
                                  fontSize: font16,
                                ),
                              ),
                            )
                          ],
                        ),
                  Divider(),
                ],
              ),
            )
          : widget1 = Container(
              padding: EdgeInsets.only(
                top: ScreenUtil().setWidth(10),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Color.fromRGBO(120, 120, 120, 1),
                            fontSize: font16,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(5),
                  ),
                  (type != 'text')
                      ? (type == 'image')
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Center(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (_) {
                                        return ImageScreen(
                                          title: widget.data[length.toString()]
                                              [i.toString()]['title'],
                                          image: widget.data[length.toString()]
                                              [i.toString()]['answer'],
                                        );
                                      }));
                                    },
                                    child: Hero(
                                      tag: 'imageHero',
                                      child: Container(
                                        height: 250,
                                        width: 250,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                  widget.data[length.toString()]
                                                      [i.toString()]['answer']),
                                              fit: BoxFit.contain),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) {
                                      return ViewPDF(
                                        url: widget.data[length.toString()]
                                            [i.toString()]['answer'],
                                      );
                                    }));
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      Icon(
                                        Icons.picture_as_pdf,
                                        size: ScreenUtil().setHeight(80),
                                        color: Colors.red,
                                      ),
                                      Text(
                                        'Click to view PDF',
                                        style: TextStyle(
                                          color: Color.fromRGBO(20, 23, 32, 1),
                                          fontSize: font16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                (widget.data[length.toString()][i.toString()]
                                                ['answer'] ==
                                            '' ||
                                        widget.data[length.toString()]
                                                [i.toString()]['answer'] ==
                                            null)
                                    ? ' -'
                                    : widget.data[length.toString()]
                                        [i.toString()]['answer'],
                                style: TextStyle(
                                  color: Color.fromRGBO(20, 23, 32, 1),
                                  fontSize: font16,
                                ),
                              ),
                            )
                          ],
                        ),
                ],
              ),
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  _showVersionDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title = "Delete response #" + widget.id;
        String message = "Are you sure you want to delete this response";
        return NDialog(
          dialogStyle: DialogStyle(titleDivider: true),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text("Yes"),
              onPressed: () => _delete(),
            ),
            FlatButton(
              child: Text("No"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _delete() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      Navigator.pop(context);
      http
          .post(urlDelete, body: {
            "companyID": widget.companyID,
            "branchID": widget.branchID,
            "userID": widget.userID,
            "level": widget.level,
            "user_type": widget.userType,
            "id": widget.vformID,
            "response_id": widget.reponseID,
          })
          .then((res) {})
          .catchError((err) {
            _toast(err.toString());
            print("Delete error: " + (err).toString());
          });
    } else {
      _toast("Please check your Internet Connection");
    }
    _toast('Response #' + widget.id + ' deleted');
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
      context,
      AwesomePageRoute(
        transitionDuration: Duration(milliseconds: 600),
        exitPage: widget,
        enterPage: VForm(
          companyID: widget.companyID,
          branchID: widget.branchID,
          userID: widget.userID,
          level: widget.level,
          userType: widget.userType,
          title: widget.title,
          id: widget.vformID,
        ),
        transition: StackTransition(),
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
        PopupMenuItem<String>(
          value: "delete",
          child: Text(
            "Delete",
            style: TextStyle(
              fontSize: font16,
            ),
          ),
        ),
      ],
      onSelected: (selectedItem) {
        switch (selectedItem) {
          case "delete":
            {
              _showVersionDialog(context);
            }
            break;
        }
      },
    );
  }

  void _phoneFormat() {
    String patttern = r'[0-9]';
    RegExp regExp = new RegExp(patttern);
    for (int i = 0; i < phoneNo.length; i++) {
      if (!regExp.hasMatch(phoneNo.substring(i, i + 1))) {
        phoneNo = phoneNo.substring(i + 1);
      } else {
        break;
      }
    }
    if (phoneNo.substring(0, 1) == '0') {
      if (this.mounted) {
        setState(() {
          phoneNo = "+6" + phoneNo.substring(0, 1) + ' ' + phoneNo.substring(1);
        });
      }
    } else {
      if (this.mounted) {
        setState(() {
          phoneNo = "+" + phoneNo.substring(0, 2) + ' ' + phoneNo.substring(2);
        });
      }
    }
  }

  Future requestPermission() async {
    var status = await PermissionHandler()
        .requestPermissions([pageState.list1[0].group]);
    if (status.toString() ==
        "{PermissionGroup.contacts: PermissionStatus.granted}") {
      _saveContact();
    }
  }

  void _saveContact() {
    Contact contact = Contact();
    PostalAddress address = PostalAddress(label: "Home");
    contact.givenName = name;
    contact.phones = [Item(label: "mobile", value: phoneNo)];
    if (company != '') {
      contact.company = company;
    }
    if (email != '') {
      contact.emails = [Item(label: "work", value: email)];
    }
    if (area != '') {
      address.city = area;
    }
    if (state != '') {
      address.region = state;
    }
    if (country != '') {
      address.country = country;
    }
    if (industry != '') {
      contact.jobTitle = industry;
    }
    contact.postalAddresses = [address];
    ContactsService.addContact(contact);
    _toast('Saved to contact');
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
    Navigator.pop(context);
    return Future.value(false);
  }
}

class ImageScreen extends StatefulWidget {
  final String image;
  final String title;
  const ImageScreen({Key key, this.image, this.title}) : super(key: key);

  @override
  _ImageScreenState createState() => _ImageScreenState();
}

class _ImageScreenState extends State<ImageScreen> {
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          ScreenUtil().setHeight(85),
        ),
        child: AppBar(
          brightness: Brightness.light,
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios,
              size: ScreenUtil().setWidth(30),
              color: Colors.grey,
            ),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
                color: Colors.black,
                fontSize: font14,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: GestureDetector(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Hero(
              tag: 'imageHero',
              child: Container(
                child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(widget.image),
                ),
              ),
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
