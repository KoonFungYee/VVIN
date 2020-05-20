import 'dart:async';
import 'dart:convert';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:badges/badges.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/data.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/more.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/myworksDB.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vanalytics.dart';
import 'package:vvin/vdata.dart';
import 'package:vvin/whatsappForward.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

final ScrollController whatsappController = ScrollController();

class MyWorks extends StatefulWidget {
  const MyWorks({Key key}) : super(key: key);

  @override
  _MyWorksState createState() => _MyWorksState();
}

enum UniLinksType { string, uri }

class _MyWorksState extends State<MyWorks> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  bool more = true;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  double _scaleFactor = 1.0;
  double font10 = ScreenUtil().setSp(23, allowFontScalingSelf: false);
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font13 = ScreenUtil().setSp(30, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font15 = ScreenUtil().setSp(34.5, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  final TextEditingController _phonecontroller = TextEditingController();
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _companycontroller = TextEditingController();
  final TextEditingController _remarkcontroller = TextEditingController();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  String filePath = "";
  List<Map> offlineLink;
  List vtagList = [];
  List seletedVTag = [];
  List handlerAllList = [];
  List handlerAllList1 = [];
  Database db;
  int total,
      startTime,
      endTime,
      imageIndex,
      linkIndex,
      totalQR,
      totalLink,
      currentTabIndex;
  bool isOffline, status, vtagStatus, connection, nodata, link, image;
  String search,
      companyID,
      userID,
      level,
      userType,
      category,
      dateInternet,
      titleInternet,
      linkInternet,
      typeInternet,
      location,
      base64Image,
      now,
      totalNotification;
  String urlNoti = "https://vvinoa.vvin.com/api/notiTotalNumber.php";
  String urlMyWorks = "https://vvinoa.vvin.com/api/myWorks.php";
  String urlHandler = "https://vvinoa.vvin.com/api/getHandler.php";
  String assignURL = "https://vvinoa.vvin.com/api/assign.php";
  String urlVTag = "https://vvinoa.vvin.com/api/vtag.php";
  String urlWhatsApp = "https://vvinoa.vvin.com/api/whatsappForward.php";
  String urlGetReminder = "https://vvinoa.vvin.com/api/getreminder.php";
  List<Myworks> myWorks = [];
  List<Myworks> myWorks1 = [];
  SharedPreferences prefs;
  File pickedImage;
  bool isImageLoaded;
  List<String> scanner = [];
  List<String> phoneList = [];
  List<String> otherList = [];
  List<String> allHandler = [];
  String tempText = "";
  final _itemExtent = ScreenUtil().setHeight(316);

  @override
  void initState() {
    imageCache.clear();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
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
      onLaunch: (Map<String, dynamic> message) async {
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
    totalNotification = "0";
    currentTabIndex = 2;
    isOffline = false;
    status = false;
    vtagStatus = false;
    connection = false;
    nodata = false;
    link = false;
    isImageLoaded = false;
    base64Image = "";
    _phonecontroller.text = "";
    _namecontroller.text = "";
    _companycontroller.text = "";
    _remarkcontroller.text = "";
    search = "";
    category = "all";
    total = 0;
    imageIndex = 0;
    linkIndex = 0;
    checkConnection();
    super.initState();
  }

  void check() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_type == UniLinksType.string) {
      _sub = getLinksStream().listen((String link) {
        // FlutterWebBrowser.openWebPage(
        //   url: "https://" + link.substring(12),
        // );
      }, onError: (err) {});
      String initialLink;
      if (prefs.getString('url') == '1') {
        try {
          initialLink = await getInitialLink();
          // FlutterWebBrowser.openWebPage(
          //   url: "https://" + initialLink.substring(12),
          // );
          prefs.setString('url', null);
        } catch (e) {}
      }
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
      if (payload != null) {
        debugPrint('notification payload: ' + payload);
      }
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
          int id = int.parse(list[0]);
          String date = list[1].toString().substring(0, 10);
          String time = list[1].toString().substring(11);
          String name = list[2];
          String phone = list[3];
          String remark = list[4];
          String status = list[5];
          int datetime = int.parse(list[6]);
          Navigator.of(context).push(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: Reminder(
                id: id,
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

  void onTapped(int index) {
    if (index != 2) {
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
        case 3:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: Notifications(),
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
  dispose() {
    if (_sub != null) _sub.cancel();
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  void _onRefresh() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (this.mounted) {
        setState(() {
          status = false;
          total = 0;
          category = "all";
        });
      }
      myWorks.clear();
      myWorks1.clear();
      getLink();
    } else {
      _toast("No Internet connection, data can't load");
    }
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    YYDialog.init(context);
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
              "My Works",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Container(
          padding: EdgeInsets.fromLTRB(0, ScreenUtil().setHeight(20), 0, 0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: Card(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                              ScreenUtil().setHeight(20),
                              0,
                              ScreenUtil().setHeight(20),
                              0),
                          height: ScreenUtil().setHeight(80),
                          child: TextField(
                            onChanged: _search,
                            style: TextStyle(
                              fontSize: font14,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                vertical: ScreenUtil().setHeight(6),
                              ),
                              hintText: "Search",
                              suffix: IconButton(
                                iconSize: ScreenUtil().setHeight(35),
                                icon: Icon(Icons.keyboard_hide),
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
                                },
                              ),
                              suffixIcon: Icon(
                                Icons.search,
                                size: ScreenUtil().setHeight(45),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(ScreenUtil().setWidth(10), 0,
                        ScreenUtil().setHeight(0), 0),
                    child: Card(
                      child: InkWell(
                        onTap: _myWorkfilter,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(
                            ScreenUtil().setHeight(15),
                          ),
                          child: Icon(
                            Icons.tune,
                            size: ScreenUtil().setHeight(45),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: ScreenUtil().setHeight(10),
              ),
              (status == true && vtagStatus == true)
                  ? Container(
                      padding: EdgeInsets.all(
                        ScreenUtil().setHeight(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            "QR downloaded: " + totalQR.toString(),
                            style: TextStyle(fontSize: font12),
                          ),
                          Text(
                            "Link downloaded: " + totalLink.toString(),
                            style: TextStyle(fontSize: font12),
                          )
                        ],
                      ),
                    )
                  : Container(),
              SizedBox(
                height: ScreenUtil().setHeight(10),
              ),
              (status == true && vtagStatus == true)
                  ? (nodata == true)
                      ? Center(
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
                                    .copyWith(color: Color(0xffabb8d6))),
                          ),
                        )
                      : Flexible(
                          child: SmartRefresher(
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
                            // onLoading: _onLoading,
                            child: ListView.builder(
                              itemExtent: _itemExtent,
                              itemCount: (connection == false)
                                  ? offlineLink.length
                                  : myWorks.length,
                              itemBuilder: (context, int index) {
                                return WidgetANimator(
                                  Card(
                                    child: Column(
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.fromLTRB(
                                              ScreenUtil().setHeight(20),
                                              ScreenUtil().setHeight(20),
                                              ScreenUtil().setHeight(20),
                                              ScreenUtil().setHeight(10)),
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                height:
                                                    ScreenUtil().setHeight(40),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: <Widget>[
                                                    Text(
                                                      (connection == false)
                                                          ? offlineLink[index]
                                                              ['date']
                                                          : myWorks[index].date,
                                                      style: TextStyle(
                                                        fontSize: font12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    (level != "0")
                                                        ? Container()
                                                        : (myWorks[index]
                                                                        .category !=
                                                                    "VForm" &&
                                                                myWorks[index]
                                                                        .category !=
                                                                    "VBrochure")
                                                            ? popupMenuButton(
                                                                index)
                                                            : Container(),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    (connection == false)
                                                        ? offlineLink[index]
                                                            ['type']
                                                        : myWorks[index]
                                                            .category,
                                                    style: TextStyle(
                                                      fontSize: font12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    ScreenUtil().setHeight(10),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  InkWell(
                                                    onTap: () {
                                                      if (connection != false) {
                                                        _visitURL(index);
                                                      }
                                                    },
                                                    child: Text(
                                                      (connection == false)
                                                          ? offlineLink[index]
                                                              ['title']
                                                          : myWorks[index]
                                                              .title,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                          fontSize: font15,
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height:
                                                    ScreenUtil().setHeight(10),
                                              ),
                                              Row(
                                                children: <Widget>[
                                                  Expanded(
                                                    child: Column(
                                                      children: <Widget>[
                                                        (connection == true)
                                                            ? Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: <
                                                                    Widget>[
                                                                  Text(
                                                                    "Available Offline",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            font12),
                                                                  )
                                                                ],
                                                              )
                                                            : Container(),
                                                        (connection == true)
                                                            ? Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: <
                                                                    Widget>[
                                                                  Transform
                                                                      .scale(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    scale: ScreenUtil()
                                                                        .setWidth(
                                                                            1.5),
                                                                    child:
                                                                        CupertinoSwitch(
                                                                      activeColor:
                                                                          Colors
                                                                              .blue,
                                                                      value: myWorks[
                                                                              index]
                                                                          .offLine,
                                                                      onChanged:
                                                                          (bool
                                                                              value) {
                                                                        if (this
                                                                            .mounted) {
                                                                          setState(
                                                                              () {
                                                                            myWorks[index].offLine =
                                                                                value;
                                                                          });
                                                                        }
                                                                      },
                                                                    ),
                                                                  )
                                                                ],
                                                              )
                                                            : Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: <
                                                                    Widget>[
                                                                  Text(
                                                                    "Offline Mode",
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .grey,
                                                                      fontSize:
                                                                          font12,
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  BouncingWidget(
                                                    scaleFactor: _scaleFactor,
                                                    onPressed: () {
                                                      if (connection == true) {
                                                        _whatsappForward(
                                                            myWorks[index]
                                                                .link);
                                                      } else {
                                                        _toast(
                                                            "Offline mode can not WhatsApp Forward");
                                                      }
                                                    },
                                                    child: Container(
                                                      height: ScreenUtil()
                                                          .setHeight(70),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.25,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                        color: Colors.white,
                                                        border: Border(
                                                          bottom: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                          top: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                          left: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                          right: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'Forward',
                                                          style: TextStyle(
                                                              fontSize: font12,
                                                              color:
                                                                  Colors.blue,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: ScreenUtil()
                                                        .setWidth(20),
                                                  ),
                                                  BouncingWidget(
                                                    scaleFactor: _scaleFactor,
                                                    onPressed: () {
                                                      _viewQR(index);
                                                    },
                                                    child: Container(
                                                      height: ScreenUtil()
                                                          .setHeight(70),
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.25,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                        color: Colors.white,
                                                        border: Border(
                                                          bottom: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                          top: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                          left: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                          right: BorderSide(
                                                              width: 1,
                                                              color:
                                                                  Colors.blue),
                                                        ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'QR Code',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.blue,
                                                              fontSize: font12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                  : Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            JumpingText('Loading...'),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget popupMenuButton(int index) {
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
                value: "assign",
                child: Text(
                  "Assign",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              ),
            ],
        onSelected: (selectedItem) async {
          switch (selectedItem) {
            case "assign":
              {
                _assign(myWorks[index].handlers,
                    myWorks[index].category + "-" + myWorks[index].id);
              }
              break;
          }
        });
  }

  void _viewQR(int index) async {
    if (connection == true) {
      if (myWorks[index].offLine == false) {
        if (myWorks[index].qr == "") {
          _toast("No QR generated for this link");
        } else {
          FlutterWebBrowser.openWebPage(
            url: myWorks[index].qr,
          );
        }
      } else {
        var path = location +
            "/" +
            myWorks[index].category +
            myWorks[index].id +
            "/VVIN.jpg";
        if (File(path).existsSync() == true) {
          await OpenFile.open(path);
        } else {
          _toast("This offline QR still in downloading or not available");
        }
      }
    } else {
      var path = location +
          "/" +
          offlineLink[index]['type'] +
          offlineLink[index]['linkid'] +
          "/VVIN.jpg";
      if (File(path).existsSync() == true) {
        await OpenFile.open(path);
      } else {
        _toast("This offline QR is not available.");
      }
    }
  }

  void _whatsappForward(String url) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      WhatsappForward whatsapp = WhatsappForward(
        url: url,
        userID: userID,
        userType: userType,
        companyID: companyID,
        level: level,
        vtagList: vtagList,
      );
      Navigator.push(
        context,
        AwesomePageRoute(
          transitionDuration: Duration(milliseconds: 600),
          exitPage: widget,
          enterPage: WhatsAppForward(whatsappForward: whatsapp),
          transition: StackTransition(),
        ),
      );
    } else {
      _toast("No Internet Connection");
    }
  }

  void _assign(List handlerList, String id) async {
    String handlersOld = "";
    for (int j = 0; j < handlerList.length; j++) {
      for (int i = 0; i < handlerAllList1.length; i++) {
        if (handlerList[j] == handlerAllList1[i].handler) {
          if (handlersOld == "") {
            handlersOld = handlerAllList1[i].handlerID;
          } else {
            handlersOld = handlersOld + "," + handlerAllList1[i].handlerID;
          }
        }
      }
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      showModalBottomSheet(
          isDismissible: false,
          context: context,
          builder: (context) {
            return StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.5,
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
                              ScreenUtil().setHeight(10),
                            ),
                            child: Text(
                              "Assign",
                              style: TextStyle(
                                  fontSize: font14,
                                  fontWeight: FontWeight.bold),
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
                                      "Done",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: font14,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    _assignDone(handlersOld, handlerList, id);
                                  },
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(ScreenUtil().setHeight(10)),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: ScreenUtil().setHeight(10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                    "Assign handler for the leads generated by this work",
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: font13)),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(5),
                          ),
                          Container(
                            padding: EdgeInsets.all(0.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: Colors.grey.shade400,
                                  style: BorderStyle.solid),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.fromLTRB(
                                        ScreenUtil().setHeight(10), 0, 0, 0),
                                    child: (handlerList.length == 0)
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                "Handler",
                                                style: TextStyle(
                                                    fontSize: font13,
                                                    color: Colors.grey),
                                              )
                                            ],
                                          )
                                        : Wrap(
                                            direction: Axis.horizontal,
                                            alignment: WrapAlignment.start,
                                            children: _handler(
                                                setModalState, handlerList),
                                          ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _selectHandler(handlerList, id);
                                  },
                                  child: Container(
                                    height: ScreenUtil().setHeight(60),
                                    width: ScreenUtil().setHeight(60),
                                    child: Center(
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                              ],
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
    } else {
      _toast("This feature need Internet connection");
    }
  }

  List<Widget> _handler(StateSetter setModalState, List handlerList) {
    List widgetList = <Widget>[];
    for (int i = 0; i < handlerList.length; i++) {
      Widget widget1 = InkWell(
        onTap: () {
          setModalState(() {
            handlerList.removeAt(i);
          });
        },
        child: Container(
          width: ScreenUtil().setWidth((handlerList[i].length * 18) + 62.8),
          margin: EdgeInsets.all(ScreenUtil().setHeight(5)),
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
                handlerList[i],
                style: TextStyle(
                  color: Colors.black,
                  fontSize: font13,
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
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  void _assignDone(String handlersOld, List handlerList, String id) async {
    String handlers = "";
    for (int j = 0; j < handlerList.length; j++) {
      for (int i = 0; i < handlerAllList1.length; i++) {
        if (handlerList[j] == handlerAllList1[i].handler) {
          if (handlers == "") {
            handlers = handlerAllList1[i].handlerID;
          } else {
            handlers = handlers + "," + handlerAllList1[i].handlerID;
          }
        }
      }
    }
    Navigator.of(context).pop();
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(assignURL, body: {
        "companyID": companyID,
        "userID": userID,
        "level": level,
        "user_type": userType,
        "id": id,
        "handler": handlers,
        "type": 'myworks',
      }).then((res) async {
        if (res.body == "success") {
          _toast("Handler updated");
        } else {
          _toast("Something's wrong");
        }
      }).catchError((err) {
        print("Assign error: " + (err).toString());
      });
    } else {
      _toast("No Internet, data can't update");
    }
  }

  void _selectHandler(List handlerList, String id) {
    String handler = "";
    Navigator.of(context).pop();
    allHandler.clear();
    for (var data in handlerAllList) {
      allHandler.add(data.handler);
    }

    for (int i = 0; i < handlerList.length; i++) {
      for (int j = 0; j < handlerAllList.length; j++) {
        if (handlerList[i] == handlerAllList[j].handler) {
          allHandler.removeAt(j);
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
              height: MediaQuery.of(context).size.height * 0.5,
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
                            if (handler == "-" || handler == "") {
                            } else {
                              if (this.mounted) {
                                setState(() {
                                  handlerList.add(handler);
                                });
                              }
                            }
                            Navigator.pop(context);
                            _assign(handlerList, id);
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
                          FixedExtentScrollController(initialItem: 0),
                      onSelectedItemChanged: (int index) {
                        handler = allHandler[index];
                      },
                      children: _allHandlers(allHandler),
                    ),
                  ))
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _allHandlers(List allHandler) {
    List widgetList = <Widget>[];
    for (int i = 0; i < allHandler.length; i++) {
      Widget widget1 = Text(
        allHandler[i],
        style: TextStyle(
          fontSize: font14,
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  Future<bool> _onBackPressAppBar() async {
    YYAlertDialogWithScaleIn();
    return Future.value(false);
  }

  void _myWorkfilter() {
    if (status == true && vtagStatus == true) {
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
                              ScreenUtil().setHeight(10),
                            ),
                            child: Text(
                              "Filter",
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
                              padding: EdgeInsets.all(10),
                              child: Text(
                                "Done",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: font14,
                                ),
                              ),
                            ),
                            onTap: _done,
                          )
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        physics: ScrollPhysics(),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                              ScreenUtil().setHeight(10),
                              ScreenUtil().setHeight(20),
                              ScreenUtil().setHeight(10),
                              ScreenUtil().setHeight(10)),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "By Category",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(10),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Flexible(
                                    child: Wrap(
                                      children: <Widget>[
                                        Container(
                                          width: ScreenUtil().setWidth(115),
                                          height: ScreenUtil().setHeight(70),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10)),
                                          decoration: BoxDecoration(
                                            color: (category == "all")
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          child: OutlineButton(
                                            onPressed: () {
                                              setModalState(() {
                                                category = "all";
                                              });
                                            },
                                            child: Text(
                                              'All',
                                              style: TextStyle(
                                                fontSize: font10,
                                                color: (category == "all")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setWidth(155),
                                          height: ScreenUtil().setHeight(70),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10)),
                                          decoration: BoxDecoration(
                                            color: (category == "vcard")
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          child: OutlineButton(
                                            onPressed: () {
                                              setModalState(() {
                                                category = "vcard";
                                              });
                                            },
                                            child: Text(
                                              'VCard',
                                              style: TextStyle(
                                                fontSize: font10,
                                                color: (category == "vcard")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setWidth(145),
                                          height: ScreenUtil().setHeight(70),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10)),
                                          decoration: BoxDecoration(
                                            color: (category == "vflex")
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          child: OutlineButton(
                                            onPressed: () {
                                              setModalState(() {
                                                category = "vflex";
                                              });
                                            },
                                            child: Text(
                                              'VFlex',
                                              style: TextStyle(
                                                fontSize: font10,
                                                color: (category == "vflex")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setHeight(215),
                                          height: ScreenUtil().setHeight(70),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10),
                                              0),
                                          decoration: BoxDecoration(
                                            color: (category == "vcatalogue")
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          child: OutlineButton(
                                            onPressed: () {
                                              setModalState(() {
                                                category = "vcatalogue";
                                              });
                                            },
                                            child: Text(
                                              'VCatalogue',
                                              style: TextStyle(
                                                fontSize: font10,
                                                color:
                                                    (category == "vcatalogue")
                                                        ? Colors.white
                                                        : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setHeight(160),
                                          height: ScreenUtil().setHeight(70),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10),
                                              0),
                                          decoration: BoxDecoration(
                                            color: (category == "vbrochure")
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          child: OutlineButton(
                                            onPressed: () {
                                              setModalState(() {
                                                category = "vbrochure";
                                              });
                                            },
                                            child: Text(
                                              'VBrochure',
                                              style: TextStyle(
                                                fontSize: font10,
                                                color: (category == "vbrochure")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setHeight(160),
                                          height: ScreenUtil().setHeight(70),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setHeight(10),
                                              0),
                                          decoration: BoxDecoration(
                                            color: (category == "vform")
                                                ? Colors.blue
                                                : Colors.white,
                                          ),
                                          child: OutlineButton(
                                            onPressed: () {
                                              setModalState(() {
                                                category = "vform";
                                              });
                                            },
                                            child: Text(
                                              'VForm',
                                              style: TextStyle(
                                                fontSize: font10,
                                                color: (category == "vform")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
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
                  ],
                ),
              );
            });
          });
    } else {
      _toast("Please wait for laoding");
    }
  }

  Future<void> _done() async {
    if (this.mounted) {
      setState(() {
        nodata = false;
      });
    }
    switch (category) {
      case "all":
        {
          Navigator.pop(context);
          myWorks.clear();
          if (connection == true) {
            for (int i = 0; i < myWorks1.length; i++) {
              if (search == "") {
                Myworks mywork = Myworks(
                  date: myWorks1[i].date,
                  title: myWorks1[i].title,
                  url: myWorks1[i].url,
                  urlName: myWorks1[i].urlName,
                  link: myWorks1[i].link,
                  category: myWorks1[i].category,
                  qr: myWorks1[i].qr,
                  id: myWorks1[i].id,
                  handlers: myWorks1[i].handlers,
                  offLine: false,
                );
                myWorks.add(mywork);
              } else {
                if (myWorks1[i]
                    .title
                    .toLowerCase()
                    .contains(search.toLowerCase())) {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
            }
            if (myWorks.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = true;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            }
          } else {
            if (search == "") {
              offlineLink = await db.rawQuery("SELECT * FROM myworks");
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE title LIKE '%" + search + "%'");
            }
            if (offlineLink.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = false;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
        }
        break;

      case "vcard":
        {
          Navigator.pop(context);
          myWorks.clear();
          if (connection == true) {
            for (int i = 0; i < myWorks1.length; i++) {
              if (search == "" && myWorks1[i].category == "VCard") {
                Myworks mywork = Myworks(
                    date: myWorks1[i].date,
                    title: myWorks1[i].title,
                    url: myWorks1[i].url,
                    urlName: myWorks1[i].urlName,
                    link: myWorks1[i].link,
                    category: myWorks1[i].category,
                    qr: myWorks1[i].qr,
                    id: myWorks1[i].id,
                    handlers: myWorks1[i].handlers,
                    offLine: false);
                myWorks.add(mywork);
              } else {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(search.toLowerCase()) &&
                    myWorks1[i].category == "VCard") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
            }
            if (myWorks.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = true;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            }
          } else {
            if (search == "") {
              offlineLink = await db
                  .rawQuery("SELECT * FROM myworks WHERE type = 'VCard'");
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VCard' AND title LIKE '%" +
                      search +
                      "%'");
            }
            if (offlineLink.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = false;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
        }
        break;

      case "vflex":
        {
          Navigator.pop(context);
          myWorks.clear();
          if (connection == true) {
            for (int i = 0; i < myWorks1.length; i++) {
              if (search == "" && myWorks1[i].category == "VFlex") {
                Myworks mywork = Myworks(
                    date: myWorks1[i].date,
                    title: myWorks1[i].title,
                    url: myWorks1[i].url,
                    urlName: myWorks1[i].urlName,
                    link: myWorks1[i].link,
                    category: myWorks1[i].category,
                    qr: myWorks1[i].qr,
                    id: myWorks1[i].id,
                    handlers: myWorks1[i].handlers,
                    offLine: false);
                myWorks.add(mywork);
              } else {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(search.toLowerCase()) &&
                    myWorks1[i].category == "VFlex") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
            }
            if (myWorks.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = true;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            }
          } else {
            if (search == "") {
              offlineLink = await db
                  .rawQuery("SELECT * FROM myworks WHERE type = 'VFlex'");
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VFlex' AND title LIKE '%" +
                      search +
                      "%'");
            }
            if (offlineLink.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = false;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
        }
        break;

      case "vcatalogue":
        {
          Navigator.pop(context);
          myWorks.clear();
          if (connection == true) {
            for (int i = 0; i < myWorks1.length; i++) {
              if (search == "" && myWorks1[i].category == "VCatalogue") {
                Myworks mywork = Myworks(
                    date: myWorks1[i].date,
                    title: myWorks1[i].title,
                    url: myWorks1[i].url,
                    urlName: myWorks1[i].urlName,
                    link: myWorks1[i].link,
                    category: myWorks1[i].category,
                    qr: myWorks1[i].qr,
                    id: myWorks1[i].id,
                    handlers: myWorks1[i].handlers,
                    offLine: false);
                myWorks.add(mywork);
              } else {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(search.toLowerCase()) &&
                    myWorks1[i].category == "VCatalogue") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
            }
            if (myWorks.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = true;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            }
          } else {
            if (search == "") {
              offlineLink = await db
                  .rawQuery("SELECT * FROM myworks WHERE type = 'VCatalogue'");
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VCatalogue' AND title LIKE '%" +
                      search +
                      "%'");
            }
            if (offlineLink.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = false;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
        }
        break;

      case "vbrochure":
        {
          Navigator.pop(context);
          myWorks.clear();
          if (connection == true) {
            for (int i = 0; i < myWorks1.length; i++) {
              if (search == "" && myWorks1[i].category == "VBrochure") {
                Myworks mywork = Myworks(
                    date: myWorks1[i].date,
                    title: myWorks1[i].title,
                    url: myWorks1[i].url,
                    urlName: myWorks1[i].urlName,
                    link: myWorks1[i].link,
                    category: myWorks1[i].category,
                    qr: myWorks1[i].qr,
                    id: myWorks1[i].id,
                    handlers: myWorks1[i].handlers,
                    offLine: false);
                myWorks.add(mywork);
              } else {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(search.toLowerCase()) &&
                    myWorks1[i].category == "VBrochure") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
            }
            if (myWorks.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = true;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            }
          } else {
            if (search == "") {
              offlineLink = await db
                  .rawQuery("SELECT * FROM myworks WHERE type = 'VBrochure'");
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VBrochure' AND title LIKE '%" +
                      search +
                      "%'");
            }
            if (offlineLink.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = false;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
        }
        break;

      case "vform":
        {
          Navigator.pop(context);
          myWorks.clear();
          if (connection == true) {
            for (int i = 0; i < myWorks1.length; i++) {
              if (search == "" && myWorks1[i].category == "VForm") {
                Myworks mywork = Myworks(
                    date: myWorks1[i].date,
                    title: myWorks1[i].title,
                    url: myWorks1[i].url,
                    urlName: myWorks1[i].urlName,
                    link: myWorks1[i].link,
                    category: myWorks1[i].category,
                    qr: myWorks1[i].qr,
                    id: myWorks1[i].id,
                    handlers: myWorks1[i].handlers,
                    offLine: false);
                myWorks.add(mywork);
              } else {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(search.toLowerCase()) &&
                    myWorks1[i].category == "VForm") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
            }
            if (myWorks.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = true;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            }
          } else {
            if (search == "") {
              offlineLink = await db
                  .rawQuery("SELECT * FROM myworks WHERE type = 'VForm'");
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VForm' AND title LIKE '%" +
                      search +
                      "%'");
            }
            if (offlineLink.length == 0) {
              if (this.mounted) {
                setState(() {
                  connection = false;
                  nodata = true;
                });
              }
            } else {
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
        }
        break;
    }
  }

  Future<void> _visitURL(int index) async {
    if (connection == true) {
      if (myWorks[index].offLine == false) {
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          FlutterWebBrowser.openWebPage(
            url: myWorks[index].link,
          );
        } else {
          var path = location +
              "/" +
              myWorks[index].category +
              myWorks[index].id +
              "/VVIN.html";
          if (File(path).existsSync() == true) {
            await OpenFile.open(path);
          } else {
            _toast("This offline link still in downloading");
          }
        }
      } else {
        var path = location +
            "/" +
            myWorks[index].category +
            myWorks[index].id +
            "/VVIN.html";
        if (File(path).existsSync() == true) {
          await OpenFile.open(path);
        } else {
          _toast("This offline link still in downloading");
        }
      }
    } else {
      var path = location +
          "/" +
          offlineLink[index]['type'] +
          offlineLink[index]['linkid'] +
          "/VVIN.html";
      if (File(path).existsSync() == true) {
        await OpenFile.open(path);
      } else {
        _toast(
            "This offline link not in your device, please enter the page again in online mode to complete the offline link download.");
      }
    }
  }

  Future<void> setData() async {
    Database db = await MyWorksDB.instance.database;
    await db.rawInsert('DELETE FROM myworks WHERE id > 0');
    for (int index = 0; index < myWorks.length; index++) {
      await db.rawInsert(
          'INSERT INTO myworks (date, title, link, type, linkid) VALUES("' +
              myWorks[index].date +
              '","' +
              myWorks[index].title +
              '","' +
              myWorks[index].link +
              '","' +
              myWorks[index].category +
              '","' +
              myWorks[index].id +
              '")');
    }
    // endTime = DateTime.now().millisecondsSinceEpoch;
    // int result = endTime - startTime;
    // print("MyWork Loading Time: " + result.toString());
  }

  Future<void> checkConnection() async {
    startTime = DateTime.now().millisecondsSinceEpoch;
    final _devicePath = await getApplicationDocumentsDirectory();
    location = _devicePath.path.toString();
    db = await MyWorksDB.instance.database;
    offlineLink = await db.query(MyWorksDB.table);
    prefs = await SharedPreferences.getInstance();
    if (prefs.getString("noti") != null) {
      if (this.mounted) {
        setState(() {
          totalNotification = prefs.getString("noti");
        });
      }
      FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
    }
    totalQR = int.parse(prefs.getString('totalQR') ?? "0");
    totalLink = int.parse(prefs.getString('totalLink') ?? "0");
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      companyID = prefs.getString('companyID');
      userID = prefs.getString('userID');
      level = prefs.getString('level');
      userType = prefs.getString('user_type');
      myWorks.clear();
      myWorks1.clear();
      getLink();
      getVTag();
      getHandlerList();
      notification();
      if (prefs.getString("reminder") == null) {
        getReminder();
      }
    } else {
      initialize();
      _toast("No Internet, the data shown is not up to date");
    }
  }

  void getReminder() {
    http.post(urlGetReminder, body: {
      "companyID": companyID,
      "userID": userID,
      "level": level,
      "user_type": userType,
    }).then((res) async {
      var jsonData = json.decode(res.body);
      if (res.body != 'nodata') {
        Database db = await ReminderDB.instance.database;
        for (var data in jsonData) {
          await db.rawInsert(
              'INSERT INTO reminder (datetime, name, phone, remark, status, time) VALUES("' +
                  data["datetime"] +
                  '","' +
                  data["name"] +
                  '","' +
                  data["phone"] +
                  '","' +
                  data["remark"] +
                  '","' +
                  data["status"] +
                  '","' +
                  data["time"] +
                  '")');
        }
        prefs.setString("reminder", '1');
      }
    }).catchError((err) {
      _toast("Get reminder error" + err.toString());
      print("Get reminder error: " + (err).toString());
    });
  }

  void notification() {
    http.post(urlNoti, body: {
      "userID": userID,
      "companyID": companyID,
      "level": level,
      "user_type": userType,
    }).then((res) {
      if (this.mounted) {
        setState(() {
          totalNotification = res.body;
        });
      }
      FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
      prefs.setString('noti', res.body);
    }).catchError((err) {
      print("Notification error: " + err.toString());
    });
  }

  void getHandlerList() {
    companyID = companyID;
    userID = userID;
    level = level;
    userType = userType;
    http.post(urlHandler, body: {
      "companyID": companyID,
      "userID": userID,
      "user_type": userType,
      "level": level,
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          Handler handler = Handler(
            handler: data["handler"],
            position: data["position"],
            handlerID: data["handlerID"],
          );
          handlerAllList.add(handler);
          handlerAllList1.add(handler);
        }
      } else {
        _toast("Something wrong, please contact VVIN IT help desk");
      }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Setup Data error: " + (err).toString());
    });
  }

  void getVTag() {
    http.post(urlVTag, body: {
      "companyID": companyID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "phone_number": "all",
    }).then((res) {
      // print("VTag body: " + res.body);
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        vtagList = jsonData;
        vtagList.insert(0, "-");
      }
      if (this.mounted) {
        setState(() {
          vtagStatus = true;
        });
      }
    }).catchError((err) {
      print("Get Link error: " + (err).toString());
    });
  }

  void getLink() {
    http.post(urlMyWorks, body: {
      "companyID": companyID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "count": myWorks.length.toString(),
    }).then((res) {
      // print("MyWorks body: " + res.body);
      if (res.body == "nodata") {
        nodata = true;
        status = true;
        // _toast("No Data");
      } else {
        var jsonData = json.decode(res.body);
        if (total == 0) {
          if (this.mounted) {
            setState(() {
              total = int.parse(jsonData[0]);
            });
          }
          for (int i = 1; i < jsonData.length; i++) {
            Myworks mywork = Myworks(
                date: jsonData[i]['date'],
                title: jsonData[i]['title'],
                url: jsonData[i]['url'],
                urlName: jsonData[i]['urlName'],
                link: jsonData[i]['link'],
                category: jsonData[i]['category'],
                qr: jsonData[i]['qr'],
                id: jsonData[i]['id'],
                handlers: jsonData[i]['handler'],
                offLine: false);
            myWorks.add(mywork);
            myWorks1.add(mywork);
          }
          if (myWorks.length != total) {
            getLink();
          } else {
            if (this.mounted) {
              setState(() {
                status = true;
                connection = true;
              });
            }
            _save();
          }
        } else {
          for (int i = 0; i < jsonData.length; i++) {
            Myworks mywork = Myworks(
                date: jsonData[i]['date'],
                title: jsonData[i]['title'],
                url: jsonData[i]['url'],
                urlName: jsonData[i]['urlName'],
                link: jsonData[i]['link'],
                category: jsonData[i]['category'],
                qr: jsonData[i]['qr'],
                id: jsonData[i]['id'],
                handlers: jsonData[i]['handlers'],
                offLine: false);
            myWorks.add(mywork);
            myWorks1.add(mywork);
          }
          if (myWorks.length != total) {
            getLink();
          } else {
            if (this.mounted) {
              setState(() {
                status = true;
                connection = true;
              });
            }
            _save();
          }
        }
      }
    }).catchError((err) {
      print("Get Link error: " + (err).toString());
    });
  }

  Future<void> _save() async {
    if (offlineLink.length == 0) {
      _download();
      _downloadImage();
      setData();
    } else {
      int totalQRcount = 0;
      int totalLinkcount = 0;
      for (int i = 0; i < myWorks.length; i++) {
        var imagePath =
            location + "/" + myWorks[i].category + myWorks[i].id + "/VVIN.jpg";
        var linkPath =
            location + "/" + myWorks[i].category + myWorks[i].id + "/VVIN.html";

        if (File(imagePath).existsSync() == true) {
          totalQRcount += 1;
          if (totalQRcount > totalQR && totalQRcount < myWorks.length) {
            if (this.mounted) {
              setState(() {
                totalQR = totalQRcount;
              });
            }
            await prefs.setString('totalQR', totalQRcount.toString());
          }
        } else {
          _downloadImage1(
              myWorks[i].qr, myWorks[i].category + myWorks[i].id, "VVIN", i);
        }

        if (File(linkPath).existsSync() == true) {
          totalLinkcount += 1;
          if (totalLinkcount > totalLink && totalLinkcount < myWorks.length) {
            if (this.mounted) {
              setState(() {
                totalLink = totalLinkcount;
              });
            }
            await prefs.setString('totalLink', totalLinkcount.toString());
          }
        } else {
          _download1(
              myWorks[i].link, myWorks[i].category + myWorks[i].id, "VVIN", i);
        }

        for (int j = 0; j < offlineLink.length; j++) {
          if (myWorks[i].category + myWorks[i].id ==
                  offlineLink[j]['type'] + offlineLink[j]['linkid'] &&
              myWorks[i].date != offlineLink[j]['date']) {
            String linkLocation = location +
                "/" +
                offlineLink[i]['type'] +
                offlineLink[i]['linkid'] +
                "/VVIN.html";
            if (File(linkLocation).existsSync() == true) {
              final dir = Directory(linkLocation);
              dir.deleteSync(recursive: true);
              _editDownload1(myWorks[i].link,
                  myWorks[i].category + myWorks[i].id, "VVIN", i);
            }
            String imageLocation = location +
                "/" +
                offlineLink[i]['type'] +
                offlineLink[i]['linkid'] +
                "/VVIN.jpg";
            if (File(imageLocation).existsSync() == true) {
              final dir1 = Directory(imageLocation);
              dir1.deleteSync(recursive: true);
              _editDownloadImage1(myWorks[i].qr,
                  myWorks[i].category + myWorks[i].id, "VVIN", i);
            }
          }
        }
      }
      setData();
    }
  }

  Future<void> initialize() async {
    if (offlineLink.length == 0) {
      if (this.mounted) {
        setState(() {
          nodata = true;
          status = true;
          vtagStatus = true;
        });
      }
    } else {
      if (this.mounted) {
        setState(() {
          status = true;
          vtagStatus = true;
        });
      }
    }
  }

  Future<void> _search(String value) async {
    if (status == false) {
      _toast("Please wait for loading");
    } else {
      if (this.mounted) {
        setState(() {
          search = value;
        });
      }
      switch (category) {
        case "all":
          {
            myWorks.clear();
            if (connection == true) {
              for (int i = 0; i < myWorks1.length; i++) {
                if (myWorks1[i]
                    .title
                    .toLowerCase()
                    .contains(value.toLowerCase())) {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE title LIKE '%" + value + "%'");
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
          break;

        case "vcard":
          {
            myWorks.clear();
            if (connection == true) {
              for (int i = 0; i < myWorks1.length; i++) {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(value.toLowerCase()) &&
                    myWorks1[i].category == "VCard") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VCard' AND title LIKE '%" +
                      value +
                      "%'");
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
          break;

        case "vflex":
          {
            myWorks.clear();
            if (connection == true) {
              for (int i = 0; i < myWorks1.length; i++) {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(value.toLowerCase()) &&
                    myWorks1[i].category == "VFlex") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VFlex' AND title LIKE '%" +
                      value +
                      "%'");
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
          break;

        case "vcatalogue":
          {
            myWorks.clear();
            if (connection == true) {
              for (int i = 0; i < myWorks1.length; i++) {
                if (myWorks1[i]
                        .title
                        .toLowerCase()
                        .contains(value.toLowerCase()) &&
                    myWorks1[i].category == "VCatalogue") {
                  Myworks mywork = Myworks(
                      date: myWorks1[i].date,
                      title: myWorks1[i].title,
                      url: myWorks1[i].url,
                      urlName: myWorks1[i].urlName,
                      link: myWorks1[i].link,
                      category: myWorks1[i].category,
                      qr: myWorks1[i].qr,
                      id: myWorks1[i].id,
                      handlers: myWorks1[i].handlers,
                      offLine: false);
                  myWorks.add(mywork);
                }
              }
              if (this.mounted) {
                setState(() {
                  connection = true;
                });
              }
            } else {
              offlineLink = await db.rawQuery(
                  "SELECT * FROM myworks WHERE type = 'VCatalogue' AND title LIKE '%" +
                      value +
                      "%'");
              if (this.mounted) {
                setState(() {
                  connection = false;
                });
              }
            }
          }
          break;
      }
    }
  }

  String _dateFormat(String fullDate) {
    String result, date, month, year;
    date = fullDate.substring(8, 10);
    month = fullDate.substring(5, 7);
    year = fullDate.substring(0, 4);
    result = date + "/" + month + "/" + year;
    return result;
  }

  Future<String> get _localDevicePath async {
    final _devicePath = await getApplicationDocumentsDirectory();
    return _devicePath.path;
  }

  Future _download() async {
    for (int i = 0; i < myWorks.length; i++) {
      final _response = await http.get(myWorks[i].link + "/hide");
      if (_response.statusCode == 200) {
        final _file = await _localFile(
            path: myWorks[i].category + myWorks[i].id, name: "VVIN");
        final _saveFile = await _file.writeAsBytes(_response.bodyBytes);
        if (this.mounted) {
          setState(() {
            filePath = _saveFile.path;
            totalLink += 1;
          });
        }
        await prefs.setString('totalLink', totalLink.toString());
      }
    }
  }

  Future<File> _localFile({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.html");
  }

  Future _download1(String url, String path, String name, int index) async {
    final _response = await http.get(url + "/hide");
    if (_response.statusCode == 200) {
      final _file = await _localFile1(path: path, name: name);
      final _saveFile = await _file.writeAsBytes(_response.bodyBytes);
      if (this.mounted) {
        setState(() {
          filePath = _saveFile.path;
        });
      }
      if (totalLink < myWorks.length) {
        if (this.mounted) {
          setState(() {
            totalLink += 1;
          });
        }
        await prefs.setString('totalLink', totalLink.toString());
      }
    }
  }

  Future<File> _localFile1({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.html");
  }

  Future _editDownload1(String url, String path, String name, int index) async {
    final _response = await http.get(url + "/hide");
    if (_response.statusCode == 200) {
      final _file = await _editLocalFile1(path: path, name: name);
      final _saveFile = await _file.writeAsBytes(_response.bodyBytes);
      if (this.mounted) {
        setState(() {
          filePath = _saveFile.path;
        });
      }
    }
  }

  Future<File> _editLocalFile1({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.html");
  }

  Future _downloadImage() async {
    for (int i = 0; i < myWorks.length; i++) {
      if (myWorks[i].qr != "") {
        final _response = await http.get(myWorks[i].qr);
        if (_response.statusCode == 200) {
          final _file = await _localImage(
              path: myWorks[i].category + myWorks[i].id, name: "VVIN");
          final _saveFile = await _file.writeAsBytes(_response.bodyBytes);
          if (this.mounted) {
            setState(() {
              filePath = _saveFile.path;
              totalQR += 1;
            });
          }
          await prefs.setString('totalQR', totalQR.toString());
        } else {
          print("Image error at: " + i.toString());
        }
      }
    }
  }

  Future<File> _localImage({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.jpg");
  }

  Future _downloadImage1(
      String url, String path, String name, int index) async {
    if (url != "") {
      final _response = await http.get(url);
      if (_response.statusCode == 200) {
        final _file = await _localImage1(path: path, name: name);
        final _saveFile = await _file.writeAsBytes(_response.bodyBytes);
        if (this.mounted) {
          setState(() {
            filePath = _saveFile.path;
          });
        }
        if (totalQR < myWorks.length) {
          if (this.mounted) {
            setState(() {
              totalQR += 1;
            });
          }
          await prefs.setString('totalQR', totalQR.toString());
        }
      } else {
        print("Image error at: " + index.toString());
      }
    }
  }

  Future<File> _localImage1({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.jpg");
  }

  Future _editDownloadImage1(
      String url, String path, String name, int index) async {
    final _response = await http.get(url);
    if (_response.statusCode == 200) {
      final _file = await _editLocalImage1(path: path, name: name);
      final _saveFile = await _file.writeAsBytes(_response.bodyBytes);
      if (this.mounted) {
        setState(() {
          filePath = _saveFile.path;
        });
      }
    } else {
      print("Image error at: " + index.toString());
    }
  }

  Future<File> _editLocalImage1({String path, String name}) async {
    String _path = await _localDevicePath;
    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.jpg");
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
