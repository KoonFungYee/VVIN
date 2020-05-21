import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:badges/badges.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:intl/intl.dart';
import 'package:vvin/reminder.dart';
import 'package:ndialog/ndialog.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/data.dart';
import 'package:vvin/leadsDB.dart';
import 'package:vvin/lineChart.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/more.dart';
import 'package:vvin/myworks.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/topViewDB.dart';
import 'package:vvin/vanalyticsDB.dart';
import 'package:vvin/vdata.dart';
import 'package:vvin/vdataNoHandler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vvin/vprofile.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

final ScrollController controller = ScrollController();

class VAnalytics extends StatefulWidget {
  final String name;
  final String url;
  const VAnalytics({Key key, this.name, this.url}) : super(key: key);

  @override
  _VAnalyticsState createState() => _VAnalyticsState();
}

enum UniLinksType { string, uri }

class _VAnalyticsState extends State<VAnalytics>
    with SingleTickerProviderStateMixin {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  AnimationController animatedController;
  Animation dateBar, leadsChart, total, top10;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  GlobalKey<RefreshIndicatorState> refreshKey;
  List<Map> offlineVAnalyticsData;
  List<Map> offlineTopViewData;
  List<Map> offlineChartData;
  DateTime _startDate, _endDate, prevDate, _startDatePicker;
  List<TopView> topViews = [];
  List<LeadData> leadsDatas = [];
  List<LeadData> offlineLeadsDatas = [];
  SharedPreferences prefs;
  String dateBanner,
      companyID,
      level,
      userID,
      userType,
      startDate,
      _startdate,
      endDate,
      _enddate,
      totalLeads,
      totalLeadsPercentage,
      unassignedLeads,
      newLeads,
      contactingLeads,
      contactedLeads,
      qualifiedLeads,
      convertedLeads,
      followupLeads,
      unqualifiedLeads,
      badInfoLeads,
      noResponseLeads,
      vflex,
      vcard,
      vcatelogue,
      vbot,
      vhome,
      messenger,
      whatsappForward,
      import,
      contactForm,
      minimumDate,
      dateBannerLocal,
      currentVersion,
      newVersion,
      now,
      totalNotification;
  String urlNoti = "https://vvinoa.vvin.com/api/notiTotalNumber.php";
  String urlVAnalytics = "https://vvinoa.vvin.com/api/vanalytics.php";
  String urlTopViews = "https://vvinoa.vvin.com/api/topview.php";
  String urlLeads = "https://vvinoa.vvin.com/api/leads.php";
  String urlGetReminder = "https://vvinoa.vvin.com/api/getreminder.php";
  int load, startTime, endTime, currentTabIndex;
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
  double font25 = ScreenUtil().setSp(57.5, allowFontScalingSelf: false);
  bool connection,
      nodata,
      positive,
      timeBar,
      topView,
      vanalytic,
      chartData,
      refresh,
      editor;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    try {
      if (widget.name != null) {
        BotToast.showText(
          text: "Welcome " + widget.name,
          wrapToastAnimation: (controller, cancel, Widget child) =>
              CustomAnimationWidget(
            controller: controller,
            child: child,
          ),
        );
      }
    } catch (e) {}
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
    );
    refreshKey = GlobalKey<RefreshIndicatorState>();
    newVersion = "";
    totalNotification = "0";
    currentTabIndex = 0;
    editor = false;
    connection = false;
    nodata = false;
    refresh = false;
    load = 0;
    _initialize();
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {});
    animatedController =
        AnimationController(duration: Duration(seconds: 1), vsync: this);
    dateBar = Tween(begin: -0.2, end: 0.0).animate(CurvedAnimation(
        curve: Curves.fastOutSlowIn, parent: animatedController));
    leadsChart = Tween(begin: -0.5, end: 0.0).animate(CurvedAnimation(
        curve: Curves.fastOutSlowIn, parent: animatedController));
    total = Tween(begin: -0.8, end: 0.0).animate(CurvedAnimation(
        curve: Curves.fastOutSlowIn, parent: animatedController));
    top10 = Tween(begin: -1.1, end: 0.0).animate(CurvedAnimation(
        curve: Curves.fastOutSlowIn, parent: animatedController));
    super.initState();
  }

  void onTapped(int index) {
    if (index != 0) {
      switch (index) {
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
  dispose() {
    if (_sub != null) _sub.cancel();
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    final deviceWidth = MediaQuery.of(context).size.width;
    YYDialog.init(context);
    return AnimatedBuilder(
        animation: animatedController,
        builder: (BuildContext context, Widget child) {
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
                        fontSize:
                            ScreenUtil().setSp(24, allowFontScalingSelf: false),
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
                        fontSize:
                            ScreenUtil().setSp(24, allowFontScalingSelf: false),
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
                        fontSize:
                            ScreenUtil().setSp(24, allowFontScalingSelf: false),
                      ),
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: (totalNotification != "0")
                        ? Badge(
                            position:
                                BadgePosition.topRight(top: -8, right: -5),
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
                        fontSize:
                            ScreenUtil().setSp(24, allowFontScalingSelf: false),
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
                        fontSize:
                            ScreenUtil().setSp(24, allowFontScalingSelf: false),
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
                    "VAnalytics",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: font18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              body: (editor == true)
                  ? Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              "You have no permission to enter this page",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                                fontSize: ScreenUtil()
                                    .setSp(35, allowFontScalingSelf: false),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      key: refreshKey,
                      onRefresh: _handleRefresh,
                      child: SingleChildScrollView(
                        controller: controller,
                        child: (timeBar == true &&
                                topView == true &&
                                vanalytic == true &&
                                chartData == true)
                            ? Column(
                                children: <Widget>[
                                  Transform(
                                    transform: Matrix4.translationValues(
                                        dateBar.value * deviceWidth, 0.0, 0.0),
                                    child: InkWell(
                                      onTap: () async {
                                        var connectivityResult =
                                            await (Connectivity()
                                                .checkConnectivity());
                                        if (connectivityResult ==
                                                ConnectivityResult.wifi ||
                                            connectivityResult ==
                                                ConnectivityResult.mobile) {
                                          _filterDate();
                                        } else {
                                          _noInternet();
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(100),
                                        ),
                                        height: ScreenUtil().setHeight(60),
                                        margin: EdgeInsets.all(
                                          ScreenUtil().setHeight(20),
                                        ),
                                        padding: EdgeInsets.all(
                                          ScreenUtil().setHeight(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Expanded(
                                                    child: Text(
                                                      (connection == true)
                                                          ? dateBanner
                                                          : dateBannerLocal,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: font14,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform(
                                    transform: Matrix4.translationValues(
                                        leadsChart.value * deviceWidth,
                                        0.0,
                                        0.0),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        ScreenUtil().setHeight(10),
                                      ),
                                      color: Colors.white,
                                      margin: EdgeInsets.fromLTRB(
                                        ScreenUtil().setHeight(20),
                                        0,
                                        ScreenUtil().setHeight(20),
                                        ScreenUtil().setHeight(20),
                                      ),
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                              ScreenUtil().setHeight(20),
                                              0,
                                              0,
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Leads",
                                                    style: TextStyle(
                                                      fontSize: font16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                FlatButton(
                                                  child: Icon(
                                                    Icons.aspect_ratio,
                                                    size: ScreenUtil()
                                                        .setHeight(50),
                                                  ),
                                                  shape: CircleBorder(
                                                      side: BorderSide(
                                                          color: Colors
                                                              .transparent)),
                                                  onPressed: () {
                                                    (connection == true)
                                                        ? Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) =>
                                                                    LineChart(
                                                                        leadsDatas:
                                                                            leadsDatas)))
                                                        : Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  LineChart(
                                                                      leadsDatas:
                                                                          offlineLeadsDatas),
                                                            ),
                                                          );
                                                  },
                                                )
                                              ],
                                            ),
                                          ),
                                          Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.3,
                                            child: SfCartesianChart(
                                              zoomPanBehavior: ZoomPanBehavior(
                                                  enablePinching: true),
                                              tooltipBehavior: TooltipBehavior(
                                                  enable: true,
                                                  header: "Total Leads"),
                                              primaryXAxis: CategoryAxis(),
                                              series: <ChartSeries>[
                                                LineSeries<LeadsData, String>(
                                                    enableTooltip: true,
                                                    dataSource:
                                                        (connection == true)
                                                            ? List.generate(
                                                                leadsDatas
                                                                    .length,
                                                                (index) {
                                                                return LeadsData(
                                                                    leadsDatas[
                                                                            index]
                                                                        .date,
                                                                    double.parse(
                                                                        leadsDatas[index]
                                                                            .number));
                                                              })
                                                            : List.generate(
                                                                offlineChartData
                                                                    .length,
                                                                (index) {
                                                                return LeadsData(
                                                                    offlineChartData[
                                                                            index]
                                                                        [
                                                                        'date'],
                                                                    double.parse(
                                                                        offlineChartData[index]
                                                                            [
                                                                            'number']));
                                                              }),
                                                    color: Colors.blue,
                                                    xValueMapper:
                                                        (LeadsData sales, _) =>
                                                            sales.x,
                                                    yValueMapper:
                                                        (LeadsData sales, _) =>
                                                            sales.y)
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Transform(
                                    transform: Matrix4.translationValues(
                                        total.value * deviceWidth, 0.0, 0.0),
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(
                                          ScreenUtil().setHeight(20),
                                          0,
                                          ScreenUtil().setHeight(20),
                                          0),
                                      child: Row(
                                        children: <Widget>[
                                          Flexible(
                                            flex: 1,
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(210),
                                              color: Colors.white,
                                              padding: EdgeInsets.all(
                                                ScreenUtil().setHeight(20),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      Text(
                                                        "Total Leads",
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: font14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      InkWell(
                                                        onTap: _totalLeads,
                                                        child: Text(
                                                          (connection == true)
                                                              ? totalLeads
                                                              : offlineVAnalyticsData[
                                                                      0][
                                                                  'total_leads'],
                                                          style: TextStyle(
                                                              fontSize: font25,
                                                              color:
                                                                  Colors.blue,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: ScreenUtil()
                                                        .setHeight(4),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      Text(
                                                        (connection == true)
                                                            ? totalLeadsPercentage
                                                            : offlineVAnalyticsData[
                                                                    0][
                                                                'total_leads_percentage'],
                                                        style: TextStyle(
                                                            fontSize: font14,
                                                            color: (positive ==
                                                                    true)
                                                                ? Colors
                                                                    .greenAccent
                                                                : Colors.red),
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: ScreenUtil().setHeight(20),
                                          ),
                                          Flexible(
                                            flex: 1,
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(210),
                                              color: Colors.white,
                                              padding: EdgeInsets.all(
                                                ScreenUtil().setHeight(20),
                                              ),
                                              child: Column(
                                                children: <Widget>[
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      Flexible(
                                                          child: Text(
                                                        "Unassigned Leads",
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: font14,
                                                        ),
                                                      ))
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      Text(
                                                        (connection == true)
                                                            ? unassignedLeads
                                                            : offlineVAnalyticsData[
                                                                    0][
                                                                'unassigned_leads'],
                                                        style: TextStyle(
                                                            fontSize: font25,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: ScreenUtil()
                                                        .setHeight(4),
                                                  ),
                                                  InkWell(
                                                    onTap: () async {
                                                      var connectivityResult =
                                                          await (Connectivity()
                                                              .checkConnectivity());
                                                      if (connectivityResult ==
                                                              ConnectivityResult
                                                                  .wifi ||
                                                          connectivityResult ==
                                                              ConnectivityResult
                                                                  .mobile) {
                                                        _assignedNow();
                                                      } else {
                                                        _noInternet();
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.fromLTRB(
                                                              0,
                                                              ScreenUtil()
                                                                  .setHeight(
                                                                      20),
                                                              ScreenUtil()
                                                                  .setHeight(
                                                                      10),
                                                              0),
                                                      child: Row(
                                                        children: <Widget>[
                                                          Text(
                                                            "Assign now",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.blue,
                                                              fontSize: font12,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: ScreenUtil()
                                                                .setHeight(6),
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .arrow_forward_ios,
                                                            size: ScreenUtil()
                                                                .setHeight(20),
                                                            color: Colors.blue,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.all(
                                      ScreenUtil().setHeight(20),
                                    ),
                                    child: Column(
                                      children: <Widget>[
                                        Transform(
                                          transform: Matrix4.translationValues(
                                              top10.value * deviceWidth,
                                              0.0,
                                              0.0),
                                          child: Column(
                                            children: <Widget>[
                                              Container(
                                                padding: EdgeInsets.all(
                                                  ScreenUtil().setHeight(20),
                                                ),
                                                color: Colors.white,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      "Top 10 Views",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: font16,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                child: (nodata == true)
                                                    ? Container(
                                                        height: ScreenUtil()
                                                            .setHeight(155),
                                                        child: Stack(
                                                          children: <Widget>[
                                                            Container(
                                                              color:
                                                                  Colors.white,
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.45,
                                                              child: ListView(
                                                                scrollDirection:
                                                                    Axis.vertical,
                                                                children: <
                                                                    Widget>[
                                                                  Column(
                                                                    children: <
                                                                        Widget>[
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.start,
                                                                        children: <
                                                                            Widget>[
                                                                          Container(
                                                                            width:
                                                                                MediaQuery.of(context).size.width * 0.45,
                                                                            padding:
                                                                                EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Color.fromRGBO(235, 235, 255, 1),
                                                                              border: Border(
                                                                                right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                              ),
                                                                            ),
                                                                            child:
                                                                                Text(
                                                                              "Name",
                                                                              style: TextStyle(
                                                                                color: Colors.grey,
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: font14,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      Container(
                                                                        height:
                                                                            ScreenUtil().setHeight(70),
                                                                        padding:
                                                                            EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              Colors.white,
                                                                          border:
                                                                              Border(
                                                                            right:
                                                                                BorderSide(width: 1, color: Colors.grey.shade300),
                                                                          ),
                                                                        ),
                                                                      )
                                                                    ],
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            Container(
                                                              color:
                                                                  Colors.white,
                                                              margin: EdgeInsets
                                                                  .fromLTRB(
                                                                MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.45,
                                                                0,
                                                                0,
                                                                0,
                                                              ),
                                                              child: Theme(
                                                                data: ThemeData(
                                                                  highlightColor:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                                child: Scrollbar(
                                                                    child: ListView(
                                                                  scrollDirection:
                                                                      Axis.horizontal,
                                                                  children: <
                                                                      Widget>[
                                                                    Column(
                                                                      children: <
                                                                          Widget>[
                                                                        Container(
                                                                          width:
                                                                              ScreenUtil().setWidth(345),
                                                                          padding:
                                                                              EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color: Color.fromRGBO(
                                                                                235,
                                                                                235,
                                                                                255,
                                                                                1),
                                                                            border:
                                                                                Border(
                                                                              right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            "Status",
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: font14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          height:
                                                                              ScreenUtil().setHeight(70),
                                                                          width:
                                                                              ScreenUtil().setWidth(345),
                                                                          padding:
                                                                              EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.white,
                                                                            border:
                                                                                Border(
                                                                              right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    Column(
                                                                      children: <
                                                                          Widget>[
                                                                        Container(
                                                                          width:
                                                                              ScreenUtil().setWidth(330),
                                                                          padding:
                                                                              EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color: Color.fromRGBO(
                                                                                235,
                                                                                235,
                                                                                255,
                                                                                1),
                                                                            border:
                                                                                Border(
                                                                              right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            "Channel",
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: font14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          height:
                                                                              ScreenUtil().setHeight(70),
                                                                          width:
                                                                              ScreenUtil().setWidth(330),
                                                                          padding:
                                                                              EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.white,
                                                                            border:
                                                                                Border(
                                                                              right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                    Column(
                                                                      children: <
                                                                          Widget>[
                                                                        Container(
                                                                          width:
                                                                              ScreenUtil().setWidth(180),
                                                                          padding:
                                                                              EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color: Color.fromRGBO(
                                                                                235,
                                                                                235,
                                                                                255,
                                                                                1),
                                                                            border:
                                                                                Border(
                                                                              right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            "Views",
                                                                            style:
                                                                                TextStyle(
                                                                              color: Colors.grey,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: font14,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          height:
                                                                              ScreenUtil().setHeight(70),
                                                                          width:
                                                                              ScreenUtil().setWidth(180),
                                                                          padding:
                                                                              EdgeInsets.all(ScreenUtil().setHeight(20)),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.white,
                                                                            border:
                                                                                Border(
                                                                              right: BorderSide(width: 1, color: Colors.grey.shade300),
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    )
                                                                  ],
                                                                )),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Container(
                                                        height: (connection ==
                                                                true)
                                                            ? ScreenUtil()
                                                                .setHeight(85 +
                                                                    77 *
                                                                        topViews
                                                                            .length)
                                                            : ScreenUtil()
                                                                .setHeight(85 +
                                                                    77 *
                                                                        offlineTopViewData
                                                                            .length),
                                                        child: Stack(
                                                          children: <Widget>[
                                                            Container(
                                                              color:
                                                                  Colors.white,
                                                              width: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width *
                                                                  0.45,
                                                              child:
                                                                  (connection ==
                                                                          true)
                                                                      ? Column(
                                                                          children:
                                                                              _topViewLength(),
                                                                        )
                                                                      : Column(
                                                                          children:
                                                                              _offLinetopViewLength(),
                                                                        ),
                                                            ),
                                                            Container(
                                                              color:
                                                                  Colors.white,
                                                              margin: EdgeInsets
                                                                  .fromLTRB(
                                                                MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width *
                                                                    0.45,
                                                                0,
                                                                0,
                                                                0,
                                                              ),
                                                              child: Theme(
                                                                data: ThemeData(
                                                                  highlightColor:
                                                                      Colors
                                                                          .blue,
                                                                ),
                                                                child:
                                                                    Scrollbar(
                                                                  child: (connection ==
                                                                          true)
                                                                      ? ListView(
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          children: <
                                                                              Widget>[
                                                                            Column(
                                                                              children: _status(),
                                                                            ),
                                                                            Column(
                                                                              children: _channel(),
                                                                            ),
                                                                            Column(
                                                                              children: _view(),
                                                                            )
                                                                          ],
                                                                        )
                                                                      : ListView(
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          children: <
                                                                              Widget>[
                                                                            Column(
                                                                              children: _offlineStatus(),
                                                                            ),
                                                                            Column(
                                                                              children: _offlineChannel(),
                                                                            ),
                                                                            Column(
                                                                              children: _offlineViews(),
                                                                            )
                                                                          ],
                                                                        ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.fromLTRB(0,
                                              ScreenUtil().setHeight(20), 0, 0),
                                          padding: EdgeInsets.all(
                                            ScreenUtil().setHeight(20),
                                          ),
                                          color: Colors.white,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                "Leads Status",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: font16,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: ScreenUtil().setHeight(2),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("New");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Colors.white,
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "New",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? newLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['new_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Contacting");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Color.fromRGBO(
                                                232, 244, 248, 1),
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Contacting",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? contactingLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['contacting_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Contacted");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Colors.white,
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Contacted",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? contactedLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['contacted_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Qualified");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Color.fromRGBO(
                                                232, 244, 248, 1),
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Qualified",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? qualifiedLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['qualified_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Converted");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Colors.white,
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Converted",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? convertedLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['converted_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Follow-up");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Color.fromRGBO(
                                                232, 244, 248, 1),
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Follow-up",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? followupLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['followup_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Unqualified");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Colors.white,
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Unqualified",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? unqualifiedLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['unqualified_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("Bad Information");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Color.fromRGBO(
                                                232, 244, 248, 1),
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "Bad Information",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? badInfoLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['bad_info_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            var connectivityResult =
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                    ConnectivityResult.wifi ||
                                                connectivityResult ==
                                                    ConnectivityResult.mobile) {
                                              _leadsStatus("No Response");
                                            } else {
                                              _noInternet();
                                            }
                                          },
                                          child: Container(
                                            color: Colors.white,
                                            padding: EdgeInsets.all(
                                              ScreenUtil().setHeight(20),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    "No Response",
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: font14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  (connection == true)
                                                      ? noResponseLeads
                                                      : offlineVAnalyticsData[0]
                                                          ['no_response_leads'],
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: font14,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: ScreenUtil().setHeight(20),
                                        ),
                                        Container(
                                          color: Colors.white,
                                          height: ScreenUtil().setHeight(820),
                                          child: SfCircularChart(
                                            onPointTapped: (PointTapArgs args) {
                                              _redirectAppChart(
                                                  args.pointIndex);
                                            },
                                            // tooltipBehavior: TooltipBehavior(enable: true),
                                            // Enables the legend
                                            legend: Legend(
                                                title: LegendTitle(
                                                    text: "App",
                                                    textStyle: ChartTextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: font16,
                                                    )),
                                                isVisible: true,
                                                overflowMode:
                                                    LegendItemOverflowMode
                                                        .wrap),
                                            series: <CircularSeries>[
                                              PieSeries<AppData, String>(
                                                enableSmartLabels: true,
                                                dataSource: [
                                                  AppData(
                                                      'VFlex',
                                                      (connection == true)
                                                          ? double.parse(vflex)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                  0]['vflex']),
                                                      Color.fromRGBO(
                                                          175, 238, 238, 1)),
                                                  AppData(
                                                      'VCard',
                                                      (connection == true)
                                                          ? double.parse(vcard)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                  0]['vcard']),
                                                      Color.fromRGBO(
                                                          0, 0, 205, 1)),
                                                  AppData(
                                                      'VCatelogue',
                                                      (connection == true)
                                                          ? double.parse(
                                                              vcatelogue)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                      0][
                                                                  'vcatelogue']),
                                                      Color.fromRGBO(
                                                          30, 144, 255, 1)),
                                                  AppData(
                                                      'VBot',
                                                      (connection == true)
                                                          ? double.parse(vbot)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                  0]['vbot']),
                                                      Color.fromRGBO(
                                                          0, 128, 255, 1)),
                                                  AppData(
                                                      'VHome',
                                                      (connection == true)
                                                          ? double.parse(vhome)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                  0]['vhome']),
                                                      Color.fromRGBO(
                                                          15, 128, 196, 1)),
                                                ],
                                                pointColorMapper:
                                                    (AppData data, _) =>
                                                        data.color,
                                                xValueMapper:
                                                    (AppData data, _) => data.x,
                                                yValueMapper:
                                                    (AppData data, _) => data.y,
                                                dataLabelSettings:
                                                    DataLabelSettings(
                                                        isVisible: true,
                                                        labelPosition:
                                                            LabelPosition
                                                                .inside),
                                              )
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: ScreenUtil().setHeight(20),
                                        ),
                                        Container(
                                          height: ScreenUtil().setHeight(820),
                                          color: Colors.white,
                                          child: SfCircularChart(
                                            onPointTapped: (PointTapArgs args) {
                                              _redirectChannelChart(
                                                  args.pointIndex);
                                            },
                                            // tooltipBehavior: TooltipBehavior(enable: true),
                                            // Enables the legend
                                            legend: Legend(
                                                title: LegendTitle(
                                                    text: "Channel",
                                                    textStyle: ChartTextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: font16,
                                                    )),
                                                isVisible: true,
                                                overflowMode:
                                                    LegendItemOverflowMode
                                                        .wrap),
                                            series: <CircularSeries>[
                                              PieSeries<ChannelData, String>(
                                                enableSmartLabels: true,
                                                dataSource: [
                                                  ChannelData(
                                                      'WhatsApp Forward',
                                                      (connection == true)
                                                          ? double.parse(
                                                              whatsappForward)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                      0][
                                                                  'whatsapp_forward']),
                                                      Color.fromRGBO(
                                                          72, 209, 204, 1)),
                                                  ChannelData(
                                                      'Contact Form',
                                                      (connection == true)
                                                          ? double.parse(
                                                              contactForm)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                      0][
                                                                  'contact_form']),
                                                      Color.fromRGBO(
                                                          255, 165, 0, 1)),
                                                  ChannelData(
                                                      'Messenger',
                                                      (connection == true)
                                                          ? double.parse(
                                                              messenger)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                      0][
                                                                  'messenger']),
                                                      Color.fromRGBO(
                                                          135, 206, 250, 1)),
                                                  ChannelData(
                                                      'Import',
                                                      (connection == true)
                                                          ? double.parse(import)
                                                          : double.parse(
                                                              offlineVAnalyticsData[
                                                                  0]['import']),
                                                      Color.fromRGBO(
                                                          225, 225, 255, 1)),
                                                ],
                                                pointColorMapper:
                                                    (ChannelData data, _) =>
                                                        data.color,
                                                xValueMapper:
                                                    (ChannelData data, _) =>
                                                        data.x,
                                                yValueMapper:
                                                    (ChannelData data, _) =>
                                                        data.y,
                                                dataLabelSettings:
                                                    DataLabelSettings(
                                                        isVisible: true,
                                                        labelPosition:
                                                            LabelPosition
                                                                .inside),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            : Container(
                                height:
                                    MediaQuery.of(context).size.height * 0.8,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      JumpingText('Loading...'),
                                      SizedBox(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.02),
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
            ),
          );
        });
  }

  List<Widget> _topViewLength() {
    List widgetList = <Widget>[];
    for (var i = 0; i < topViews.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * 0.45,
                  padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(235, 235, 255, 1),
                    border: Border(
                      right: BorderSide(width: 1, color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "Name",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: font14,
                    ),
                  ),
                ),
              ],
            )
          : widget1 = InkWell(
              onTap: () async {
                var connectivityResult =
                    await (Connectivity().checkConnectivity());
                if (connectivityResult == ConnectivityResult.wifi ||
                    connectivityResult == ConnectivityResult.mobile) {
                  _redirectVProfile(i - 1);
                } else {
                  _noInternet();
                }
              },
              child: Container(
                height: (i == topViews.length)
                    ? ScreenUtil().setHeight(80)
                    : ScreenUtil().setHeight(77),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                        width: ScreenUtil().setWidth(2),
                        color: Colors.grey.shade300),
                  ),
                ),
                padding: EdgeInsets.all(
                  ScreenUtil().setHeight(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      topViews[i - 1].name,
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: font14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _offLinetopViewLength() {
    List widgetList = <Widget>[];
    for (var i = 0; i < offlineTopViewData.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * 0.45,
                  padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(235, 235, 255, 1),
                    border: Border(
                      right: BorderSide(width: 1, color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "Name",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: font14,
                    ),
                  ),
                ),
              ],
            )
          : widget1 = Container(
              height: (i == offlineTopViewData.length)
                  ? ScreenUtil().setHeight(80)
                  : ScreenUtil().setHeight(77),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                      width: ScreenUtil().setWidth(2),
                      color: Colors.grey.shade300),
                ),
              ),
              padding: EdgeInsets.all(
                ScreenUtil().setHeight(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text(
                    (connection == true)
                        ? topViews[i - 1].name
                        : offlineTopViewData[i - 1]['name'],
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: font14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _status() {
    List widgetList = <Widget>[];
    for (var i = 0; i < topViews.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Container(
              width: ScreenUtil().setWidth(345),
              padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
              decoration: BoxDecoration(
                color: Color.fromRGBO(235, 235, 255, 1),
                border: Border(
                  right: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "Status",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: font14,
                ),
              ),
            )
          : widget1 = Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: ScreenUtil().setHeight(77),
                  width: ScreenUtil().setWidth(345),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  padding: EdgeInsets.all(
                    ScreenUtil().setHeight(20),
                  ),
                  child: Text(
                    topViews[i - 1].status,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: font14,
                    ),
                  ),
                ),
              ],
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _channel() {
    List widgetList = <Widget>[];
    for (var i = 0; i < topViews.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Container(
              width: ScreenUtil().setWidth(345),
              padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
              decoration: BoxDecoration(
                color: Color.fromRGBO(235, 235, 255, 1),
                border: Border(
                  right: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "Channel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: font14,
                ),
              ),
            )
          : widget1 = Container(
              height: ScreenUtil().setHeight(77),
              width: ScreenUtil().setWidth(345),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                      width: ScreenUtil().setHeight(2),
                      color: Colors.grey.shade300),
                ),
              ),
              padding: EdgeInsets.all(
                ScreenUtil().setHeight(20),
              ),
              child: Text(
                topViews[i - 1].channel,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: font14,
                ),
              ),
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _view() {
    List widgetList = <Widget>[];
    for (var i = 0; i < topViews.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Container(
              width: ScreenUtil().setWidth(180),
              padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
              decoration: BoxDecoration(
                color: Color.fromRGBO(235, 235, 255, 1),
                border: Border(
                  right: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "Views",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: font14,
                ),
              ),
            )
          : widget1 = Container(
              height: ScreenUtil().setHeight(77),
              width: ScreenUtil().setWidth(180),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                      width: ScreenUtil().setHeight(2),
                      color: Colors.grey.shade300),
                ),
              ),
              padding: EdgeInsets.all(
                ScreenUtil().setHeight(20),
              ),
              child: Text(
                topViews[i - 1].views,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: font14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _offlineStatus() {
    List widgetList = <Widget>[];
    for (var i = 0; i < offlineTopViewData.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Container(
              width: ScreenUtil().setWidth(345),
              padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
              decoration: BoxDecoration(
                color: Color.fromRGBO(235, 235, 255, 1),
                border: Border(
                  right: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "Status",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: font14,
                ),
              ),
            )
          : widget1 = Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: ScreenUtil().setHeight(77),
                  width: ScreenUtil().setWidth(345),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  padding: EdgeInsets.all(
                    ScreenUtil().setHeight(20),
                  ),
                  child: Text(
                    offlineTopViewData[i - 1]['status'],
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: font14,
                    ),
                  ),
                ),
              ],
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _offlineChannel() {
    List widgetList = <Widget>[];
    for (var i = 0; i < offlineTopViewData.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Container(
              width: ScreenUtil().setWidth(345),
              padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
              decoration: BoxDecoration(
                color: Color.fromRGBO(235, 235, 255, 1),
                border: Border(
                  right: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "Status",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: font14,
                ),
              ),
            )
          : widget1 = Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: ScreenUtil().setHeight(77),
                  width: ScreenUtil().setWidth(345),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          width: ScreenUtil().setHeight(2),
                          color: Colors.grey.shade300),
                    ),
                  ),
                  padding: EdgeInsets.all(
                    ScreenUtil().setHeight(20),
                  ),
                  child: Text(
                    offlineTopViewData[i - 1]['status'],
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: font14,
                    ),
                  ),
                ),
              ],
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _offlineViews() {
    List widgetList = <Widget>[];
    for (var i = 0; i < offlineTopViewData.length + 1; i++) {
      Widget widget1;
      (i == 0)
          ? widget1 = Container(
              width: ScreenUtil().setWidth(180),
              padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
              decoration: BoxDecoration(
                color: Color.fromRGBO(235, 235, 255, 1),
                border: Border(
                  right: BorderSide(width: 1, color: Colors.grey.shade300),
                ),
              ),
              child: Text(
                "Views",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: font14,
                ),
              ),
            )
          : widget1 = Container(
              height: ScreenUtil().setHeight(77),
              width: ScreenUtil().setWidth(180),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                      width: ScreenUtil().setHeight(2),
                      color: Colors.grey.shade300),
                ),
              ),
              padding: EdgeInsets.all(
                ScreenUtil().setHeight(20),
              ),
              child: Text(
                offlineTopViewData[i - 1]['views'],
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: font14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  void _redirectVProfile(int position) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      VDataDetails vdata = new VDataDetails(
        companyID: companyID,
        userID: userID,
        level: level,
        userType: userType,
        name: topViews[position].name,
        phoneNo: topViews[position].phoneNo,
        status: topViews[position].status,
      );
      Navigator.of(context).push(PageRouteTransition(
          animationType: AnimationType.scale,
          builder: (context) => VProfile(vdata: vdata)));
    } else {
      _toast("No Internet Connection!");
    }
  }

  void _redirectAppChart(int position) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      String app;
      switch (position) {
        case 0:
          app = "VFlex";
          break;
        case 1:
          app = "VCard";
          break;
        case 2:
          app = "VCatalogue";
          break;
        case 3:
          app = "VBot";
          break;
        case 4:
          app = "VHome";
          break;
      }

      VDataFilter vDataFilter = VDataFilter(
          startDate: startDate,
          endDate: endDate,
          type: "all",
          status: "All Status",
          app: app,
          channel: "all");
      Navigator.of(context).pushReplacement(PageTransition(
        duration: Duration(milliseconds: 1),
        type: PageTransitionType.transferUp,
        child: VDataNoHandler(
          vDataFilter: vDataFilter,
        ),
      ));
    } else {
      _toast("No Internet Connection!");
    }
  }

  void _redirectChannelChart(int position) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      String channel;
      switch (position) {
        case 0:
          channel = "whatsApp forward";
          break;
        case 1:
          channel = "contact form";
          break;
        case 2:
          channel = "messenger";
          break;
        case 3:
          channel = "import";
          break;
      }
      VDataFilter vDataFilter = VDataFilter(
          startDate: startDate,
          endDate: endDate,
          type: "all",
          status: "All Status",
          app: "All",
          channel: channel);
      Navigator.of(context).pushReplacement(PageTransition(
        duration: Duration(milliseconds: 1),
        type: PageTransitionType.transferUp,
        child: VDataNoHandler(
          vDataFilter: vDataFilter,
        ),
      ));
    } else {
      _toast("No Internet Connection!");
    }
  }

  Future<bool> _onBackPressAppBar() async {
    YYAlertDialogWithScaleIn();
    return Future.value(false);
  }

  void _assignedNow() {
    VDataFilter vDataFilter = VDataFilter(
        startDate: startDate,
        endDate: endDate,
        type: "unassigned",
        status: "All Status",
        app: "All",
        channel: "all");
    Navigator.of(context).pushReplacement(PageTransition(
      duration: Duration(milliseconds: 1),
      type: PageTransitionType.transferUp,
      child: VDataNoHandler(
        vDataFilter: vDataFilter,
      ),
    ));
  }

  void _totalLeads() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      VDataFilter vDataFilter = VDataFilter(
          startDate: startDate,
          endDate: endDate,
          type: "all",
          status: "All Status",
          app: "All",
          channel: "all");
      Navigator.of(context).pushReplacement(PageTransition(
        duration: Duration(milliseconds: 1),
        type: PageTransitionType.transferUp,
        child: VDataNoHandler(
          vDataFilter: vDataFilter,
        ),
      ));
    } else {
      _noInternet();
    }
  }

  void _leadsStatus(String status) {
    VDataFilter vDataFilter = VDataFilter(
        startDate: startDate,
        endDate: endDate,
        type: "all",
        status: status,
        app: "All",
        channel: "all");
    Navigator.of(context).pushReplacement(PageTransition(
      duration: Duration(milliseconds: 1),
      type: PageTransitionType.transferUp,
      child: VDataNoHandler(
        vDataFilter: vDataFilter,
      ),
    ));
  }

  void _filterDate() {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(width: 1, color: Colors.grey.shade300),
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
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: ScrollPhysics(),
                    child: Container(
                      padding: EdgeInsets.all(
                        ScreenUtil().setHeight(20),
                      ),
                      child: Column(
                        children: <Widget>[
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
                            height: ScreenUtil().setHeight(4),
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(200),
                            child: CupertinoDatePicker(
                              minimumDate:
                                  DateFormat("yyyy-MM-dd").parse(minimumDate),
                              maximumDate: DateTime.now(),
                              mode: CupertinoDatePickerMode.date,
                              backgroundColor: Colors.transparent,
                              initialDateTime: _startDate,
                              onDateTimeChanged: (startDate) {
                                setModalState(() {
                                  _startDate = startDate;
                                  _startDatePicker = startDate;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(90),
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
                            height: ScreenUtil().setHeight(4),
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(200),
                            child: CupertinoDatePicker(
                              minimumDate: (_startDatePicker == null)
                                  ? DateFormat("yyyy-MM-dd").parse(minimumDate)
                                  : _startDatePicker,
                              maximumDate: DateTime.now(),
                              mode: CupertinoDatePickerMode.date,
                              backgroundColor: Colors.transparent,
                              initialDateTime: _endDate,
                              onDateTimeChanged: (endDate) {
                                setModalState(() {
                                  _endDate = endDate;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _noInternet() {
    _toast("This feature need Internet connection");
  }

  void _initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("noti") != null) {
      if (this.mounted) {
        setState(() {
          totalNotification = prefs.getString("noti");
        });
      }
      FlutterAppBadger.updateBadgeCount(int.parse(totalNotification));
    }
    if (prefs.getString("level") != "1") {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.mobile) {
        startTime = (DateTime.now()).millisecondsSinceEpoch;
        getPreference();
      } else {
        offline();
        _toast("No Internet, the data shown is not up to date");
      }
    } else {
      if (this.mounted) {
        setState(() {
          editor = true;
        });
      }
    }
  }

  Future<void> offline() async {
    Database vanalyticsDB = await VAnalyticsDB.instance.database;
    offlineVAnalyticsData = await vanalyticsDB.query(VAnalyticsDB.table);
    Database topViewDB = await TopViewDB.instance.database;
    offlineTopViewData = await topViewDB.query(TopViewDB.table);
    if (offlineTopViewData.length == 0) {
      if (this.mounted) {
        setState(() {
          nodata = true;
        });
      }
    }
    Database leadsDB = await LeadsDB.instance.database;
    offlineChartData = await leadsDB.query(LeadsDB.table);
    for (var data in offlineChartData) {
      LeadData leadsData = LeadData(
        date: data["date"],
        number: data["number"],
      );
      offlineLeadsDatas.add(leadsData);
    }
    String startDateLocal = offlineVAnalyticsData[0]['start_date'];
    String endDateLocal = offlineVAnalyticsData[0]['end_date'];
    String startYear = startDateLocal.toString().substring(0, 4);
    String endYear = endDateLocal.toString().substring(0, 4);
    String startMonth = checkMonth(startDateLocal.toString().substring(5, 7));
    String endMonth = checkMonth(endDateLocal.toString().substring(5, 7));
    String startDay = startDateLocal.toString().substring(8, 10);
    String endDay = endDateLocal.toString().substring(8, 10);
    dateBannerLocal = startMonth +
        " " +
        startDay +
        ", " +
        startYear +
        " - " +
        endMonth +
        " " +
        endDay +
        ", " +
        endYear;
    if (this.mounted) {
      setState(() {
        timeBar = true;
        topView = true;
        vanalytic = true;
        chartData = true;
      });
    }
    String number = offlineVAnalyticsData[0]['total_leads_percentage'];
    double percentage = double.parse(number.substring(1, number.length - 1));
    if (percentage >= 0) {
      positive = true;
    } else {
      positive = false;
    }
    animatedController.forward();
  }

  String checkMonth(String month) {
    String monthInEnglishFormat;
    switch (month) {
      case "01":
        monthInEnglishFormat = "Jan";
        break;

      case "02":
        monthInEnglishFormat = "Feb";
        break;

      case "03":
        monthInEnglishFormat = "Mar";
        break;

      case "04":
        monthInEnglishFormat = "Apr";
        break;

      case "05":
        monthInEnglishFormat = "May";
        break;

      case "06":
        monthInEnglishFormat = "Jun";
        break;

      case "07":
        monthInEnglishFormat = "Jul";
        break;

      case "08":
        monthInEnglishFormat = "Aug";
        break;

      case "09":
        monthInEnglishFormat = "Sep";
        break;

      case "10":
        monthInEnglishFormat = "Oct";
        break;

      case "11":
        monthInEnglishFormat = "Nov";
        break;

      case "12":
        monthInEnglishFormat = "Dec";
        break;
    }
    return monthInEnglishFormat;
  }

  Future<void> getPreference() async {
    prefs = await SharedPreferences.getInstance();
    companyID = prefs.getString('companyID');
    level = prefs.getString('level');
    userID = prefs.getString('userID');
    userType = prefs.getString('user_type');
    minimumDate = "2017-12-01";
    _startDate = DateTime(
        DateTime.now().year, DateTime.now().month - 1, DateTime.now().day + 1);
    _startdate = _startDate.toString();
    _endDate = DateTime.now();
    _enddate = _endDate.toString();
    startDate = _startDate.toString().substring(0, 10);
    endDate = _endDate.toString().substring(0, 10);
    setupDateTimeBar();
    getTopViewData();
    getVanalyticsData();
    getChartData();
    notification();
    if (prefs.getString("getreminder") == null) {
      getReminder();
    }
  }

  void getReminder() {
    http.post(urlGetReminder, body: {
      "companyID": companyID,
      "userID": userID,
      "level": level,
      "user_type": userType,
    }).then((res) async {
      if (res.body != 'nodata') {
        var jsonData = json.decode(res.body);
        Database db = await ReminderDB.instance.database;
        for (var data in jsonData) {
          await db.rawInsert(
              'INSERT INTO reminder (dataid, datetime, name, phone, remark, status, time) VALUES(' +
                  data["data_id"].toString() +
                  ',"' +
                  data["datetime"].toString() +
                  '","' +
                  data["name"] +
                  '","' +
                  data["phone_number"].toString() +
                  '","' +
                  data["remark"].toString() +
                  '","' +
                  data["status"] +
                  '","' +
                  data["time"].toString() +
                  '")');
          if (data["status"] == 'active') {
            List list = await db.query(ReminderDB.table);
            String details = list[list.length - 1]['dataid'].toString() +
                "~!" +
                data["datetime"] +
                "~!" +
                data["name"] +
                "~!" +
                data["phone_number"].toString() +
                "~!" +
                data["remark"] +
                "~!" +
                'not active' +
                "~!" +
                data["time"].toString();
            if (int.parse(data["time"]) >
                DateTime.now().millisecondsSinceEpoch) {
              _scheduleNotification(
                  int.parse(list[list.length - 1]['dataid']),
                  details,
                  data["name"],
                  data["phone_number"].toString(),
                  data["remark"].toString(),
                  DateTime.fromMillisecondsSinceEpoch(int.parse(data["time"])));
            }
          }
        }
        prefs.setString("getreminder", "1");
      }
    }).catchError((err) {
      _toast("Get reminder error" + err.toString());
      print("Get reminder error: " + (err).toString());
    });
  }

  Future<void> _scheduleNotification(int id, String details, String name,
      String phone, String remark, DateTime dateTime) async {
    String name1 = 'Name: ' + name + ' ';
    String phoneNo = 'Phone Number: ' + phone + ' ';
    String decription = 'Description: ' + remark + ' ';
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
        name1 + '\n' + phoneNo + '\n' + decription,
        scheduledNotificationDateTime,
        platformChannelSpecifics,
        payload: 'reminder' + details);
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
      prefs.setString('noti', res.body);
    }).catchError((err) {
      print("Notification error: " + err.toString());
    });
  }

  void getTopViewData() {
    if (this.mounted) {
      setState(() {
        topView = false;
      });
    }
    http.post(urlTopViews, body: {
      "companyID": companyID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "startDate": _startDate.toString().substring(0, 10),
      "endDate": _endDate.toString().substring(0, 10)
    }).then((res) {
      // print("VAnalytics top view body: " + res.body);
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            connection = true;
            topView = true;
            nodata = true;
          });
        }
      } else {
        var jsonData = json.decode(res.body);
        topViews.clear();
        for (var data in jsonData) {
          TopView topView = TopView(
            name: data["name"],
            status: data["status"],
            channel: data["channel"],
            views: data["views"],
            phoneNo: data["phone_number"],
          );
          topViews.add(topView);
        }
        if (this.mounted) {
          setState(() {
            topView = true;
            connection = true;
            load += 1;
          });
        }
      }
      if (timeBar == true &&
          topView == true &&
          vanalytic == true &&
          chartData == true) {
        animatedController.forward();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VAnalytics Loading Time: " + result.toString());
      }
      setTopViewData();
    }).catchError((err) {
      _toast(err.toString());
      print("Get Top View Data error: " + (err).toString());
    });
  }

  String calculatePercentage(String number) {
    String percentage;
    if (double.parse(number) >= 0) {
      percentage = "+" + number + "%";
    } else {
      percentage = number + "%";
    }
    return percentage;
  }

  Future<void> setAnalyticsData() async {
    Database db = await VAnalyticsDB.instance.database;
    await db.rawInsert('DELETE FROM analytics WHERE id > 0');
    await db.rawInsert(
        'INSERT INTO analytics (start_date, end_date, total_leads, total_leads_percentage, unassigned_leads, new_leads, contacting_leads, contacted_leads, qualified_leads, converted_leads, followup_leads, unqualified_leads, bad_info_leads, no_response_leads, vflex, vcard, vcatelogue, vbot, vhome, messenger, whatsapp_forward, import, contact_form, minimum_date) VALUES("' +
            startDate +
            '","' +
            endDate +
            '","' +
            totalLeads +
            '","' +
            totalLeadsPercentage +
            '","' +
            unassignedLeads +
            '","' +
            newLeads +
            '","' +
            contactingLeads +
            '","' +
            contactedLeads +
            '","' +
            qualifiedLeads +
            '","' +
            convertedLeads +
            '","' +
            followupLeads +
            '","' +
            unqualifiedLeads +
            '","' +
            badInfoLeads +
            '","' +
            noResponseLeads +
            '","' +
            vflex +
            '","' +
            vcard +
            '","' +
            vcatelogue +
            '","' +
            vbot +
            '","' +
            vhome +
            '","' +
            messenger +
            '","' +
            whatsappForward +
            '","' +
            import +
            '","' +
            contactForm +
            '","' +
            minimumDate +
            '")');
  }

  Future<void> setTopViewData() async {
    Database db = await TopViewDB.instance.database;
    await db.rawInsert('DELETE FROM topview WHERE id > 0');
    if (nodata != true) {
      for (int index = 0; index < topViews.length; index++) {
        await db.rawInsert(
            'INSERT INTO topview (name, status, channel, views) VALUES("' +
                topViews[index].name +
                '","' +
                topViews[index].status +
                '","' +
                topViews[index].channel +
                '","' +
                topViews[index].views +
                '")');
      }
    }
  }

  Future<void> setLeadsData() async {
    Database db = await LeadsDB.instance.database;
    await db.rawInsert('DELETE FROM leads WHERE id > 0');
    for (int index = 0; index < leadsDatas.length; index++) {
      await db.rawInsert('INSERT INTO leads (date, number) VALUES("' +
          leadsDatas[index].date +
          '","' +
          leadsDatas[index].number +
          '")');
    }
  }

  void getChartData() {
    if (this.mounted) {
      setState(() {
        chartData = false;
      });
    }
    http.post(urlLeads, body: {
      "companyID": companyID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "startDate": _startDate.toString().substring(0, 10),
      "endDate": _endDate.toString().substring(0, 10),
    }).then((res) {
      // print("VAnalytics total leads body: " + res.body);
      if (res.body == "nodata") {
        LeadData leadsData = LeadData(
          date: DateTime.now().toString().substring(0, 10),
          number: "0",
        );
        leadsDatas.add(leadsData);
      } else {
        var jsonData = json.decode(res.body);
        leadsDatas.clear();
        for (var data in jsonData) {
          LeadData leadsData = LeadData(
            date: data["date"],
            number: data["number"],
          );
          leadsDatas.add(leadsData);
        }
      }
      if (this.mounted) {
        setState(() {
          chartData = true;
          connection = true;
          _startdate = _startDate.toString();
        });
      }
      if (timeBar == true &&
          topView == true &&
          vanalytic == true &&
          chartData == true) {
        animatedController.forward();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VAnalytics Loading Time: " + result.toString());
      }
      setLeadsData();
    }).catchError((err) {
      _toast(err.toString());
      print("Get chart data error: " + (err).toString());
    });
  }

  void getVanalyticsData() {
    if (this.mounted) {
      setState(() {
        vanalytic = false;
      });
    }
    String system;
    if (Platform.isAndroid) {
      system = "android";
    } else {
      system = "ios";
    }
    http.post(urlVAnalytics, body: {
      "system": system,
      "companyID": companyID,
      "level": level,
      "userID": userID,
      "user_type": userType,
      "startDate": _startDate.toString().substring(0, 10),
      "endDate": _endDate.toString().substring(0, 10),
    }).then((res) {
      // print("VAnalytics body: " + res.body);
      var jsonData = json.decode(res.body);
      if (jsonData[0] == "nodata") {
        newVersion = jsonData[1];
        totalLeads = "0";
        totalLeadsPercentage = "0";
        unassignedLeads = "0";
        newLeads = "0";
        contactingLeads = "0";
        contactedLeads = "0";
        qualifiedLeads = "0";
        convertedLeads = "0";
        followupLeads = "0";
        unqualifiedLeads = "0";
        badInfoLeads = "0";
        noResponseLeads = "0";
        vflex = "0";
        vcard = "0";
        vcatelogue = "0";
        vbot = "0";
        vhome = "0";
        messenger = "0";
        whatsappForward = "0";
        import = "0";
        contactForm = "0";
        minimumDate = "2017-12-01";
      } else {
        for (var data in jsonData) {
          newVersion = data["version"];
          totalLeads = data["total_leads"];
          totalLeadsPercentage =
              calculatePercentage(data["total_leads_percentage"].toString());
          unassignedLeads = data["unassigned_leads"].toString();
          newLeads = data["new_leads"].toString();
          contactingLeads = data["contacting_leads"].toString();
          contactedLeads = data["contacted_leads"].toString();
          qualifiedLeads = data["qualified_leads"].toString();
          convertedLeads = data["converted_leads"].toString();
          followupLeads = data["followup_leads"].toString();
          unqualifiedLeads = data["unqualified_leads"].toString();
          badInfoLeads = data["bad_info_leads"].toString();
          noResponseLeads = data["no_response_leads"].toString();
          vflex = data["vflex"].toString();
          vcard = data["vcard"].toString();
          vcatelogue = data["vcatelogue"].toString();
          vbot = data["vbot"].toString();
          vhome = data["vhome"].toString();
          messenger = data["messenger"].toString();
          whatsappForward = data["whatsapp_forward"].toString();
          import = data["import"].toString();
          contactForm = data["contact_form"].toString();

          if (double.parse(data["total_leads_percentage"]) >= 0) {
            positive = true;
          } else {
            positive = false;
          }
        }
      }
      try {
        versionCheck(context);
      } catch (e) {
        print("VersionCheck error: " + e.toString());
      }
      if (this.mounted) {
        setState(() {
          vanalytic = true;
          connection = true;
        });
      }

      if (timeBar == true &&
          topView == true &&
          vanalytic == true &&
          chartData == true) {
        animatedController.forward();
        // endTime = DateTime.now().millisecondsSinceEpoch;
        // int result = endTime - startTime;
        // print("VAnalytics Loading Time: " + result.toString());
      }
      setAnalyticsData();
    }).catchError((err) {
      _toast(err.toString());
      print("Get Vanalytics Data error: " + (err).toString());
    });
  }

  void setupDateTimeBar() {
    if (this.mounted) {
      setState(() {
        timeBar = false;
      });
    }

    String startYear = _startDate.toString().substring(0, 4);
    String endYear = _endDate.toString().substring(0, 4);
    String startMonth = checkMonth(_startDate.toString().substring(5, 7));
    String endMonth = checkMonth(_endDate.toString().substring(5, 7));
    String startDay = _startDate.toString().substring(8, 10);
    String endDay = _endDate.toString().substring(8, 10);
    dateBanner = startMonth +
        " " +
        startDay +
        ", " +
        startYear +
        " - " +
        endMonth +
        " " +
        endDay +
        ", " +
        endYear;
    if (this.mounted) {
      setState(() {
        connection = true;
        timeBar = true;
      });
    }

    if (timeBar == true &&
        topView == true &&
        vanalytic == true &&
        chartData == true) {
      animatedController.forward();
      // endTime = DateTime.now().millisecondsSinceEpoch;
      // int result = endTime - startTime;
      // print("VAnalytics Loading Time: " + result.toString());
    }
  }

  void _done() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (_startDate.toString() == _startdate &&
          _endDate.toString() == _enddate) {
        Navigator.of(context).pop();
      } else {
        if (this.mounted) {
          setState(() {
            startDate = _startDate.toString().substring(0, 10);
            endDate = _endDate.toString().substring(0, 10);
          });
        }

        Navigator.of(context).pop();
        getTopViewData();
        getVanalyticsData();
        getChartData();
        String startYear = _startDate.toString().substring(0, 4);
        String endYear = _endDate.toString().substring(0, 4);
        String startMonth = checkMonth(_startDate.toString().substring(5, 7));
        String endMonth = checkMonth(_endDate.toString().substring(5, 7));
        String startDay = _startDate.toString().substring(8, 10);
        String endDay = _endDate.toString().substring(8, 10);
        if (this.mounted) {
          setState(() {
            dateBanner = startMonth +
                " " +
                startDay +
                ", " +
                startYear +
                " - " +
                endMonth +
                " " +
                endDay +
                ", " +
                endYear;
          });
        }
      }
    } else {
      Navigator.pop(context);
      _toast("Please check your Internet connection");
    }
  }

  Future<Null> _handleRefresh() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (this.mounted) {
        setState(() {
          refresh = true;
          load = 0;
          timeBar = false;
          topView = false;
          vanalytic = false;
          chartData = false;
        });
      }
      _startDate = DateTime(DateTime.now().year, DateTime.now().month - 1,
          DateTime.now().day + 1);
      _startdate = _startDate.toString();
      _endDate = DateTime.now();
      _enddate = _endDate.toString();
      startDate = _startDate.toString().substring(0, 10);
      endDate = _endDate.toString().substring(0, 10);
      setupDateTimeBar();
      getTopViewData();
      getVanalyticsData();
      getChartData();
    } else {
      _toast("No Internet connection, data can't load");
    }
  }

  versionCheck(context) async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    currentVersion = info.version.trim();
    if (newVersion != currentVersion) {
      _showVersionDialog(context);
    }
  }

  _showVersionDialog(context) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title = "New Update Available";
        String message =
            "There is a newer version of app available please update it now.";
        return Platform.isIOS
            ? new CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Update Now"),
                    onPressed: () => _launchURL(
                        'https://apps.apple.com/us/app/vvin/id1502502224'),
                  ),
                  FlatButton(
                    child: Text("Later"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              )
            : NDialog(
                dialogStyle: DialogStyle(titleDivider: true),
                title: Text(title),
                content: Text(message),
                actions: <Widget>[
                  FlatButton(
                    child: Text("Update Now"),
                    onPressed: () => _launchURL(
                        'https://play.google.com/store/apps/details?id=com.my.jtapps.vvin'),
                  ),
                  FlatButton(
                    child: Text("Later"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
      },
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
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

class LeadsData {
  LeadsData(this.x, this.y);
  final String x;
  final double y;
}

class AppData {
  AppData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color color;
}

class ChannelData {
  ChannelData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color color;
}
