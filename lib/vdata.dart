import 'dart:async';
import 'dart:convert';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:badges/badges.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:menu_button/menu_button.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/vdataStatus.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/data.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/more.dart';
import 'package:vvin/myworks.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vDataDB.dart';
import 'package:vvin/vanalytics.dart';
import 'package:vvin/vprofile.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vvin/whatsappForward.dart';

class VData extends StatefulWidget {
  const VData({Key key}) : super(key: key);

  @override
  _VDataState createState() => _VDataState();
}

enum UniLinksType { string, uri }

class _VDataState extends State<VData> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dialogSearchController = TextEditingController();
  SharedPreferences prefs;
  double _scaleFactor = 1.0;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  bool connection,
      nodata,
      link,
      vData,
      vDataReady,
      executive,
      more,
      vtagStatus,
      branch,
      readyNew,
      readyContacting,
      readyContacted,
      readyQualified,
      readyConverted,
      readyFollowUp,
      readyUnqualified,
      readyBadInfo,
      readyNoResponse,
      nodataNew,
      nodataContacting,
      nodataContacted,
      nodataQualified,
      nodataConverted,
      nodataFollowUp,
      nodataUnqualified,
      nodataBadInfo,
      nodataNoResponse,
      myworksReady,
      vTagData;
  List<Links> linksID = [];
  List<VDataDetails> vDataDetails = [];
  List<VDataDetails> vDataNew = [];
  List<VDataDetails> vDataContacting = [];
  List<VDataDetails> vDataContacted = [];
  List<VDataDetails> vDataQualified = [];
  List<VDataDetails> vDataConverted = [];
  List<VDataDetails> vDataFollowUp = [];
  List<VDataDetails> vDataUnqualified = [];
  List<VDataDetails> vDataBadInfo = [];
  List<VDataDetails> vDataNoResponse = [];
  List<VDataDetails> vDataOffline = [];
  List<Myworks> myWorks = [];
  List<Myworks> myWorks1 = [];
  List<Map> offlineVData;
  List<Handler> handlerList = [];
  List<Branch> branchesList = [];
  List<String> executiveList = [];
  List<String> links = [];
  List<RadioItem> radioItems = [];
  List vtagList = [];
  List vTag;
  Database vdataDB;
  VDataInfo vDataInfoNew,
      vDataInfoContacting,
      vDataInfoContacted,
      vDataInfoQualified,
      vDataInfoConverted,
      vDataInfoFollowUp,
      vDataInfoUnqualified,
      vDataInfoBadInfo,
      vDataInfoNoResponse;
  String companyID,
      branchID,
      userID,
      _byLink,
      _byVTag,
      _byStatus,
      _byExecutive,
      _byBranch,
      link_id,
      type,
      channel,
      apps,
      level,
      userType,
      search,
      startDate,
      endDate,
      minimumDate,
      maximumDate,
      handlerStatus,
      now,
      totalNotification;
  int tap, total, startTime, endTime, currentTabIndex, totalLink;
  DateTime _startDate,
      _endDate,
      _startDatePicker,
      _endDatePicker,
      startDateTime,
      endDateTime;
  String urlNoti = ip + "notiTotalNumber.php";
  String urlVData = ip + "vdata.php";
  String urlChangeStatus = ip + "vdataChangeStatus.php";
  String urlLinks = ip + "links.php";
  String urlHandler = ip + "getHandler.php";
  String urlVTag = ip + "vtag.php";
  String urlBranches = ip + "branch.php";
  String urlMyWorks = ip + "myWorks2.php";
  List<String> data = [
    "New",
    "Contacting",
    "Contacted",
    "Qualified",
    "Converted",
    "Follow-up",
    "Unqualified",
    "Bad Information",
    "No Response"
  ];
  List<String> status = [
    "All Status",
    "New",
    "Contacting",
    "Contacted",
    "Qualified",
    "Converted",
    "Follow-up",
    "Unqualified",
    "Bad Information",
    "No Response"
  ];
  List<String> appsAll = [
    "All",
    "VBot",
    "VBrochure",
    "VCard",
    "VCatalogue",
    "VFlex",
    "VHome",
    "VForm",
  ];

  var radioSelections = [
    RadioItem(
      padding: EdgeInsets.only(left: ScreenUtil().setHeight(12)),
      text: "WhatApps",
      color: Colors.black,
      fontSize: font16,
    ),
    RadioItem(
      padding: EdgeInsets.only(left: ScreenUtil().setHeight(12)),
      text: "WhatApps Forward Link",
      color: Colors.black,
      fontSize: font16,
    ),
  ];

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    _init();
    totalNotification = "0";
    currentTabIndex = 1;
    totalLink = 0;
    more = true;
    vTagData = myworksReady = readyNew = readyContacting = readyContacted =
        readyQualified = readyConverted = readyFollowUp = readyUnqualified =
            readyBadInfo = readyNoResponse = nodataNew = nodataContacting =
                nodataContacted = nodataQualified = nodataConverted = nodataFollowUp =
                    nodataUnqualified = nodataBadInfo = nodataNoResponse = vDataReady =
                        branch = executive = link = vData = nodata = connection = vtagStatus = false;
    _byLink = "All Links";
    _byVTag = "All VTags";
    _byStatus = "All Status";
    _byExecutive = "All Executives";
    link_id = "All Links";
    type = "all";
    channel = "all";
    apps = "All";
    search = "";
    minimumDate = "2017-12-01";
    checkConnection();
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

  void onTapped(int index) {
    if (index != 1) {
      switch (index) {
        case 0:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: VAnalytics(),
          ));
          break;
        case 2:
          Navigator.of(context).pushReplacement(PageTransition(
            duration: Duration(milliseconds: 1),
            type: PageTransitionType.transferUp,
            child: MyWorks(),
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
  void dispose() {
    if (_sub != null) _sub.cancel();
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
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
                "VData",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: font18,
                    fontWeight: FontWeight.bold),
              )),
        ),
        body: Container(
          padding: EdgeInsets.fromLTRB(0, ScreenUtil().setHeight(10), 0, 0),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      child: Card(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: ScreenUtil().setHeight(20),
                            left: ScreenUtil().setHeight(20),
                          ),
                          height: ScreenUtil().setHeight(75),
                          child: TextField(
                            controller: _searchController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.go,
                            onSubmitted: (value) => _search(value),
                            style: TextStyle(
                              fontSize: font14,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 3),
                              hintText: "Search",
                              suffix: IconButton(
                                iconSize: ScreenUtil().setHeight(40),
                                icon: Icon(Icons.keyboard_hide),
                                onPressed: () {
                                  FocusScope.of(context)
                                      .requestFocus(new FocusNode());
                                },
                              ),
                              suffixIcon: BouncingWidget(
                                scaleFactor: _scaleFactor,
                                onPressed: () {
                                  _search(_searchController.text);
                                },
                                child: Icon(
                                  Icons.search,
                                  size: ScreenUtil().setHeight(50),
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(ScreenUtil().setHeight(10), 0,
                        ScreenUtil().setHeight(0), 0),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: (connection == true) ? _filter : _noInternet,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.all(
                            ScreenUtil().setHeight(18),
                          ),
                          child: Icon(
                            Icons.tune,
                            size: ScreenUtil().setHeight(40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: ScreenUtil().setHeight(5),
              ),
              Container(
                padding:
                    EdgeInsets.fromLTRB(ScreenUtil().setHeight(10), 0, 0, 0),
                child: (total == null)
                    ? Row(
                        children: <Widget>[
                          Text("Total Entries: ",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: font12)),
                          JumpingText('Loading...',
                              style: TextStyle(fontSize: font12)),
                        ],
                      )
                    : Row(
                        children: <Widget>[
                          Text("Total Entries: ",
                              style: TextStyle(
                                  color: Colors.grey, fontSize: font12)),
                          Text(
                              (connection == true)
                                  ? (total == null) ? "" : total.toString()
                                  : (link == true &&
                                          vDataReady == true &&
                                          vtagStatus == true)
                                      ? (offlineVData.length != 0)
                                          ? offlineVData[0]['total']
                                          : "0"
                                      : "data loading...",
                              style: TextStyle(fontSize: font12)),
                        ],
                      ),
              ),
              Flexible(
                child: DefaultTabController(
                  length: 10,
                  child: Scaffold(
                    backgroundColor: Color.fromRGBO(235, 235, 255, 1),
                    appBar: PreferredSize(
                      preferredSize: Size.fromHeight(
                        ScreenUtil().setHeight(88),
                      ),
                      child: AppBar(
                        backgroundColor: Color.fromRGBO(235, 235, 255, 1),
                        elevation: 0,
                        bottom: TabBar(
                          labelPadding: EdgeInsets.fromLTRB(
                              ScreenUtil().setHeight(10),
                              0,
                              ScreenUtil().setHeight(10),
                              0),
                          isScrollable: true,
                          tabs: [
                            Tab(
                              child: Text('All',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('New',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Contacting',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Contacted',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Qualified',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Converted',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Followu  Up',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Unqualified',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('Bad Information',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                            Tab(
                              child: Text('No Response',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: font15)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    body: TabBarView(
                      children: [
                        _all(),
                        (readyNew == false)
                            ? _loading()
                            : (nodataNew == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoNew),
                        (readyContacting == false)
                            ? _loading()
                            : (nodataContacting == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoContacting),
                        (readyContacted == false)
                            ? _loading()
                            : (nodataContacted == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoContacted),
                        (readyQualified == false)
                            ? _loading()
                            : (nodataQualified = true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoQualified),
                        (readyConverted == false)
                            ? _loading()
                            : (nodataConverted == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoConverted),
                        (readyFollowUp == false)
                            ? _loading()
                            : (nodataFollowUp == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoFollowUp),
                        (readyUnqualified == false)
                            ? _loading()
                            : (nodataUnqualified == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoUnqualified),
                        (readyBadInfo == false)
                            ? _loading()
                            : (nodataBadInfo == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoBadInfo),
                        (readyNoResponse == false)
                            ? _loading()
                            : (nodataNoResponse == true)
                                ? _empty()
                                : VDataStatus(vdataInfo: vDataInfoNoResponse),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    Widget widget;
    widget = Center(
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
    );
    return widget;
  }

  Widget _all() {
    Widget widget;
    double remark = MediaQuery.of(context).size.width * 0.30;
    double cWidth = MediaQuery.of(context).size.width * 0.30;
    (link == true && vDataReady == true && vtagStatus == true)
        ? (nodata == true)
            ? widget = _empty()
            : widget = SmartRefresher(
                enablePullDown: (connection == true) ? true : false,
                enablePullUp: (connection == true)
                    ? (vDataDetails.length != total) ? true : false
                    : false,
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
                child: ListView.builder(
                  itemCount: (connection == false)
                      ? offlineVData.length
                      : vDataDetails.length,
                  itemBuilder: (context, int index) {
                    return WidgetANimator(
                      Card(
                        child: Container(
                          child: Column(
                            children: <Widget>[
                              InkWell(
                                onTap: () async {
                                  _redirectVProfile(index);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          width: ScreenUtil().setHeight(2),
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  padding: EdgeInsets.fromLTRB(
                                      ScreenUtil().setHeight(10),
                                      ScreenUtil().setHeight(10),
                                      ScreenUtil().setHeight(10),
                                      0),
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            (connection == true)
                                                ? vDataDetails[index].date
                                                : offlineVData[index]['date'],
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: font12,
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: ScreenUtil().setHeight(10),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            width: cWidth,
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Flexible(
                                                      child: Text(
                                                        (connection == true)
                                                            ? vDataDetails[
                                                                    index]
                                                                .name
                                                            : offlineVData[
                                                                index]['name'],
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: font14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w900),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: ScreenUtil()
                                                      .setHeight(10),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Flexible(
                                                      child: Text(
                                                        (connection == true)
                                                            ? vDataDetails[
                                                                    index]
                                                                .phoneNo
                                                            : offlineVData[
                                                                index]['phone'],
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: font12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              width: ScreenUtil().setWidth(10)),
                                          Container(
                                            width: cWidth,
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Center(
                                                      child: Text(
                                                        "Link",
                                                        style: TextStyle(
                                                            fontSize: font12,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Flexible(
                                                      child: Text(
                                                        (connection == true)
                                                            ? vDataDetails[
                                                                    index]
                                                                .handler
                                                            : offlineVData[
                                                                    index]
                                                                ['handler'],
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: font12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: ScreenUtil().setWidth(10),
                                          ),
                                          Container(
                                            width: remark,
                                            child: Column(
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      "Remark",
                                                      style: TextStyle(
                                                          fontSize: font12,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Flexible(
                                                      child: Text(
                                                        (connection == true)
                                                            ? vDataDetails[
                                                                    index]
                                                                .remark
                                                            : offlineVData[
                                                                    index]
                                                                ['remark'],
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            fontSize: font12,
                                                            color: Colors.grey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: ScreenUtil().setHeight(10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(10),
                              ),
                              Container(
                                padding: EdgeInsets.all(
                                  ScreenUtil().setHeight(8),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        BouncingWidget(
                                          scaleFactor: _scaleFactor,
                                          onPressed: () {
                                            (connection == true)
                                                ? launch("tel:+" +
                                                    vDataDetails[index].phoneNo)
                                                : launch("tel:+" +
                                                    offlineVData[index]
                                                        ['phone']);
                                          },
                                          child: Container(
                                            height: ScreenUtil().setHeight(60),
                                            width: ScreenUtil().setWidth(98),
                                            child: Icon(
                                              Icons.call,
                                              size:
                                                  ScreenUtil().setHeight(32.2),
                                              color: Colors.white,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: ScreenUtil().setHeight(20),
                                        ),
                                        BouncingWidget(
                                          scaleFactor: _scaleFactor,
                                          onPressed: () {
                                            _selection(index);
                                          },
                                          child: Container(
                                            height: ScreenUtil().setHeight(60),
                                            width: ScreenUtil().setWidth(98),
                                            child: Icon(
                                              FontAwesomeIcons.whatsapp,
                                              color: Colors.white,
                                              size:
                                                  ScreenUtil().setHeight(32.2),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Color.fromRGBO(
                                                  37, 211, 102, 1),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: ScreenUtil().setHeight(20),
                                        ),
                                        BouncingWidget(
                                          scaleFactor: _scaleFactor,
                                          onPressed: () {
                                            (vDataDetails[index].email != '')
                                                ? launch('mailto:' +
                                                    vDataDetails[index].email)
                                                : _toast('No email address');
                                          },
                                          child: Container(
                                            height: ScreenUtil().setHeight(60),
                                            width: ScreenUtil().setWidth(98),
                                            child: Icon(
                                              Icons.email,
                                              color: Colors.white,
                                              size:
                                                  ScreenUtil().setHeight(32.2),
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade500,
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    (connection == true)
                                        ? menuButton(
                                            vDataDetails[index].status, index)
                                        : menuButton(
                                            offlineVData[index]['status'],
                                            index),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
        : widget = _loading();
    return widget;
  }

  Widget _loading() {
    Widget widget = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          JumpingText('Loading...'),
          SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          SpinKitRing(
            lineWidth: 3,
            color: Colors.blue,
            size: 30.0,
            duration: Duration(milliseconds: 600),
          ),
        ],
      ),
    );
    return widget;
  }

  Widget menuButton(String status, int index) {
    final Widget button = SizedBox(
      width: ScreenUtil().setWidth(285),
      height: ScreenUtil().setHeight(60),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                status,
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
    return MenuButton(
      child: button,
      items: data,
      scrollPhysics: AlwaysScrollableScrollPhysics(),
      topDivider: true,
      itemBuilder: (value) => Container(
        height: ScreenUtil().setHeight(60),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10),
        child: Text(value, style: TextStyle(fontSize: font12)),
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
          status = value1;
        });
        (connection == true)
            ? setStatus(index, status)
            : _toast(
                "Status can't changed! Please enter the page again in online mode");
      },
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: const BorderRadius.all(Radius.circular(3.0)),
          color: Colors.white),
      onMenuButtonToggle: (isToggle) {},
    );
  }

  void _onRefresh() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (this.mounted) {
        setState(() {
          vData = false;
          link = false;
          total = null;
        });
      }
      if (level == '0' && _byBranch != 'All Branch') {
        for (var branch in branchesList) {
          if (_byBranch == branch.branchName) {
            branchID = branch.branchID;
          }
        }
      }
      http.post(urlVData, body: {
        "companyID": companyID,
        "branchID": branchID,
        "level": level,
        "userID": userID,
        "user_type": userType,
        "type": type,
        "channel": channel,
        "apps": apps,
        "link_id": link_id,
        "status": _byStatus,
        "executive": _byExecutive,
        "vtag": _byVTag,
        "search": search,
        "start_date": minimumDate,
        "end_date": DateTime.now().toString().substring(0, 10),
        "count": "0",
        "offline": "no"
      }).then((res) {
        // print("search body: " + res.body.toString());
        if (res.body == "nodata") {
          if (this.mounted) {
            setState(() {
              vData = true;
              connection = true;
              nodata = true;
              vDataReady = true;
              total = 0;
            });
          }
          if (level == "0" && branch == true) {
            if (this.mounted) {
              setState(() {
                vDataReady = true;
              });
            }
          } else {
            if (this.mounted) {
              setState(() {
                vDataReady = true;
              });
            }
          }
        } else {
          var jsonData = json.decode(res.body);
          if (this.mounted) {
            setState(() {
              total = jsonData[0]['total'];
            });
          }
          vDataDetails.clear();
          for (var data in jsonData) {
            VDataDetails vdata = VDataDetails(
              date: data['date'],
              name: data['name'] ?? "",
              phoneNo: data['phone_number'],
              email: data['email'] ?? '',
              remark: data['remark'] ?? "-",
              status: checkStatus(data['status']),
              type: data['type'],
              app: data['app'],
              channel: data['channel'],
              link: data['link_type'] ?? "" + data['link'],
              handler: data['link'],
            );
            vDataDetails.add(vdata);
          }
          if (this.mounted) {
            setState(() {
              vData = true;
              connection = true;
            });
          }
          if (level == "0" && branch == true) {
            if (this.mounted) {
              setState(() {
                vDataReady = true;
              });
            }
          } else {
            if (this.mounted) {
              setState(() {
                vDataReady = true;
              });
            }
          }
        }
      }).catchError((err) {
        print("Get data error: " + (err).toString());
      });

      http.post(urlLinks, body: {
        "companyID": companyID,
        "branchID": branchID,
        "level": level,
        "userID": userID,
        "user_type": userType,
      }).then((res) {
        links.clear();
        links.add("All Links");
        if (res.body != "nodata") {
          var jsonData = json.decode(res.body);
          Links allLinks = Links(
            link_type: "",
            link: "All Links",
            link_id: "All Links",
            position: 0,
          );
          linksID.add(allLinks);
          for (int i = 0; i < jsonData.length; i++) {
            Links linkID = Links(
              link_type: jsonData[i]['link_type'],
              link: jsonData[i]['link'] ?? "",
              link_id: jsonData[i]['link_id'],
              position: i + 1,
            );
            linksID.add(linkID);
            String link = jsonData[i]['link_type'].toString() +
                jsonData[i]['link'].toString();
            links.add(link);
          }
        }
        _startDate = DateFormat("yyyy-MM-dd").parse(minimumDate);
        _endDate = DateTime.now();
        if (this.mounted) {
          setState(() {
            link = true;
          });
        }
      }).catchError((err) {
        print("Get link error: " + (err).toString());
      });
      _refreshController.refreshCompleted();
    } else {
      _toast("No Internet connection, data can't load");
      _refreshController.refreshCompleted();
    }
  }

  void _onLoading() {
    if (level == '0' && _byBranch != 'All Branch') {
      for (var branch in branchesList) {
        if (_byBranch == branch.branchName) {
          branchID = branch.branchID;
        }
      }
    }
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": _byStatus,
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": _startDate.toString().substring(0, 10),
      "end_date": _endDate.toString().substring(0, 10),
      "count": vDataDetails.length.toString(),
      "offline": "no"
    }).then((res) {
      // print("Get More VData body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            connection = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        if (this.mounted) {
          setState(() {
            total = jsonData[0]['total'];
          });
        }
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataDetails.add(vdata);
        }
        if (this.mounted) {
          setState(() {
            connection = true;
          });
        }
      }
    }).catchError((err) {
      print("Get more data error: " + (err).toString());
    });
    _refreshController.loadComplete();
  }

  void _redirectVProfile(int index) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      String name, phoneNo, status, email;
      if (connection == true) {
        name = vDataDetails[index].name;
        phoneNo = vDataDetails[index].phoneNo;
        email = vDataDetails[index].email;
        status = vDataDetails[index].status;
      } else {
        name = offlineVData[index]['name'];
        phoneNo = offlineVData[index]['phone'];
        email = offlineVData[index]['email'];
        status = offlineVData[index]['status'];
      }
      VDataDetails vdata = new VDataDetails(
        companyID: companyID,
        branchID: branchID,
        userID: userID,
        level: level,
        userType: userType,
        name: name,
        phoneNo: phoneNo,
        email: email,
        status: status,
      );
      Navigator.of(context).push(PageRouteTransition(
          animationType: AnimationType.scale,
          builder: (context) => VProfile(vdata: vdata)));
    } else {
      _toast("No Internet Connection!");
    }
  }

  void _selection(int index) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (myworksReady == true) {
        _whatsappType(index);
      } else {
        _toast('Data loading, please try again');
      }
    } else {
      _toast('No Internet Connection');
    }
  }

  YYDialog _whatsappType(int index) {
    int type = 0;
    return YYDialog().build()
      ..width = ScreenUtil().setHeight(560)
      ..borderRadius = ScreenUtil().setHeight(8)
      ..text(
        padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
        alignment: Alignment.center,
        text: "Select WhatsApp Type",
        color: Colors.black,
        fontSize: font18,
        fontWeight: FontWeight.w500,
      )
      ..divider()
      ..listViewOfRadioButton(
          height: ScreenUtil().setHeight(240),
          items: radioSelections,
          intialValue: 0,
          color: Colors.white,
          activeColor: Colors.blue,
          onClickItemListener: (index) {
            type = index;
          })
      ..divider()
      ..doubleButton(
          padding: EdgeInsets.only(
              top: ScreenUtil().setHeight(16),
              bottom: ScreenUtil().setHeight(16)),
          gravity: Gravity.right,
          text1: "CANCEL",
          color1: Colors.blue,
          fontSize1: font14,
          fontWeight1: FontWeight.bold,
          text2: "OK",
          color2: Colors.blue,
          fontSize2: font14,
          fontWeight2: FontWeight.bold,
          onTap2: () {
            if (type == 0) {
              _redirectWhatsApp(index);
            } else {
              getVTagData(vDataDetails[index].phoneNo);
              Future.delayed(const Duration(milliseconds: 50), () {
                _myworksLink(index);
              });
            }
          })
      ..show();
  }

  void _redirectWhatsApp(int index) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (connection == true) {
        FlutterOpenWhatsapp.sendSingleMessage(vDataDetails[index].phoneNo, "");
      } else {
        FlutterOpenWhatsapp.sendSingleMessage(offlineVData[index]['phone'], "");
      }
    } else {
      _toast("This feature need Internet connection");
    }
  }

  void _myworksLink(int index) {
    RadioItem widget;
    radioItems.clear();
    for (var link in myWorks) {
      widget = RadioItem(
        padding: EdgeInsets.only(
          left: ScreenUtil().setHeight(12),
        ),
        text: link.title,
        color: Colors.black,
        fontSize: font14,
      );
      radioItems.add(widget);
    }
    YYListViewDialogListRadio(index);
  }

  YYDialog YYListViewDialogListRadio(int index) {
    int index1 = 0;
    return YYDialog().build()
      ..width = ScreenUtil().setHeight(600)
      ..borderRadius = ScreenUtil().setHeight(8)
      ..text(
        padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
        alignment: Alignment.center,
        text: "Select MyWorks Link",
        color: Colors.black,
        fontSize: font18,
        fontWeight: FontWeight.w500,
      )
      ..divider()
      ..widget(
        Container(
          child: Card(
            child: Container(
              margin: EdgeInsets.only(
                right: ScreenUtil().setHeight(20),
                left: ScreenUtil().setHeight(30),
              ),
              height: ScreenUtil().setHeight(75),
              child: TextField(
                controller: _dialogSearchController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.go,
                onSubmitted: (value) => _dialogSearch(value, index),
                style: TextStyle(
                  fontSize: font14,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(10, 3, 0, 3),
                  hintText: "Search",
                  suffix: IconButton(
                    iconSize: ScreenUtil().setHeight(40),
                    icon: Icon(Icons.keyboard_hide),
                    onPressed: () {
                      FocusScope.of(context).requestFocus(new FocusNode());
                    },
                  ),
                  suffixIcon: BouncingWidget(
                    scaleFactor: _scaleFactor,
                    onPressed: () {
                      _dialogSearch(_dialogSearchController.text, index);
                    },
                    child: Icon(
                      Icons.search,
                      size: ScreenUtil().setHeight(50),
                    ),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      )
      ..listViewOfRadioButton(
          height: ScreenUtil().setHeight(1000),
          items: radioItems,
          intialValue: 0,
          color: Colors.white,
          activeColor: Colors.blue,
          onClickItemListener: (index) {
            index1 = index;
          })
      ..divider()
      ..doubleButton(
          padding: EdgeInsets.only(
              top: ScreenUtil().setHeight(16),
              bottom: ScreenUtil().setHeight(16)),
          gravity: Gravity.right,
          text1: "CANCEL",
          color1: Colors.blue,
          fontSize1: font14,
          fontWeight1: FontWeight.bold,
          onTap1: () {
            _dialogSearchController.text = '';
          },
          text2: "OK",
          color2: Colors.blue,
          fontSize2: font14,
          fontWeight2: FontWeight.bold,
          onTap2: () {
            _checking(index1, index);
          })
      ..show();
  }

  void _checking(int index1, int index) {
    if (vTagData == true) {
      WhatsappForward whatsapp = WhatsappForward(
        url: myWorks[index1].link,
        userID: userID,
        userType: userType,
        companyID: companyID,
        branchID: branchID,
        level: level,
        vtagList: vtagList,
        vtag: vTag,
        name: vDataDetails[index].name,
        phone: vDataDetails[index].phoneNo,
      );
      Future.delayed(const Duration(milliseconds: 50), () {
        Navigator.push(
          context,
          AwesomePageRoute(
            transitionDuration: Duration(milliseconds: 600),
            exitPage: widget,
            enterPage: WhatsAppForward(whatsappForward: whatsapp),
            transition: StackTransition(),
          ),
        );
      });
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        _checking(index1, index);
      });
    }
  }

  Future<void> _dialogSearch(String value, int index) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    Navigator.pop(context);
    myWorks.clear();
    for (int i = 0; i < myWorks1.length; i++) {
      if (myWorks1[i].title.toLowerCase().contains(value.toLowerCase())) {
        myWorks.add(myWorks1[i]);
      }
    }
    _myworksLink(index);
  }

  Future<bool> _onBackPressAppBar() async {
    YYAlertDialogWithScaleIn();
    return Future.value(false);
  }

  void _filter() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      showModalBottomSheet(
        isScrollControlled: true,
        isDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Container(
                height: MediaQuery.of(context).size.height * 0.9,
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
                                  fontSize: font14,
                                  fontWeight: FontWeight.bold),
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
                                    "By Status",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showBottomSheet("byStatus");
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
                                                  _byStatus,
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
                              SizedBox(
                                height: ScreenUtil().setHeight(15),
                              ),
                              Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "By Type",
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
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              margin: EdgeInsets.fromLTRB(0, 0,
                                                  ScreenUtil().setWidth(20), 0),
                                              decoration: BoxDecoration(
                                                color: (type == "all")
                                                    ? Colors.blue
                                                    : Colors.white,
                                                border: Border(
                                                  top: BorderSide(
                                                      width: 1,
                                                      color: (type == "all")
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey.shade300),
                                                  right: BorderSide(
                                                      width: 1,
                                                      color: (type == "all")
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey.shade300),
                                                  bottom: BorderSide(
                                                      width: 1,
                                                      color: (type == "all")
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey.shade300),
                                                  left: BorderSide(
                                                      width: 1,
                                                      color: (type == "all")
                                                          ? Colors.blue
                                                          : Colors
                                                              .grey.shade300),
                                                ),
                                              ),
                                              child: FlatButton(
                                                onPressed: () {
                                                  setModalState(() {
                                                    type = "all";
                                                  });
                                                },
                                                child: Text(
                                                  'All',
                                                  style: TextStyle(
                                                    fontSize: font12,
                                                    color: (type == "all")
                                                        ? Colors.white
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: ScreenUtil().setWidth(220),
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              margin: EdgeInsets.fromLTRB(0, 0,
                                                  ScreenUtil().setWidth(20), 0),
                                              decoration: BoxDecoration(
                                                color: (type == "assigned")
                                                    ? Colors.blue
                                                    : Colors.white,
                                                border: Border(
                                                  top: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "assigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                  right: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "assigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                  bottom: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "assigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                  left: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "assigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                ),
                                              ),
                                              child: FlatButton(
                                                onPressed: () {
                                                  setModalState(() {
                                                    type = "assigned";
                                                  });
                                                },
                                                child: Text(
                                                  'Assigned',
                                                  style: TextStyle(
                                                    fontSize: font12,
                                                    color: (type == "assigned")
                                                        ? Colors.white
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: ScreenUtil().setWidth(250),
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              margin: EdgeInsets.fromLTRB(0, 0,
                                                  ScreenUtil().setWidth(10), 0),
                                              decoration: BoxDecoration(
                                                color: (type == "unassigned")
                                                    ? Colors.blue
                                                    : Colors.white,
                                                border: Border(
                                                  top: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "unassigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                  right: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "unassigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                  bottom: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "unassigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                  left: BorderSide(
                                                      width: 1,
                                                      color:
                                                          (type == "unassigned")
                                                              ? Colors.blue
                                                              : Colors.grey
                                                                  .shade300),
                                                ),
                                              ),
                                              child: FlatButton(
                                                onPressed: () {
                                                  setModalState(() {
                                                    type = "unassigned";
                                                  });
                                                },
                                                child: Text(
                                                  'Unassigned',
                                                  style: TextStyle(
                                                    fontSize: font12,
                                                    color:
                                                        (type == "unassigned")
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
                                  SizedBox(
                                    height: ScreenUtil().setHeight(30),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "By Channel",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Flexible(
                                    child: Wrap(
                                      children: <Widget>[
                                        Container(
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setWidth(15),
                                              ScreenUtil().setHeight(10)),
                                          width: ScreenUtil().setWidth(115),
                                          height: ScreenUtil().setHeight(60),
                                          decoration: BoxDecoration(
                                            color: (channel == "all")
                                                ? Colors.blue
                                                : Colors.white,
                                            border: Border(
                                              top: BorderSide(
                                                  width: 1,
                                                  color: (channel == "all")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              right: BorderSide(
                                                  width: 1,
                                                  color: (channel == "all")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              bottom: BorderSide(
                                                  width: 1,
                                                  color: (channel == "all")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              left: BorderSide(
                                                  width: 1,
                                                  color: (channel == "all")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: FlatButton(
                                            onPressed: () {
                                              setModalState(() {
                                                channel = "all";
                                              });
                                            },
                                            child: Text(
                                              'All',
                                              style: TextStyle(
                                                fontSize: font11,
                                                color: (channel == "all")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Container(
                                        //   width: ScreenUtil().setWidth(250),
                                        //   height: ScreenUtil().setHeight(60),
                                        //   margin: EdgeInsets.fromLTRB(
                                        //       0,
                                        //       ScreenUtil().setHeight(10),
                                        //       ScreenUtil().setWidth(15),
                                        //       ScreenUtil().setHeight(10)),
                                        //   decoration: BoxDecoration(
                                        //     color: (channel == "contact form")
                                        //         ? Colors.blue
                                        //         : Colors.white,
                                        //     border: Border(
                                        //       top: BorderSide(
                                        //           width: 1,
                                        //           color: (channel ==
                                        //                   "contact form")
                                        //               ? Colors.blue
                                        //               : Colors.grey.shade300),
                                        //       right: BorderSide(
                                        //           width: 1,
                                        //           color: (channel ==
                                        //                   "contact form")
                                        //               ? Colors.blue
                                        //               : Colors.grey.shade300),
                                        //       bottom: BorderSide(
                                        //           width: 1,
                                        //           color: (channel ==
                                        //                   "contact form")
                                        //               ? Colors.blue
                                        //               : Colors.grey.shade300),
                                        //       left: BorderSide(
                                        //           width: 1,
                                        //           color: (channel ==
                                        //                   "contact form")
                                        //               ? Colors.blue
                                        //               : Colors.grey.shade300),
                                        //     ),
                                        //   ),
                                        //   child: FlatButton(
                                        //     onPressed: () {
                                        //       setModalState(() {
                                        //         channel = "contact form";
                                        //       });
                                        //     },
                                        //     child: Text(
                                        //       'Contact Form',
                                        //       style: TextStyle(
                                        //         fontSize: font11,
                                        //         color:
                                        //             (channel == "contact form")
                                        //                 ? Colors.white
                                        //                 : Colors.grey,
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),
                                        Container(
                                          width: ScreenUtil().setWidth(320),
                                          height: ScreenUtil().setHeight(60),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setWidth(10),
                                              ScreenUtil().setHeight(10)),
                                          decoration: BoxDecoration(
                                            color:
                                                (channel == "whatsapp forward")
                                                    ? Colors.blue
                                                    : Colors.white,
                                            border: Border(
                                              top: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "whatsapp forward")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              right: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "whatsapp forward")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              bottom: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "whatsapp forward")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              left: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "whatsapp forward")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: FlatButton(
                                            onPressed: () {
                                              setModalState(() {
                                                channel = "whatsapp forward";
                                              });
                                            },
                                            child: Text(
                                              'WhatsApp Forward',
                                              style: TextStyle(
                                                fontSize: font11,
                                                color: (channel ==
                                                        "whatsapp forward")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setWidth(220),
                                          height: ScreenUtil().setHeight(60),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setWidth(20),
                                              0),
                                          decoration: BoxDecoration(
                                            color: (channel == "messenger")
                                                ? Colors.blue
                                                : Colors.white,
                                            border: Border(
                                              top: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "messenger")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              right: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "messenger")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              bottom: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "messenger")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              left: BorderSide(
                                                  width: 1,
                                                  color: (channel ==
                                                          "messenger")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: FlatButton(
                                            onPressed: () {
                                              setModalState(() {
                                                channel = "messenger";
                                              });
                                            },
                                            child: Text(
                                              'Messenger',
                                              style: TextStyle(
                                                fontSize: font11,
                                                color: (channel == "messenger")
                                                    ? Colors.white
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: ScreenUtil().setWidth(200),
                                          height: ScreenUtil().setHeight(60),
                                          margin: EdgeInsets.fromLTRB(
                                              0,
                                              ScreenUtil().setHeight(10),
                                              ScreenUtil().setWidth(15),
                                              0),
                                          decoration: BoxDecoration(
                                            color: (channel == "import")
                                                ? Colors.blue
                                                : Colors.white,
                                            border: Border(
                                              top: BorderSide(
                                                  width: 1,
                                                  color: (channel == "import")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              right: BorderSide(
                                                  width: 1,
                                                  color: (channel == "import")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              bottom: BorderSide(
                                                  width: 1,
                                                  color: (channel == "import")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                              left: BorderSide(
                                                  width: 1,
                                                  color: (channel == "import")
                                                      ? Colors.blue
                                                      : Colors.grey.shade300),
                                            ),
                                          ),
                                          child: FlatButton(
                                            onPressed: () {
                                              setModalState(() {
                                                channel = "import";
                                              });
                                            },
                                            child: Text(
                                              'Import',
                                              style: TextStyle(
                                                fontSize: font11,
                                                color: (channel == "import")
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
                              SizedBox(
                                height: ScreenUtil().setHeight(30),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "By Apps",
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
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showBottomSheet("byApps");
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
                                                  apps,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              SizedBox(
                                height: ScreenUtil().setHeight(20),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "By Link",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showBottomSheet("byLink");
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
                                                  _byLink,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              SizedBox(
                                height: ScreenUtil().setHeight(20),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "By VTag",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showBottomSheet("byVTag");
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
                                                  _byVTag,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                              SizedBox(
                                height: ScreenUtil().setHeight(20),
                              ),
                              Container(
                                child: (level == "0" || level == "4")
                                    ? Column(
                                        children: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                "By Executive",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: font14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: ScreenUtil().setHeight(5),
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    _showBottomSheet(
                                                        "byExecutive");
                                                  },
                                                  child: Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      0,
                                                      0,
                                                      0,
                                                      ScreenUtil()
                                                          .setHeight(20),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade400,
                                                          style: BorderStyle
                                                              .solid),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: Container(
                                                            height: ScreenUtil()
                                                                .setHeight(60),
                                                            padding: EdgeInsets
                                                                .fromLTRB(
                                                                    ScreenUtil()
                                                                        .setHeight(
                                                                            10),
                                                                    ScreenUtil()
                                                                        .setHeight(
                                                                            16),
                                                                    0,
                                                                    0),
                                                            child: Text(
                                                              _byExecutive,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    font14,
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
                                                              .setWidth(10),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: ScreenUtil().setHeight(20),
                                          ),
                                        ],
                                      )
                                    : Container(),
                              ),
                              Container(
                                child: (level == "0")
                                    ? Column(
                                        children: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                "By Branch",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: font14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: ScreenUtil().setHeight(5),
                                          ),
                                          Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    _showBottomSheet(
                                                        "byBranch");
                                                  },
                                                  child: Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                      0,
                                                      0,
                                                      0,
                                                      ScreenUtil()
                                                          .setHeight(20),
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade400,
                                                          style: BorderStyle
                                                              .solid),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        Expanded(
                                                          child: Container(
                                                            height: ScreenUtil()
                                                                .setHeight(60),
                                                            padding: EdgeInsets
                                                                .fromLTRB(
                                                                    ScreenUtil()
                                                                        .setHeight(
                                                                            10),
                                                                    ScreenUtil()
                                                                        .setHeight(
                                                                            16),
                                                                    0,
                                                                    0),
                                                            child: Text(
                                                              _byBranch,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize:
                                                                    font14,
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
                                                              .setWidth(10),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: ScreenUtil().setHeight(20),
                                          ),
                                        ],
                                      )
                                    : Container(),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Start Date",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(200),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  backgroundColor: Colors.transparent,
                                  minimumDate: DateFormat("yyyy-MM-dd")
                                      .parse(minimumDate),
                                  initialDateTime: _startDate,
                                  maximumDate: (_endDatePicker == null)
                                      ? DateTime.now()
                                      : _endDatePicker,
                                  onDateTimeChanged: (start) {
                                    setModalState(() {
                                      _startDate = start;
                                      _startDatePicker = start;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(20),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "End Date",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(200),
                                child: CupertinoDatePicker(
                                  mode: CupertinoDatePickerMode.date,
                                  backgroundColor: Colors.transparent,
                                  minimumDate: (_startDatePicker == null)
                                      ? DateFormat("yyyy-MM-dd")
                                          .parse(minimumDate)
                                      : _startDatePicker,
                                  maximumDate: DateTime.now(),
                                  initialDateTime: _endDate,
                                  onDateTimeChanged: (end) {
                                    setModalState(() {
                                      _endDate = end;
                                      _endDatePicker = end;
                                    });
                                  },
                                ),
                              )
                            ],
                          ),
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
    } else {
      _toast("Please check your Internet connection");
    }
  }

  void _showBottomSheet(String type) {
    switch (type) {
      case "byVTag":
        {
          if (vtagList.length != 0) {
            int position;
            if (_byVTag == "All VTags") {
              position = 0;
            } else {
              for (int i = 0; i < vtagList.length; i++) {
                if (_byVTag == vtagList[i]) {
                  position = i;
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
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    width: 1, color: Colors.grey.shade300),
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
                                    Navigator.pop(context, true);
                                    Navigator.of(context).pop();
                                    _filter();
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
                                scrollController: FixedExtentScrollController(
                                    initialItem: position),
                                onSelectedItemChanged: (int index) {
                                  if (index != 0) {
                                    if (this.mounted) {
                                      setState(() {
                                        _byVTag = vtagList[index];
                                      });
                                    }
                                  } else {
                                    if (this.mounted) {
                                      setState(() {
                                        _byVTag = 'All VTags';
                                      });
                                    }
                                  }
                                },
                                children: _list(vtagList),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            );
          } else {
            _toast('No VTag');
          }
        }
        break;

      case "byLink":
        {
          int position;
          if (_byLink == "All Links") {
            position = 0;
          } else {
            for (int i = 0; i < linksID.length; i++) {
              if (_byLink == linksID[i].link_type + linksID[i].link) {
                position = linksID[i].position;
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
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Column(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  width: 1, color: Colors.grey.shade300),
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
                                  Navigator.pop(context, true);
                                  Navigator.of(context).pop();
                                  _filter();
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
                              scrollController: FixedExtentScrollController(
                                  initialItem: position),
                              onSelectedItemChanged: (int index) {
                                if (this.mounted) {
                                  setState(() {
                                    _byLink = linksID[index].link_type +
                                        linksID[index].link;
                                  });
                                }
                              },
                              children: _link(linksID),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        }
        break;

      case "byBranch":
        {
          int position;
          for (int i = 0; i < branchesList.length; i++) {
            if (_byBranch == branchesList[i].branchName) {
              position = i;
            }
          }
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
                              bottom: BorderSide(
                                  width: 1, color: Colors.grey.shade300),
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
                                  Navigator.pop(context, true);
                                  Navigator.of(context).pop();
                                  _filter();
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
                              scrollController: FixedExtentScrollController(
                                  initialItem: position),
                              onSelectedItemChanged: (int index) {
                                if (this.mounted) {
                                  setState(() {
                                    _byBranch = branchesList[index].branchName;
                                  });
                                }
                              },
                              children: _branch(branchesList),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        }
        break;

      case "byStatus":
        {
          int position;
          for (int i = 0; i < status.length; i++) {
            if (_byStatus == status[i]) {
              position = i;
            }
          }
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
                              bottom: BorderSide(
                                  width: 1, color: Colors.grey.shade300),
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
                                  Navigator.pop(context, true);
                                  Navigator.of(context).pop();
                                  _filter();
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
                              scrollController: FixedExtentScrollController(
                                  initialItem: position),
                              onSelectedItemChanged: (int index) {
                                if (this.mounted) {
                                  setState(() {
                                    _byStatus = status[index];
                                  });
                                }
                              },
                              children: _list(status),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        }
        break;

      case "byExecutive":
        {
          int position;
          for (int i = 0; i < executiveList.length; i++) {
            if (_byExecutive == executiveList[i]) {
              position = i;
            }
          }
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
                              bottom: BorderSide(
                                  width: 1, color: Colors.grey.shade300),
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
                                  Navigator.pop(context, true);
                                  Navigator.of(context).pop();
                                  _filter();
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
                              scrollController: FixedExtentScrollController(
                                  initialItem: position),
                              onSelectedItemChanged: (int index) {
                                if (this.mounted) {
                                  setState(() {
                                    _byExecutive = executiveList[index];
                                  });
                                }
                              },
                              children: _list(executiveList),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        }
        break;

      case "byApps":
        {
          int position;
          if (apps == "All") {
            position = 0;
          } else {
            for (int i = 0; i < appsAll.length; i++) {
              if (apps == appsAll[i]) {
                position = i;
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
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: Column(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  width: 1, color: Colors.grey.shade300),
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
                                  Navigator.pop(context, true);
                                  Navigator.of(context).pop();
                                  _filter();
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
                              scrollController: FixedExtentScrollController(
                                  initialItem: position),
                              onSelectedItemChanged: (int index) {
                                if (this.mounted) {
                                  setState(() {
                                    apps = appsAll[index];
                                  });
                                }
                              },
                              children: _list(appsAll),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        }
        break;
    }
  }

  List<Widget> _link(List<Links> linksID) {
    List widgetList = <Widget>[];
    for (var each in linksID) {
      Widget widget1 = Text(
        each.link_type + each.link,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: font14,
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _branch(List<Branch> branches) {
    List widgetList = <Widget>[];
    for (var each in branches) {
      Widget widget1 = Text(
        each.branchName,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: font14,
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _list(List list) {
    List widgetList = <Widget>[];
    for (var each in list) {
      Widget widget1 = Text(
        each,
        style: TextStyle(
          fontSize: font14,
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  void checkConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("noti") != null) {
      if (this.mounted) {
        setState(() {
          totalNotification = prefs.getString("noti");
        });
      }
      FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
    }
    companyID = prefs.getString('companyID');
    branchID = prefs.getString('branchID');
    userID = prefs.getString('userID');
    level = prefs.getString('level');
    _byBranch = (level == "0") ? "All Branch" : "";
    userType = prefs.getString('user_type');
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      getPreference();
    } else {
      offline();
      _toast("No Internet, the data shown is not up to date");
    }
  }

  void getPreference() {
    startTime = (DateTime.now()).millisecondsSinceEpoch;
    if (level == "0" || level == "4") {
      getExecutive();
    }
    getLink();
    getData();
    getLinks();
    getVTag();
    if (level == "0") {
      getBranches();
    }
    notification();
  }

  void getVTagData(String phoneNo) {
    http.post(urlVTag, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "phone_number": phoneNo,
    }).then((res) {
      // print("getVTag body: " + res.body);
      if (res.body == "nodata") {
        vTag = [];
      } else {
        var jsonData = json.decode(res.body);
        vTag = jsonData;
      }
      if (this.mounted) {
        setState(() {
          vTagData = true;
        });
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get VTag error: " + err.toString());
    });
  }

  void getBranches() {
    http.post(urlBranches, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
    }).then((res) {
      Branch branches = Branch(
        branchID: '00',
        branchName: 'All Branch',
      );
      branchesList.add(branches);
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          Branch branch = Branch(
            branchID: data['id'],
            branchName: data['name'],
          );
          branchesList.add(branch);
        }
        if (this.mounted) {
          setState(() {
            branch = true;
          });
        }
        if (vData == true) {
          if (this.mounted) {
            setState(() {
              vDataReady = true;
            });
          }
        }
      } else {}
    }).catchError((err) {
      print("Get branches error: " + err.toString());
    });
  }

  void notification() {
    http.post(urlNoti, body: {
      "userID": userID,
      "companyID": companyID,
      "branchID": branchID,
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

  String checkStatus(String status) {
    String realStatus;
    switch (status.toLowerCase()) {
      case "new":
        realStatus = "New";
        break;

      case "contacting":
        realStatus = "Contacting";
        break;

      case "contacted":
        realStatus = "Contacted";
        break;

      case "qualified":
        realStatus = "Qualified";
        break;

      case "converted":
        realStatus = "Converted";
        break;

      case "follow-up":
        realStatus = "Follow-up";
        break;

      case "unqualified":
        realStatus = "Unqualified";
        break;

      case "new":
        realStatus = "New";
        break;

      case "bad information":
        realStatus = "Bad Information";
        break;

      case "no response":
        realStatus = "No Response";
        break;
    }
    return realStatus;
  }

  void getData() {
    startDate = minimumDate;
    endDate = DateTime.now().toString().substring(0, 10);
    getNewData();
    getContactingData();
    getContactedData();
    getQualifiedData();
    getConvertedData();
    getFollowUpData();
    getUnqualifiedData();
    getBadInfoData();
    getNoResponseData();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": _byStatus,
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VData body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            vData = true;
            connection = true;
            nodata = true;
            total = 0;
          });
        }
        if (level == "0" && branch == true) {
          if (this.mounted) {
            setState(() {
              vDataReady = true;
            });
          }
        } else {
          if (this.mounted) {
            setState(() {
              vDataReady = true;
            });
          }
        }
      } else {
        var jsonData = json.decode(res.body);
        if (this.mounted) {
          setState(() {
            total = jsonData[0]['total'];
          });
        }
        vDataDetails.clear();
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataDetails.add(vdata);
        }
        if (this.mounted) {
          setState(() {
            vData = true;
            connection = true;
          });
        }
        if (level == "0" && branch == true) {
          if (this.mounted) {
            setState(() {
              vDataReady = true;
            });
          }
        } else {
          if (this.mounted) {
            setState(() {
              vDataReady = true;
            });
          }
        }
      }
      if (link == true &&
          vData == true &&
          executive == true &&
          vtagStatus == true) {
        getOfflineData();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VData loading Time: " + result.toString());
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getNewData() {
    vDataNew.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'New',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataNew body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyNew = true;
            nodataNew = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataNew.add(vdata);
        }
        vDataInfoNew = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'New',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataNew,
        );
        if (this.mounted) {
          setState(() {
            readyNew = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getContactingData() {
    vDataContacting.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Contacting',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacting body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyContacting = true;
            nodataContacting = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataContacting.add(vdata);
        }
        vDataInfoContacting = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacting',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataContacting,
        );
        if (this.mounted) {
          setState(() {
            readyContacting = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getContactedData() {
    vDataContacted.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Contacted',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyContacted = true;
            nodataContacted = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataContacted.add(vdata);
        }
        vDataInfoContacted = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataContacted,
        );
        if (this.mounted) {
          setState(() {
            readyContacted = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getQualifiedData() {
    vDataQualified.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Qualified',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyQualified = true;
            nodataQualified = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataQualified.add(vdata);
        }
        vDataInfoQualified = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataQualified,
        );
        if (this.mounted) {
          setState(() {
            readyQualified = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getConvertedData() {
    vDataConverted.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Converted',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyConverted = true;
            nodataConverted = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataConverted.add(vdata);
        }
        vDataInfoConverted = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataConverted,
        );
        if (this.mounted) {
          setState(() {
            readyConverted = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getFollowUpData() {
    vDataFollowUp.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Follow-Up',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyFollowUp = true;
            nodataFollowUp = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataFollowUp.add(vdata);
        }
        vDataInfoFollowUp = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataFollowUp,
        );
        if (this.mounted) {
          setState(() {
            readyFollowUp = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getUnqualifiedData() {
    vDataUnqualified.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Unqualified',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyUnqualified = true;
            nodataUnqualified = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataUnqualified.add(vdata);
        }
        vDataInfoUnqualified = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataUnqualified,
        );
        if (this.mounted) {
          setState(() {
            readyUnqualified = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getBadInfoData() {
    vDataBadInfo.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'Bad Information',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyBadInfo = true;
            nodataBadInfo = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataBadInfo.add(vdata);
        }
        vDataInfoBadInfo = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataBadInfo,
        );
        if (this.mounted) {
          setState(() {
            readyBadInfo = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getNoResponseData() {
    vDataNoResponse.clear();
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": link_id,
      "status": 'No Response',
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": startDate,
      "end_date": endDate,
      "count": "0",
      "offline": "no"
    }).then((res) {
      // print("VDataContacted body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            readyNoResponse = true;
            nodataNoResponse = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataNoResponse.add(vdata);
        }
        vDataInfoNoResponse = VDataInfo(
          companyID: companyID,
          branchID: branchID,
          level: level,
          userID: userID,
          userType: userType,
          type: type,
          channel: channel,
          apps: apps,
          link_id: link_id,
          byStatus: 'Contacted',
          byExecutive: _byExecutive,
          byVTag: _byVTag,
          search: search,
          startDate: startDate,
          endDate: endDate,
          total: jsonData[0]['total'],
          vDataList: vDataNoResponse,
        );
        if (this.mounted) {
          setState(() {
            readyNoResponse = true;
          });
        }
      }
    }).catchError((err) {
      print("Get data error: " + err.toString());
    });
  }

  void getOfflineData() {
    http.post(urlVData, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "type": type,
      "channel": channel,
      "apps": apps,
      "link_id": "All Links",
      "status": _byStatus,
      "executive": _byExecutive,
      "vtag": _byVTag,
      "search": search,
      "start_date": minimumDate,
      "end_date": DateTime.now().toString().substring(0, 10),
      "count": "0",
      "offline": "yes"
    }).then((res) {
      // print("Save VData body: " + res.body.toString());
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          VDataDetails vdata = VDataDetails(
            date: data['date'],
            name: data['name'] ?? "",
            phoneNo: data['phone_number'],
            email: data['email'] ?? '',
            remark: data['remark'] ?? "-",
            status: checkStatus(data['status']),
            type: data['type'],
            app: data['app'],
            channel: data['channel'],
            link: data['link_type'] ?? "" + data['link'],
            handler: data['link'],
          );
          vDataOffline.add(vdata);
        }
        setData();
      }
    }).catchError((err) {
      print("Get offline data error: " + (err).toString());
    });
  }

  void getLink() {
    http.post(urlMyWorks, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "count": myWorks.length.toString(),
    }).then((res) {
      // print("MyWorks body: " + res.body);
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            myworksReady = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        if (totalLink == 0) {
          totalLink = int.parse(jsonData[0]);
          for (int i = 1; i < jsonData.length; i++) {
            Myworks mywork = Myworks(
                date: jsonData[i]['date'],
                title: jsonData[i]['title'],
                urlName: jsonData[i]['urlName'],
                link: jsonData[i]['link'],
                category: jsonData[i]['category'],
                qr: jsonData[i]['qr'],
                id: jsonData[i]['id'],
                handlers: jsonData[i]['handler'],
                branchID: jsonData[i]['branchID'] ?? '',
                branchName: jsonData[i]['branchName'] ?? '',
                offLine: false);
            myWorks.add(mywork);
            myWorks1.add(mywork);
          }
          if (myWorks.length != totalLink) {
            getLink();
          } else {
            if (this.mounted) {
              setState(() {
                myworksReady = true;
              });
            }
          }
        } else {
          for (int i = 0; i < jsonData.length; i++) {
            Myworks mywork = Myworks(
                date: jsonData[i]['date'],
                title: jsonData[i]['title'],
                urlName: jsonData[i]['urlName'],
                link: jsonData[i]['link'],
                category: jsonData[i]['category'],
                qr: jsonData[i]['qr'],
                id: jsonData[i]['id'],
                handlers: jsonData[i]['handlers'],
                branchID: jsonData[i]['branchID'] ?? '',
                branchName: jsonData[i]['branchName'] ?? '',
                offLine: false);
            myWorks.add(mywork);
            myWorks1.add(mywork);
          }
          if (myWorks.length != totalLink) {
            getLink();
          } else {
            if (this.mounted) {
              setState(() {
                myworksReady = true;
              });
            }
          }
        }
      }
    }).catchError((err) {
      print("Get Link error: " + (err).toString());
    });
  }

  void getLinks() {
    http.post(urlLinks, body: {
      "companyID": companyID,
      "branchID": branchID,
      "level": level,
      "userID": userID,
      "user_type": userType,
    }).then((res) {
      links.clear();
      links.add("All Links");
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        Links allLinks = Links(
          link_type: "",
          link: "All Links",
          link_id: "All Links",
          position: 0,
        );
        linksID.add(allLinks);
        for (int i = 0; i < jsonData.length; i++) {
          Links linkID = Links(
            link_type: jsonData[i]['link_type'],
            link: jsonData[i]['link'] ?? "",
            link_id: jsonData[i]['link_id'],
            position: i + 1,
          );
          linksID.add(linkID);
          String link = jsonData[i]['link_type'].toString() +
              jsonData[i]['link'].toString();
          links.add(link);
        }
      }
      _startDate = DateFormat("yyyy-MM-dd").parse(minimumDate);
      _endDate = DateTime.now();
      if (this.mounted) {
        setState(() {
          link = true;
        });
      }
      if (link == true &&
          vData == true &&
          executive == true &&
          vtagStatus == true) {
        getOfflineData();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VData loading Time: " + result.toString());
      }
    }).catchError((err) {
      print("Get link error: " + (err).toString());
    });
  }

  void getExecutive() {
    executiveList.clear();
    executiveList.add("All Executives");
    http.post(urlHandler, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "user_type": userType,
      "level": level,
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          if (data["handler"] != "-") {
            Handler handler = Handler(
              handler: data["handler"],
              position: data["position"],
              handlerID: data["handlerID"],
            );
            executiveList.add(data["handler"]);
            handlerList.add(handler);
          }
        }
      }
      if (this.mounted) {
        setState(() {
          executive = true;
        });
      }
      if (link == true &&
          vData == true &&
          executive == true &&
          vtagStatus == true) {
        getOfflineData();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VData loading Time: " + result.toString());
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get Executive error: " + (err).toString());
    });
  }

  void getVTag() {
    http.post(urlVTag, body: {
      "companyID": companyID,
      "branchID": branchID,
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
      if (link == true &&
          vData == true &&
          executive == true &&
          vtagStatus == true) {
        getOfflineData();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VData loading Time: " + result.toString());
      }
    }).catchError((err) {
      print("Get Link error: " + (err).toString());
    });
  }

  Future<void> setData() async {
    Database db = await VDataDB.instance.database;
    await db.rawInsert('DELETE FROM vdata WHERE id > 0');
    for (int index = 0; index < vDataOffline.length; index++) {
      await db.rawInsert(
          'INSERT INTO vdata (date, name, phone, handler, remark, status, total) VALUES("' +
              vDataOffline[index].date +
              '","' +
              vDataOffline[index].name +
              '","' +
              vDataOffline[index].phoneNo +
              '","' +
              vDataOffline[index].handler +
              '","' +
              vDataOffline[index].remark +
              '","' +
              vDataOffline[index].status +
              '","' +
              total.toString() +
              '")');
    }
  }

  Future<void> offline() async {
    vdataDB = await VDataDB.instance.database;
    offlineVData = await vdataDB.query(VDataDB.table);
    if (this.mounted) {
      setState(() {
        link = true;
        vDataReady = true;
        vtagStatus = true;
      });
    }
  }

  void setStatus(int index, String newVal) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlChangeStatus, body: {
        "phone_number": vDataDetails[index].phoneNo.toString(),
        "companyID": companyID,
        "branchID": branchID,
        "userID": userID,
        "level": level,
        "user_type": userType,
        "status": newVal,
      }).then((res) {
        if (res.body == "success") {
          _toast("Status changed");
          if (this.mounted) {
            setState(() {
              vDataDetails[index].status = newVal;
              connection = true;
            });
          }
        } else {
          _toast("Status can't change, please contact VVIN help desk");
        }
      }).catchError((err) {
        _toast("Status can't change, please check your Internet connection");
        print("Set status error: " + (err).toString());
      });
    } else {
      _toast("This feature need Internet connection");
    }
  }

  void _noInternet() {
    _toast("You are in offline mode, filter feature is not allow");
  }

  void _done() async {
    if (this.mounted) {
      setState(() {
        nodataNew = nodataContacting = nodataContacted = nodataQualified =
            nodataConverted = nodataFollowUp =
                nodataUnqualified = nodataBadInfo = nodataNoResponse = false;
        readyNew = readyContacting = readyContacted = readyQualified =
            readyConverted = readyFollowUp =
                readyUnqualified = readyBadInfo = readyNoResponse = true;
      });
    }
    if (_byStatus != 'All Status') {
      switch (_byStatus) {
        case 'New':
          if (this.mounted) {
            setState(() {
              readyNew = false;
              nodataContacting = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }

          getNewData();
          break;
        case 'Contacting':
          if (this.mounted) {
            setState(() {
              readyContacting = false;
              nodataNew = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }
          getContactingData();
          break;
        case 'Contacted':
          if (this.mounted) {
            setState(() {
              readyContacted = false;
              nodataNew = true;
              nodataContacting = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }
          getContactedData();
          break;
        case 'Qualified':
          if (this.mounted) {
            setState(() {
              readyQualified = false;
              nodataNew = true;
              nodataContacting = true;
              nodataContacted = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }
          getQualifiedData();
          break;
        case 'Converted':
          if (this.mounted) {
            setState(() {
              readyConverted = false;
              nodataNew = true;
              nodataContacting = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }
          getConvertedData();
          break;
        case 'Follow-up':
          if (this.mounted) {
            setState(() {
              readyFollowUp = false;
              nodataNew = true;
              nodataContacting = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }
          getFollowUpData();
          break;
        case 'Unqualified':
          if (this.mounted) {
            setState(() {
              readyUnqualified = false;
              nodataNew = true;
              nodataContacting = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataBadInfo = true;
              nodataNoResponse = true;
            });
          }
          getUnqualifiedData();
          break;
        case 'Bad Information':
          if (this.mounted) {
            setState(() {
              readyBadInfo = false;
              nodataNew = true;
              nodataContacting = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataNoResponse = true;
            });
          }
          getBadInfoData();
          break;
        default:
          if (this.mounted) {
            setState(() {
              readyNoResponse = false;
              nodataNew = true;
              nodataContacting = true;
              nodataContacted = true;
              nodataQualified = true;
              nodataConverted = true;
              nodataFollowUp = true;
              nodataUnqualified = true;
              nodataBadInfo = true;
            });
          }
          getNoResponseData();
      }
    } else {
      FocusScope.of(context).requestFocus(new FocusNode());
      if (this.mounted) {
        setState(() {
          total = null;
          nodata = nodataNew = nodataContacting = nodataContacted =
              nodataQualified = nodataConverted = nodataFollowUp =
                  nodataUnqualified = nodataBadInfo = nodataNoResponse = false;
          readyNew = readyContacting = readyContacted = readyQualified =
              readyConverted = readyFollowUp =
                  readyUnqualified = readyBadInfo = readyNoResponse = false;
        });
      }
      getNewData();
      getContactingData();
      getContactedData();
      getQualifiedData();
      getConvertedData();
      getFollowUpData();
      getUnqualifiedData();
      getBadInfoData();
      getNoResponseData();
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      Navigator.pop(context);
      startDate = _startDate.toString().substring(0, 10);
      endDate = _endDate.toString().substring(0, 10);
      for (int i = 0; i < linksID.length; i++) {
        if (_byLink == linksID[i].link_type + linksID[i].link) {
          link_id = linksID[i].link_type + linksID[i].link_id;
        }
      }
      if (level == '0' && _byBranch != 'All Branch') {
        for (var branch in branchesList) {
          if (_byBranch == branch.branchName) {
            branchID = branch.branchID;
          }
        }
      }
      http.post(urlVData, body: {
        "companyID": companyID,
        "branchID": branchID,
        "level": level,
        "userID": userID,
        "user_type": userType,
        "startDate": startDate,
        "endDate": endDate,
        "type": type,
        "channel": channel,
        "apps": apps,
        "link_id": link_id,
        "status": _byStatus,
        "executive": _byExecutive,
        "vtag": _byVTag,
        "search": search,
        "count": "0",
        "offline": "no"
      }).then((res) {
        // print("_done body: " + res.body.toString());
        if (res.body == "nodata") {
          if (this.mounted) {
            setState(() {
              vDataDetails.clear();
              connection = true;
              nodata = true;
              total = 0;
            });
          }
        } else {
          var jsonData = json.decode(res.body);
          if (this.mounted) {
            setState(() {
              total = jsonData[0]['total'];
            });
          }
          vDataDetails.clear();
          for (var data in jsonData) {
            VDataDetails vdata = VDataDetails(
              date: data['date'],
              name: data['name'] ?? "",
              phoneNo: data['phone_number'],
              email: data['email'] ?? '',
              remark: data['remark'] ?? "-",
              status: checkStatus(data['status']),
              type: data['type'],
              app: data['app'],
              channel: data['channel'],
              link: data['link_type'] ?? "" + data['link'],
              handler: data['link'],
            );
            vDataDetails.add(vdata);
          }
          if (this.mounted) {
            setState(() {
              connection = true;
            });
          }
        }
      }).catchError((err) {
        print("Filter error: " + (err).toString());
      });
    } else {
      _toast("Please check your internet connection");
    }
  }

  Future<void> _search(String value) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    if (this.mounted) {
      setState(() {
        total = null;
        search = value.toLowerCase();
        nodata = nodataNew = nodataContacting = nodataContacted =
            nodataQualified = nodataConverted = nodataFollowUp =
                nodataUnqualified = nodataBadInfo = nodataNoResponse = false;
        readyNew = readyContacting = readyContacted = readyQualified =
            readyConverted = readyFollowUp =
                readyUnqualified = readyBadInfo = readyNoResponse = false;
      });
    }
    getNewData();
    getContactingData();
    getContactedData();
    getQualifiedData();
    getConvertedData();
    getFollowUpData();
    getUnqualifiedData();
    getBadInfoData();
    getNoResponseData();
    if (connection == true) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.mobile) {
        if (level == '0' && _byBranch != 'All Branch') {
          for (var branch in branchesList) {
            if (_byBranch == branch.branchName) {
              branchID = branch.branchID;
            }
          }
        }
        http.post(urlVData, body: {
          "companyID": companyID,
          "branchID": branchID,
          "level": level,
          "userID": userID,
          "user_type": userType,
          "startDate": _startDate.toString().substring(0, 10),
          "endDate": _endDate.toString().substring(0, 10),
          "type": type,
          "channel": channel,
          "apps": apps,
          "link_id": link_id,
          "status": _byStatus,
          "executive": _byExecutive,
          "vtag": _byVTag,
          "search": search,
          "count": "0",
          "offline": "no"
        }).then((res) {
          // print("Search body: " + res.body.toString());
          if (res.body == "nodata") {
            if (this.mounted) {
              setState(() {
                vDataDetails.clear();
                connection = true;
                nodata = true;
                total = 0;
              });
            }
          } else {
            var jsonData = json.decode(res.body);
            if (this.mounted) {
              setState(() {
                total = jsonData[0]['total'];
              });
            }
            vDataDetails.clear();
            for (var data in jsonData) {
              VDataDetails vdata = VDataDetails(
                date: data['date'],
                name: data['name'] ?? "",
                phoneNo: data['phone_number'],
                email: data['email'] ?? '',
                remark: data['remark'] ?? "-",
                status: checkStatus(data['status']),
                type: data['type'],
                app: data['app'],
                channel: data['channel'],
                link: data['link_type'] ?? "" + data['link'],
                handler: data['link'],
              );
              vDataDetails.add(vdata);
            }
            if (this.mounted) {
              setState(() {
                connection = true;
              });
            }
          }
        }).catchError((err) {
          _toast("Something wrong, please contact VVIN IT deesk");
          print("Search error: " + (err).toString());
        });
      } else {
        _toast("Please check your Internet Connection");
      }
    } else {
      offlineVData = await vdataDB.rawQuery(
          "SELECT * FROM vdata WHERE name LIKE '%" +
              value +
              "%' OR phone LIKE '%" +
              value +
              "%' OR remark LIKE '%" +
              value +
              "%' OR status LIKE '%" +
              value +
              "%'");
      if (this.mounted) {
        setState(() {
          connection = false;
        });
      }
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
