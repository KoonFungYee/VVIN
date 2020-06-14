import 'dart:async';
import 'dart:convert';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:badges/badges.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity/connectivity.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:progress_indicators/progress_indicators.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/NotiDetail.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/data.dart';
import 'package:vvin/more.dart';
import 'package:vvin/myworks.dart';
import 'package:vvin/notiDB.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vanalytics.dart';
import 'package:vvin/vdata.dart';
import 'package:vvin/vprofile.dart';

class Notifications extends StatefulWidget {
  const Notifications({Key key}) : super(key: key);

  @override
  _NotificationsState createState() => _NotificationsState();
}

enum UniLinksType { string, uri }

class _NotificationsState extends State<Notifications> {
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
  bool more = true;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  String urlNoti = "https://vvinoa.vvin.com/api/notiTotalNumber.php";
  String urlNotification = "https://vvinoa.vvin.com/api/notification.php";
  String urlNotiChangeStatus =
      "https://vvinoa.vvin.com/api/notificationAction.php";
  String userID,
      companyID,
      level,
      userType,
      title,
      subtitle1,
      subtitle2,
      now,
      totalNotification;
  List<Noti> notifications = [];
  bool status, connection, nodata;
  List<Map> offlineNoti;
  int total, startTime, endTime, currentTabIndex;
  SharedPreferences prefs;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    setTime();
    totalNotification = "0";
    currentTabIndex = 3;
    status = false;
    connection = false;
    nodata = false;
    checkConnection();
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

  void check() async {
    if (_type == UniLinksType.string) {
      _sub = getLinksStream().listen((String link) {
        // FlutterWebBrowser.openWebPage(
        //   url: "https://" + link.substring(12),
        // );
      }, onError: (err) {});
    }
  }

  void setTime() async {
    prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'newNoti', (DateTime.now().millisecondsSinceEpoch).toString());
  }

  void onTapped(int index) {
    if (index != 3) {
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
        case 4:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: More(),
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
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
        backgroundColor: Color.fromRGBO(235, 235, 255, 1),
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
              "Notifications",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[popupMenuButton()],
          ),
        ),
        body: SmartRefresher(
          enablePullDown: true,
          enablePullUp: true,
          header: MaterialClassicHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                if (more == true) {
                  body = SpinKitRing(
                    lineWidth: 2,
                    color: Colors.blue,
                    size: 20.0,
                    duration: Duration(milliseconds: 600),
                  );
                }
              } else if (mode == LoadStatus.loading) {
                if (more == true) {
                  body = SpinKitRing(
                    lineWidth: 2,
                    color: Colors.blue,
                    size: 20.0,
                    duration: Duration(milliseconds: 600),
                  );
                }
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
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
              : (nodata == false)
                  ? SingleChildScrollView(
                      physics: ScrollPhysics(),
                      child: Column(
                        children: _list(),
                      ),
                    )
                  : Center(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: EmptyListWidget(
                          packageImage: PackageImage.Image_2,
                          // title: 'No Data',
                          subTitle: 'No Data',
                          titleTextStyle: Theme.of(context)
                              .typography
                              .dense
                              .display1
                              .copyWith(color: Color(0xff9da9c7)),
                          subtitleTextStyle: Theme.of(context)
                              .typography
                              .dense
                              .body2
                              .copyWith(color: Color(0xffabb8d6)),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  List<Widget> _list() {
    List widgetList = <Widget>[];
    int length;
    if (connection == true) {
      length = notifications.length;
    } else {
      length = offlineNoti.length;
    }
    for (var i = 0; i < length; i++) {
      List list;
      String nameStart, nameEnd, type, title, subtitle;
      nameStart = 'Name: ';
      nameEnd = 'Contact';

      if (connection == true) {
        title = notifications[i].title;
      } else {
        title = offlineNoti[i]['title'];
      }
      if (title.substring(0, 3) == 'You') {
        type = 'new';
        list = title.split('- ');
      } else if (title.substring(0, 3) == 'VVI') {
        if (title.substring(title.length - 6, title.length) == 'branch') {
          type = 'link';
        } else {
          type = 'user';
        }
      } else {
        type = 'assign';
        list = title.split(' has');
      }
      if (connection == true) {
        subtitle = notifications[i].subtitle;
      } else {
        subtitle = offlineNoti[i]['subtitle'];
      }
      Widget widget1;
      double cwidth = MediaQuery.of(context).size.width * 0.8;
      widget1 = Container(
        padding: EdgeInsets.all(ScreenUtil().setHeight(10)),
        decoration: BoxDecoration(
          color: (connection == false)
              ? (offlineNoti[i]['status'] == "1")
                  ? Colors.white
                  : Color.fromRGBO(234, 244, 251, 1)
              : (notifications[i].status == "1")
                  ? Colors.white
                  : Color.fromRGBO(234, 244, 251, 1),
          border: Border(
            bottom: BorderSide(width: 1, color: Colors.grey.shade300),
          ),
        ),
        child: Column(
          children: <Widget>[
            WidgetANimator(
              InkWell(
                  onTap: () {
                    changeStatus(i);
                  },
                  child: Row(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.all(10.0),
                        width: ScreenUtil().setWidth(80),
                        height: ScreenUtil().setHeight(80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: _icon(type),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: cwidth,
                                child: _title(title, type, subtitle, list),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(10),
                          ),
                          Row(
                            children: <Widget>[
                              Text(
                                (connection == false)
                                    ? offlineNoti[i]['date']
                                        .toString()
                                        .substring(0, 10)
                                    : notifications[i]
                                        .date
                                        .toString()
                                        .substring(0, 10),
                                style: TextStyle(
                                  color: Color.fromRGBO(165, 165, 165, 1),
                                  fontSize: font12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  )),
            ),
          ],
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  Widget _title(String title, String type, String subtitle, List list) {
    Widget widget;
    String nameStart, nameEnd;
    nameStart = 'Name: ';
    nameEnd = 'Contact';
    switch (type) {
      case 'new':
        widget = RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'A New VData ',
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontSize: font16,
              ),
            ),
            TextSpan(
              text: subtitle.substring(
                  subtitle.indexOf(nameStart) + nameStart.length,
                  subtitle.indexOf(
                      nameEnd, subtitle.indexOf(nameStart) + nameStart.length)),
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontWeight: FontWeight.bold,
                fontSize: font16,
              ),
            ),
            TextSpan(
              text: ' has been obtained through ',
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontSize: font16,
              ),
            ),
            TextSpan(
              text: list[1],
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontWeight: FontWeight.bold,
                fontSize: font16,
              ),
            ),
          ]),
        );
        break;
      case 'user':
        widget = Text(
          title.substring(7),
          style: TextStyle(
            color: Color.fromRGBO(20, 23, 32, 1),
            fontSize: font14,
          ),
        );
        break;
      case 'assign':
        widget = RichText(
          text: TextSpan(children: [
            TextSpan(
              text: 'VData ',
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontSize: font16,
              ),
            ),
            TextSpan(
              text: subtitle.substring(
                  subtitle.indexOf(nameStart) + nameStart.length,
                  subtitle.indexOf(
                      nameEnd, subtitle.indexOf(nameStart) + nameStart.length)),
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontWeight: FontWeight.bold,
                fontSize: font16,
              ),
            ),
            TextSpan(
              text: ' has been assigned to you by ',
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontSize: font16,
              ),
            ),
            TextSpan(
              text: list[0],
              style: TextStyle(
                color: Color.fromRGBO(20, 23, 32, 1),
                fontWeight: FontWeight.bold,
                fontSize: font16,
              ),
            ),
          ]),
        );
        break;
      case 'link':
        widget = Text(
          title.substring(7),
          style: TextStyle(
            color: Color.fromRGBO(20, 23, 32, 1),
            fontSize: font14,
          ),
        );
        break;
    }
    return widget;
  }

  Widget _icon(String type) {
    Widget widget;
    switch (type) {
      case 'new':
        widget = Icon(Icons.insert_chart,
            size: ScreenUtil().setHeight(40),
            color: Color.fromRGBO(31, 127, 194, 1));
        break;
      case 'assign':
        widget = Icon(FontAwesomeIcons.userPlus,
            size: ScreenUtil().setHeight(40),
            color: Color.fromRGBO(31, 127, 194, 1));
        break;
      case 'user':
        widget = Icon(FontAwesomeIcons.user,
            size: ScreenUtil().setHeight(40),
            color: Color.fromRGBO(31, 127, 194, 1));
        break;
      case 'link':
        widget = Image.asset('assets/images/unit.png',
            width: ScreenUtil().setHeight(20),
            height: ScreenUtil().setHeight(20));
        break;
      default:
    }
    return widget;
  }

  void _onRefresh() {
    if (connection == true) {
      notifications.clear();
      http.post(urlNotification, body: {
        "userID": userID,
        "companyID": companyID,
        "level": level,
        "user_type": userType,
        "count": "0",
      }).then((res) {
        notifications.clear();
        if (res.body == "nodata") {
          _toast("No Data");
        } else {
          var jsonData = json.decode(res.body);
          total = jsonData[0]['total'];
          String subtitle, subtitle1;
          String subtitle2 = "";
          for (int i = 0; i < jsonData.length; i++) {
            if (jsonData[i]['subtitle'].toString().contains(",")) {
              List subtitleList = jsonData[i]['subtitle'].toString().split(",");
              subtitle1 = subtitleList[0] + ", ";
              List secondSubtitle = subtitleList[1].toString().split(".");
              if (secondSubtitle.length < 3) {
                int match = 0;
                for (int k = 0; k < secondSubtitle[0].length; k++) {
                  if (secondSubtitle[0]
                          .toString()
                          .substring(k, k + 1)
                          .contains(new RegExp(r'[A-Z]')) ||
                      secondSubtitle[0]
                          .toString()
                          .substring(k, k + 1)
                          .contains(new RegExp(r'[a-z]'))) {
                    if (match == 0) {
                      subtitle2 =
                          secondSubtitle[0].toString().substring(k) + ".";
                      match++;
                    }
                  }
                }
              } else {
                int match = 0;
                for (int j = 0; j < secondSubtitle.length - 4; j++) {
                  if (j == 0) {
                    for (int k = 0; k < secondSubtitle[0].length; k++) {
                      if (secondSubtitle[0]
                              .toString()
                              .substring(k, k + 1)
                              .contains(new RegExp(r'[A-Z]')) ||
                          secondSubtitle[0]
                              .toString()
                              .substring(k, k + 1)
                              .contains(new RegExp(r'[a-z]'))) {
                        if (match == 0) {
                          subtitle2 =
                              secondSubtitle[0].toString().substring(k) + ".";
                          match++;
                        }
                      }
                    }
                  } else {
                    subtitle2 += secondSubtitle[j] + ".";
                  }
                }
              }
              subtitle = subtitle1 + subtitle2;
            } else {
              subtitle = jsonData[i]['subtitle'];
            }

            Noti notification = Noti(
                title: jsonData[i]['title'],
                subtitle: subtitle,
                date: jsonData[i]['date'],
                notiID: jsonData[i]['id'],
                status: jsonData[i]['status']);
            notifications.add(notification);
          }
          if (this.mounted) {
            setState(() {
              status = true;
              connection = true;
            });
          }
          setNoti();
        }
      }).catchError((err) {
        _toast("No Internet Connection");
        print("Get Notifications error: " + (err).toString());
      });
      _refreshController.refreshCompleted();
    } else {
      _toast("Offline mode not allow to reload");
      _refreshController.refreshCompleted();
    }
  }

  void _onLoading() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlNotification, body: {
        "userID": userID,
        "companyID": companyID,
        "level": level,
        "user_type": userType,
        "count": notifications.length.toString(),
      }).then((res) {
        var jsonData = json.decode(res.body);
        // print("Notifications reload body: " + jsonData.toString());
        String subtitle, subtitle1;
        String subtitle2 = "";
        for (int i = 0; i < jsonData.length; i++) {
          if (jsonData[i]['subtitle'].toString().contains(",")) {
            List subtitleList = jsonData[i]['subtitle'].toString().split(",");
            subtitle1 = subtitleList[0] + ", ";
            List secondSubtitle = subtitleList[1].toString().split(".");
            if (secondSubtitle.length < 3) {
              int match = 0;
              for (int k = 0; k < secondSubtitle[0].length; k++) {
                if (secondSubtitle[0]
                        .toString()
                        .substring(k, k + 1)
                        .contains(new RegExp(r'[A-Z]')) ||
                    secondSubtitle[0]
                        .toString()
                        .substring(k, k + 1)
                        .contains(new RegExp(r'[a-z]'))) {
                  if (match == 0) {
                    subtitle2 = secondSubtitle[0].toString().substring(k) + ".";
                    match++;
                  }
                }
              }
            } else {
              int match = 0;
              for (int j = 0; j < secondSubtitle.length - 4; j++) {
                if (j == 0) {
                  for (int k = 0; k < secondSubtitle[0].length; k++) {
                    if (secondSubtitle[0]
                            .toString()
                            .substring(k, k + 1)
                            .contains(new RegExp(r'[A-Z]')) ||
                        secondSubtitle[0]
                            .toString()
                            .substring(k, k + 1)
                            .contains(new RegExp(r'[a-z]'))) {
                      if (match == 0) {
                        subtitle2 =
                            secondSubtitle[0].toString().substring(k) + ".";
                        match++;
                      }
                    }
                  }
                } else {
                  subtitle2 += secondSubtitle[j] + ".";
                }
              }
            }
            subtitle = subtitle1 + subtitle2;
          } else {
            subtitle = jsonData[i]['subtitle'];
          }
          Noti notification = Noti(
              title: jsonData[i]['title'],
              subtitle: subtitle,
              date: jsonData[i]['date'],
              notiID: jsonData[i]['id'],
              status: jsonData[i]['status']);
          notifications.add(notification);
        }
        if (this.mounted) {
          setState(() {
            status = true;
            connection = true;
          });
        }
      }).catchError((err) {
        _toast(err.toString());
        print("Get More Notification error: " + (err).toString());
      });
      _refreshController.loadComplete();
    } else {
      _toast("Data can't load, please check your Internet connection");
      _refreshController.loadComplete();
    }
  }

  Widget popupMenuButton() {
    if (connection == true) {
      return PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          size: ScreenUtil().setWidth(40),
          color: Colors.grey,
        ),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: "markall",
            child: Text(
              "Mark all as read",
              style: TextStyle(
                fontSize: font14,
              ),
            ),
          ),
        ],
        onSelected: (selectedItem) {
          switch (selectedItem) {
            case "markall":
              {
                markAllAsRead();
              }
              break;
          }
        },
      );
    } else {
      return Container();
    }
  }

  void markAllAsRead() {
    http
        .post(urlNotiChangeStatus, body: {
          "userID": userID,
          "companyID": companyID,
          "level": level,
          "user_type": userType,
          "id": "all",
          "actionType": "read",
        })
        .then((res) {})
        .catchError((err) {
          print("Notification change status error: " + (err).toString());
        });
    prefs.setString('noti', '0');
    for (int i = 0; i < notifications.length; i++) {
      if (this.mounted) {
        setState(() {
          notifications[i].status = "1";
        });
      }
    }
    if (this.mounted) {
      setState(() {
        totalNotification = "0";
      });
    }
    FlutterAppBadger.removeBadge();
  }

  void changeStatus(int index) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (notifications[index].subtitle.toString().substring(0, 4) != 'Dear') {
        List names =
            notifications[index].subtitle.toString().split("Contact Number:");
        List phones = names[1].toString().split(' Make');
        VDataDetails vdata = new VDataDetails(
          companyID: companyID,
          userID: userID,
          level: level,
          userType: userType,
          name: names[0].toString().substring(14),
          phoneNo: phones[0].toString().substring(1),
          status: '',
        );
        Navigator.of(context).push(PageRouteTransition(
            animationType: AnimationType.scale,
            builder: (context) => VProfile(
                  vdata: vdata,
                  notification: 'yes',
                )));
      } else {
        String subtitle1, subtitle2;
        List subtitleDetail;
        if (connection == true) {
          subtitleDetail = notifications[index].subtitle.toString().split(",");
        } else {
          subtitleDetail = offlineNoti[index]['subtitle'].toString().split(",");
        }

        if (subtitleDetail.length == 1) {
          subtitle1 = subtitleDetail[0];
          subtitle2 = "";
        } else {
          subtitle1 = subtitleDetail[0];
          subtitle2 = subtitleDetail[1];
        }

        String titleNoti;
        if (connection == true) {
          titleNoti = notifications[index].title;
        } else {
          titleNoti = offlineNoti[index]['title'];
        }
        NotificationDetail notification = new NotificationDetail(
          title: titleNoti,
          subtitle1: subtitle1,
          subtitle2: subtitle2,
        );
        Navigator.push(
          context,
          AwesomePageRoute(
            transitionDuration: Duration(milliseconds: 600),
            exitPage: widget,
            enterPage: NotiDetail(
              notification: notification,
              companyID: companyID,
              level: level,
              userID: userID,
              userType: userType,
            ),
            transition: StackTransition(),
          ),
        );
      }

      if (notifications[index].status == "0" && connection == true) {
        http
            .post(urlNotiChangeStatus, body: {
              "userID": userID,
              "companyID": companyID,
              "level": level,
              "user_type": userType,
              "id": notifications[index].notiID,
              "actionType": "read",
            })
            .then((res) {})
            .catchError((err) {
              print("Notification change status error: " + (err).toString());
            });
        if (this.mounted) {
          setState(() {
            notifications[index].status = "1";
            totalNotification = (int.parse(totalNotification) - 1).toString();
          });
        }
        FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
        prefs.setString('noti', totalNotification);
      }
    } else {
      _toast("Please check your Internet Connection");
    }
  }

  String checkTitle(String title) {
    String confirmedTitle;
    if (title.substring(0, 1) == "r") {
      confirmedTitle = "You've " + title;
    } else {
      confirmedTitle = title;
    }
    return confirmedTitle;
  }

  String checkSubtitle(String subtitle) {
    String confirmedSubtitle;
    if (subtitle.substring(0, 7) == "Details") {
      confirmedSubtitle = subtitle.substring(8, subtitle.length - 9);
    } else {
      confirmedSubtitle = subtitle;
    }
    return confirmedSubtitle;
  }

  Future<bool> _onBackPressAppBar() async {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
              title: Text(
                "Are you sure you want to close application?",
                style: TextStyle(
                  fontSize: font14,
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text("NO"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                FlatButton(
                  child: Text("YES"),
                  onPressed: () {
                    SystemNavigator.pop();
                  },
                )
              ],
            ));
    return Future.value(false);
  }

  void checkConnection() async {
    prefs = await SharedPreferences.getInstance();
    companyID = prefs.getString('companyID');
    level = prefs.getString('level');
    userID = prefs.getString('userID');
    userType = prefs.getString('user_type');
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
      getNotifications();
    } else {
      initialize();
      _toast("No Internet, the data shown is not up to date");
    }
  }

  void getNotifications() async {
    userID = prefs.getString('userID');
    companyID = prefs.getString('companyID');
    level = prefs.getString('level');
    userType = prefs.getString('user_type');
    notification();
    startTime = (DateTime.now()).millisecondsSinceEpoch;
    http.post(urlNotification, body: {
      "userID": userID,
      "companyID": companyID,
      "level": level,
      "user_type": userType,
      "count": "0",
    }).then((res) async {
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            nodata = true;
            status = true;
            connection = true;
          });
        }
      } else {
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("Notification loading Time: " + result.toString());
        var jsonData = json.decode(res.body);
        total = jsonData[0]['total'];
        String subtitle, subtitle1;
        String subtitle2 = "";
        for (int i = 0; i < jsonData.length; i++) {
          if (jsonData[i]['subtitle'].toString().contains(",")) {
            List subtitleList = jsonData[i]['subtitle'].toString().split(",");
            subtitle1 = subtitleList[0] + ", ";
            List secondSubtitle = subtitleList[1].toString().split(".");

            if (secondSubtitle.length < 3) {
              int match = 0;
              for (int k = 0; k < secondSubtitle[0].length; k++) {
                if (secondSubtitle[0]
                        .toString()
                        .substring(k, k + 1)
                        .contains(new RegExp(r'[A-Z]')) ||
                    secondSubtitle[0]
                        .toString()
                        .substring(k, k + 1)
                        .contains(new RegExp(r'[a-z]'))) {
                  if (match == 0) {
                    subtitle2 = secondSubtitle[0].toString().substring(k) + ".";
                    match++;
                  }
                }
              }
            } else {
              int match = 0;
              if (secondSubtitle.length - 4 != 0) {
                for (int j = 0; j < secondSubtitle.length - 4; j++) {
                  if (j == 0) {
                    for (int k = 0; k < secondSubtitle[0].length; k++) {
                      if (secondSubtitle[0]
                              .toString()
                              .substring(k, k + 1)
                              .contains(new RegExp(r'[A-Z]')) ||
                          secondSubtitle[0]
                              .toString()
                              .substring(k, k + 1)
                              .contains(new RegExp(r'[a-z]'))) {
                        if (match == 0) {
                          subtitle2 =
                              secondSubtitle[0].toString().substring(k) + ".";
                          match++;
                        }
                      }
                    }
                  } else {
                    subtitle2 += secondSubtitle[j] + ".";
                  }
                }
              } else {
                for (int j = 0; j < secondSubtitle.length; j++) {
                  if (j == 0) {
                    for (int k = 0; k < secondSubtitle[0].length; k++) {
                      if (secondSubtitle[0]
                              .toString()
                              .substring(k, k + 1)
                              .contains(new RegExp(r'[A-Z]')) ||
                          secondSubtitle[0]
                              .toString()
                              .substring(k, k + 1)
                              .contains(new RegExp(r'[a-z]'))) {
                        if (match == 0) {
                          subtitle2 =
                              secondSubtitle[0].toString().substring(k) + ".";
                          match++;
                        }
                      }
                    }
                  } else {
                    subtitle2 += secondSubtitle[j] + ".";
                  }
                }
              }
            }
            subtitle = subtitle1 + subtitle2;
          } else {
            subtitle = jsonData[i]['subtitle'];
          }
          Noti notification = Noti(
              title: jsonData[i]['title'],
              subtitle: subtitle,
              date: jsonData[i]['date'],
              notiID: jsonData[i]['id'],
              status: jsonData[i]['status']);
          notifications.add(notification);
        }
        if (this.mounted) {
          setState(() {
            status = true;
            connection = true;
          });
        }
        setNoti();
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get Notifications error: " + (err).toString());
    });
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

  Future<void> initialize() async {
    Database db = await NotiDB.instance.database;
    offlineNoti = await db.query(NotiDB.table);
    if (offlineNoti.length == 0) {
      nodata = true;
    }
    if (this.mounted) {
      setState(() {
        status = true;
      });
    }
  }

  Future<void> setNoti() async {
    Database db = await NotiDB.instance.database;
    await db.rawInsert('DELETE FROM noti WHERE id > 0');
    for (int index = 0; index < notifications.length; index++) {
      await db.rawInsert(
          'INSERT INTO noti (title, subtitle, notiid, date, status) VALUES("' +
              notifications[index].title +
              '","' +
              notifications[index].subtitle +
              '","' +
              notifications[index].notiID +
              '","' +
              notifications[index].date +
              '","' +
              notifications[index].status +
              '")');
    }
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
