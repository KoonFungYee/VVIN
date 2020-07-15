import 'dart:convert';
import 'dart:io';
import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvin/reminder.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:menu_button/menu_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/data.dart';
import 'package:vvin/editReminder.dart';
import 'package:vvin/editVProfile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vvin/notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vformResponse.dart';

bool isScan;
String full = "";
File pickedImage;
_VProfileState pageState;

class Item1 {
  PermissionGroup group;
  PermissionStatus status;

  Item1(this.group, this.status);
}

class VProfile extends StatefulWidget {
  final VDataDetails vdata;
  final String notification;
  const VProfile({Key key, this.vdata, this.notification}) : super(key: key);

  @override
  _VProfileState createState() {
    pageState = _VProfileState();
    return pageState;
  }
}

enum UniLinksType { string, uri }

class _VProfileState extends State<VProfile>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // final SpeechToText speech = SpeechToText();
  List<Item1> list = List<Item1>();
  Contact contact = Contact();
  PostalAddress address = PostalAddress(label: "Home");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  final TextEditingController _addRemark = TextEditingController();
  final GlobalKey _one = GlobalKey();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  BuildContext myContext;
  SharedPreferences prefs;
  double _scaleFactor = 1.0;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  TabController controller;
  String urlVProfile = ip + "vprofile.php";
  String urlHandler = ip + "handler.php";
  String urlVTag = ip + "vtag.php";
  String urlViews = ip + "views.php";
  String urlRemarks = ip + "remarks.php";
  String urlChangeStatus = ip + "vdataChangeStatus.php";
  String urlSaveRemark = ip + "saveRemark.php";
  String urlWhatsApp = ip + "whatsappForward.php";
  String assignURL = ip + "assign.php";
  String urlAllHandlers = ip + "getHandler.php";
  String responseURL = ip + 'response.php';
  List handler, vTag;
  List<VProfileData> vProfileDetails = [];
  List<View> vProfileViews = [];
  List<Remarks> vProfileRemarks = [];
  List<Handler> allHandler = [];
  List<String> otherList = [];
  List vformResponse = [];
  String name,
      phoneNo,
      status,
      companyID,
      branchID,
      userID,
      level,
      userType,
      resultText,
      now,
      base64Image,
      speechText;
  bool vProfileData,
      handlerData,
      viewsData,
      remarksData,
      vTagData,
      hasSpeech,
      start,
      isFirst,
      click,
      hListStatus,
      assignDone,
      noHandler,
      response,
      noResponse,
      assignDoneClick,
      isSend;
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

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (widget.notification == null) {
      controller = TabController(vsync: this, length: 3, initialIndex: 0);
    } else {
      controller = TabController(vsync: this, length: 3, initialIndex: 2);
    }
    list.clear();
    list.add(Item1(PermissionGroup.values[2], PermissionStatus.denied));
    check();
    _init();
    name = widget.vdata.name;
    phoneNo = widget.vdata.phoneNo;
    status = widget.vdata.status;
    companyID = widget.vdata.companyID;
    branchID = widget.vdata.branchID;
    userID = widget.vdata.userID;
    level = widget.vdata.level;
    userType = widget.vdata.userType;
    assignDoneClick = noResponse = response = noHandler = assignDone =
        handlerData = hListStatus = click = isFirst = isSend = start =
            hasSpeech = vTagData =
                remarksData = viewsData = isScan = vProfileData = false;
    base64Image = _addRemark.text = resultText = speechText = "";
    // WidgetsBinding.instance.addObserver(this);
    // PermissionHandler().checkPermissionStatus(PermissionGroup.microphone);
    // askPermission();
    // initSpeechState();
    checkConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
          Duration(milliseconds: 200),
          () => ShowCaseWidget.of(myContext).startShowCase([
                _one,
              ]));
    });
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
  }

  void check() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('vprofile') == null) {
      if (this.mounted) {
        setState(() {
          isFirst = true;
        });
      }
      prefs.setString('vprofile', '1');
    }
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
    super.dispose();
  }

  // Future<void> initSpeechState() async {
  //   bool hasSpeechs = await speech.initialize();
  //   if (!mounted) return;
  //   setState(() {
  //     hasSpeech = hasSpeechs;
  //   });
  // }

  // void startListening() {
  //   speech.listen(onResult: resultListener);
  // }

  // void resultListener(SpeechRecognitionResult result) {
  //   if (result.finalResult == true) {
  //     if (_addRemark.text == "") {
  //       setState(() {
  //         start = false;
  //         _addRemark.text = result.recognizedWords;
  //       });
  //     } else {
  //       setState(() {
  //         _addRemark.text = _addRemark.text + " " + result.recognizedWords;
  //       });
  //     }
  //   }
  // }

  // void askPermission() {
  //   PermissionHandler().requestPermissions([PermissionGroup.microphone]).then(
  //       _onStatusRequested);
  // }

  // void _onStatusRequested(Map<PermissionGroup, PermissionStatus> statuses) {
  //   final status = statuses[PermissionGroup.microphone];
  //   if (status != PermissionStatus.granted) {
  //     PermissionHandler().openAppSettings();
  //   } else {
  //     // _updateStatus(status);
  //   }
  // }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   print(state);
  //   if (state == AppLifecycleState.resumed) {
  //     PermissionHandler().checkPermissionStatus(PermissionGroup.microphone);
  //     // .then(_updateStatus);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    final Widget button = SizedBox(
      width: ScreenUtil().setWidth(320),
      height: ScreenUtil().setHeight(60),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                status,
                style: TextStyle(fontSize: font14),
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
    return ShowCaseWidget(
      builder: Builder(
        builder: (context) {
          myContext = context;
          return WillPopScope(
            onWillPop: _onBackPressAppBar,
            child: Scaffold(
              backgroundColor: Color.fromRGBO(235, 235, 255, 1),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(ScreenUtil().setHeight(85)),
                child: AppBar(
                  brightness: Brightness.light,
                  leading: IconButton(
                    onPressed: _onBackPressAppBar,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      size: ScreenUtil().setWidth(30),
                      color: Colors.grey,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  elevation: 1,
                  centerTitle: true,
                  title: Text(
                    "VProfile",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: font18,
                        fontWeight: FontWeight.bold),
                  ),
                  actions: (vProfileData == true)
                      ? <Widget>[popupMenuButton()]
                      : null,
                ),
              ),
              body: Column(
                children: <Widget>[
                  (assignDone == false)
                      ? Container()
                      : Container(
                          height: ScreenUtil().setHeight(60),
                          margin: EdgeInsets.all(ScreenUtil().setHeight(10)),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color.fromRGBO(158, 232, 168, 1)),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(3.0)),
                              color: Color.fromRGBO(230, 249, 241, 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                height: ScreenUtil().setHeight(50),
                                width: ScreenUtil().setHeight(50),
                                margin:
                                    EdgeInsets.all(ScreenUtil().setHeight(10)),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(8, 195, 20, 1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.check,
                                    color: Colors.white,
                                    size: ScreenUtil().setHeight(30)),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'VProfiled has been assigned to a handler',
                                      style: TextStyle(
                                          color: Color.fromRGBO(8, 195, 20, 1),
                                          fontSize: font12),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (this.mounted) {
                                    setState(() {
                                      assignDone = false;
                                    });
                                  }
                                },
                                child: Icon(
                                  Icons.close,
                                  color: Color.fromRGBO(8, 195, 20, 1),
                                  size: font18,
                                ),
                              ),
                              SizedBox(
                                width: ScreenUtil().setWidth(10),
                              ),
                            ],
                          ),
                        ),
                  Container(
                    margin: EdgeInsets.fromLTRB(
                        0, ScreenUtil().setHeight(15), 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: font18,
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: ScreenUtil().setHeight(10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      InkWell(
                        onTap: () async {
                          var connectivityResult =
                              await (Connectivity().checkConnectivity());
                          if (connectivityResult == ConnectivityResult.wifi ||
                              connectivityResult == ConnectivityResult.mobile) {
                            launch('tel:' + widget.vdata.phoneNo);
                          } else {
                            _toast("No Internet Connection");
                          }
                        },
                        child: Container(
                          width: ScreenUtil().setWidth(90),
                          height: ScreenUtil().setHeight(90),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.call,
                            size: ScreenUtil().setHeight(50),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          var connectivityResult =
                              await (Connectivity().checkConnectivity());
                          if (connectivityResult == ConnectivityResult.wifi ||
                              connectivityResult == ConnectivityResult.mobile) {
                            FlutterOpenWhatsapp.sendSingleMessage(
                                widget.vdata.phoneNo, "");
                          } else {
                            _toast("No Internet Connection");
                          }
                        },
                        child: Container(
                          width: ScreenUtil().setWidth(90),
                          height: ScreenUtil().setHeight(90),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(37, 211, 102, 1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FontAwesomeIcons.whatsapp,
                            size: ScreenUtil().setHeight(50),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          var connectivityResult =
                              await (Connectivity().checkConnectivity());
                          if (connectivityResult == ConnectivityResult.wifi ||
                              connectivityResult == ConnectivityResult.mobile) {
                            launch('mailto:' + widget.vdata.email);
                          } else {
                            _toast("No Internet Connection");
                          }
                        },
                        child: Container(
                          width: ScreenUtil().setWidth(90),
                          height: ScreenUtil().setHeight(90),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mail,
                            size: ScreenUtil().setHeight(50),
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: <Widget>[
                  //     BouncingWidget(
                  //       scaleFactor: _scaleFactor,
                  //       onPressed: () async {
                  //         var connectivityResult =
                  //             await (Connectivity().checkConnectivity());
                  //         if (connectivityResult == ConnectivityResult.wifi ||
                  //             connectivityResult == ConnectivityResult.mobile) {
                  //           FlutterOpenWhatsapp.sendSingleMessage(phoneNo, "");
                  //         } else {
                  //           _toast("This feature need Internet connection");
                  //         }
                  //       },
                  //       child: ButttonWithIcon(
                  //         icon: FontAwesomeIcons.whatsapp,
                  //         title: "WhatsApp",
                  //         buttonColor: Color.fromRGBO(37, 211, 102, 1),
                  //         onPressed: () async {
                  //           var connectivityResult =
                  //               await (Connectivity().checkConnectivity());
                  //           if (connectivityResult == ConnectivityResult.wifi ||
                  //               connectivityResult ==
                  //                   ConnectivityResult.mobile) {
                  //             FlutterOpenWhatsapp.sendSingleMessage(
                  //                 phoneNo, "");
                  //           } else {
                  //             _toast("This feature need Internet connection");
                  //           }
                  //         },
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(
                    height: ScreenUtil().setHeight(10),
                  ),
                  (status == '')
                      ? Container()
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            MenuButton(
                              child: button,
                              items: data,
                              scrollPhysics: AlwaysScrollableScrollPhysics(),
                              topDivider: true,
                              itemBuilder: (value) => Container(
                                height: ScreenUtil().setHeight(60),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 0.0, horizontal: 10),
                                child: Text(value,
                                    style: TextStyle(fontSize: font14)),
                              ),
                              toggledChild: Container(
                                color: Colors.white,
                                child: button,
                              ),
                              divider: Container(
                                height: 1,
                                color: Colors.grey[300],
                              ),
                              onItemSelected: (value) {
                                setState(() {
                                  status = value;
                                  setStatus(value);
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
                  SizedBox(
                    height: ScreenUtil().setHeight(20),
                  ),
                  (handlerData == true && noHandler == true && level == '4')
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'This VData has no handler. ',
                              style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: font12),
                            ),
                            InkWell(
                              onTap: _assign,
                              child: Text(
                                'Assign now',
                                style: TextStyle(
                                    color: Colors.blue, fontSize: font12),
                              ),
                            ),
                          ],
                        )
                      : Container(),
                  SizedBox(
                    height: ScreenUtil().setHeight(20),
                  ),
                  Expanded(
                    child: Scaffold(
                      backgroundColor: Color.fromRGBO(235, 235, 255, 1),
                      appBar: PreferredSize(
                        preferredSize: Size.fromHeight(
                          ScreenUtil().setHeight(70),
                        ),
                        child: TabBar(
                          controller: controller,
                          indicator: BoxDecoration(color: Colors.white),
                          unselectedLabelColor: Colors.grey,
                          labelColor: Colors.blue,
                          labelStyle: TextStyle(
                            fontSize: font18,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: font18,
                          ),
                          tabs: <Widget>[
                            Tab(
                              child: Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: font18,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Views',
                                style: TextStyle(
                                  fontSize: font18,
                                ),
                              ),
                            ),
                            Tab(
                              child: Text(
                                'Remarks',
                                style: TextStyle(
                                  fontSize: font18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      body: TabBarView(
                        controller: controller,
                        children: <Widget>[
                          (vProfileData == true &&
                                  handlerData == true &&
                                  vTagData == true)
                              ? Details(
                                  vProfileDetails: vProfileDetails,
                                  handler: handler,
                                  vdata: widget.vdata,
                                  vtag: vTag,
                                )
                              : Container(
                                  color: Colors.white,
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                          (viewsData == true)
                              ? Views(
                                  vProfileViews: vProfileViews,
                                )
                              : Container(
                                  color: Colors.white,
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                          (remarksData == true)
                              ? Remark(
                                  vProfileRemarks: vProfileRemarks,
                                  vdata: widget.vdata,
                                )
                              : Container(
                                  color: Colors.white,
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget popupMenuButton() {
    return PopupMenuButton<String>(
      icon: (isFirst == true)
          ? Showcase(
              key: _one,
              description: 'Click to view new features',
              child: Icon(
                Icons.more_vert,
                size: ScreenUtil().setWidth(40),
                color: Colors.grey,
              ),
            )
          : Icon(
              Icons.more_vert,
              size: ScreenUtil().setWidth(40),
              color: Colors.grey,
            ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: "edit",
          child: Text(
            "Edit",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: "add remark",
          child: Text(
            "Add Remark",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: "add reminder",
          child: Text(
            "Add Reminder",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: "save contact",
          child: Text(
            "Save Contact",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: "scan card",
          child: Text(
            "Scan Name Card",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: "open map",
          child: Text(
            "Open Map",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        (vProfileDetails[0].app == 'VForm')
            ? PopupMenuItem<String>(
                value: "response",
                child: Text(
                  "View Response",
                  style: TextStyle(
                    fontSize: font14,
                  ),
                ),
              )
            : null,
      ],
      onSelected: (selectedItem) {
        switch (selectedItem) {
          case "add remark":
            {
              showGeneralDialog(
                  barrierDismissible: false,
                  barrierColor: Colors.grey.withOpacity(0.5),
                  transitionBuilder: (context, a1, a2, widget) {
                    final curvedValue =
                        Curves.easeInOutBack.transform(a1.value) - 1.0;
                    return Transform(
                      transform: Matrix4.translationValues(
                          0.0, curvedValue * 200, 0.0),
                      child: Opacity(
                        opacity: a1.value,
                        child: AlertDialog(
                          shape: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          elevation: 1.0,
                          title: Text(
                            "Add new remark",
                            style: TextStyle(
                              fontSize: font16,
                            ),
                          ),
                          content: Container(
                            decoration: BoxDecoration(
                                color: Color.fromRGBO(235, 235, 255, 1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            height: MediaQuery.of(context).size.height * 0.2,
                            child: TextField(
                              style: TextStyle(
                                fontSize: font14,
                              ),
                              maxLines: 5,
                              controller: _addRemark,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          actions: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                // FloatingActionButton(
                                //   child: Icon(
                                //     Icons.mic,
                                //     // color: (start == false) ? Colors.pink : Colors.grey,
                                //   ),
                                //   mini: true,
                                //   onPressed: () {
                                //     initSpeechState();
                                //     startListening();
                                //     // setState(() {
                                //     //   start = true;
                                //     // });
                                //   },
                                //   backgroundColor:
                                //   // Colors.pink,
                                //   (start == false)
                                //   ? Colors.pink
                                //   : Colors.grey,
                                // ),
                                // SizedBox(
                                //   width: MediaQuery.of(context).size.width * 0.2,
                                // ),
                                FlatButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: font14,
                                    ),
                                  ),
                                ),
                                FlatButton(
                                  onPressed: _onSubmit,
                                  child: Text(
                                    "Submit",
                                    style: TextStyle(
                                      fontSize: font14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  transitionDuration: Duration(milliseconds: 300),
                  context: context,
                  pageBuilder: (context, animation1, animation2) {});
            }
            break;
          case "add reminder":
            {
              if (vProfileData == true) {
                Navigator.push(
                  context,
                  AwesomePageRoute(
                    transitionDuration: Duration(milliseconds: 600),
                    exitPage: widget,
                    enterPage: EditReminder(
                      datetime: "",
                      name: vProfileDetails[0].name,
                      phoneNo: phoneNo,
                      remark: "",
                    ),
                    transition: DefaultTransition(),
                  ),
                );
              } else {
                _toast('Data is laoding, please try again later');
              }
            }
            break;
          case "save contact":
            {
              requestPermission();
            }
            break;
          case "open map":
            {
              openMapsSheet();
            }
            break;
          case "scan card":
            {
              _scanner();
            }
            break;
          case "edit":
            {
              _editVProfile();
            }
            break;
          case "response":
            {
              viewResponse();
            }
            break;
        }
      },
    );
  }

  void viewResponse() {
    if (response == true) {
      if (noResponse == false) {
        Navigator.of(context).push(
          PageRouteTransition(
            animationType: AnimationType.scale,
            builder: (context) => VFormResponse(
              id: '',
              vformID: vProfileDetails[0].vformID,
              reponseID: '',
              companyID: companyID,
              branchID: branchID,
              userID: userID,
              level: level,
              userType: userType,
              title: '',
              data: vformResponse[0]['data'],
            ),
          ),
        );
      } else {
        _toast('This response has been deleted');
      }
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        viewResponse();
      });
    }
  }

  void _scanner() async {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            title: Text(
              "Action",
              style: TextStyle(
                fontSize: font14,
              ),
            ),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontSize: font18,
                ),
              ),
            ),
            actions: <Widget>[
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  var tempStore =
                      await ImagePicker.pickImage(source: ImageSource.gallery);
                  if (tempStore != null) {
                    _onLoading1();
                    if (this.mounted) {
                      setState(() {
                        pickedImage = tempStore;
                        isScan = true;
                      });
                    }
                    readText();
                  }
                },
                child: Text(
                  "Browse Gallery",
                  style: TextStyle(
                    fontSize: font18,
                  ),
                ),
              ),
              CupertinoActionSheetAction(
                onPressed: () async {
                  Navigator.of(context).pop();
                  var tempStore =
                      await ImagePicker.pickImage(source: ImageSource.camera);
                  if (tempStore != null) {
                    _onLoading1();
                    if (this.mounted) {
                      setState(() {
                        pickedImage = tempStore;
                        isScan = true;
                      });
                    }
                    readText();
                  }
                },
                child: Text(
                  "Take Photo",
                  style: TextStyle(
                    fontSize: font18,
                  ),
                ),
              ),
            ],
          );
        });
  }

  Future readText() async {
    full = "";
    pickedImage = await FlutterNativeImage.compressImage(pickedImage.path,
        quality: 40, percentage: 30);
    base64Image = base64Encode(pickedImage.readAsBytesSync());
    String number = DateTime.now().millisecondsSinceEpoch.toString();
    http
        .post(urlWhatsApp, body: {
          "companyID": companyID,
          "branchID": branchID,
          "userID": userID,
          "user_type": userType,
          "level": level,
          "phoneNo": phoneNo,
          "name": name,
          "companyName": "",
          "remark": "",
          "vtag": "",
          "number": userID.toString() + '_' + number.toString(),
          "url": '',
          "nameCard": base64Image,
          "system": 'android',
          "details": '',
        })
        .then((res) {})
        .catchError((err) {
          _toast('Something error on save image');
          print(err.toString());
        });
    FirebaseVisionImage image = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(image);

    String patttern = r'[0-9]';
    RegExp regExp = new RegExp(patttern);
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        String temPhone = "";
        String number = '';
        int startIndex = 0;
        int endIndex = 0;
        bool save = true;
        for (int i = 0; i < line.text.length; i++) {
          if (regExp.hasMatch(line.text[i])) {
            endIndex = i + 1;
            if (number != 'string') {
              number = 'num';
              temPhone = temPhone + line.text[i];
            } else if (temPhone.length == 0) {
              number = 'num';
              temPhone = temPhone + line.text[i];
            } else {
              temPhone = '';
              endIndex = 0;
            }
          } else {
            if (number == 'num') {
              number = 'notNum';
            } else if (number == 'notNum') {
              number = 'string';
            }
          }
          if (temPhone.length > 9 && number == 'string') {
            String text =
                line.text.substring(startIndex, endIndex - temPhone.length - 2);
            otherList.add(text);
            temPhone = '';
            number = '';
            startIndex = endIndex;
            endIndex = 0;
          } else if (temPhone.length > 9 && i == line.text.length - 1) {
            save = false;
          }
          if (i == line.text.length - 1) {
            if (startIndex != line.text.length - 1 && save == true) {
              otherList.add(line.text.substring(startIndex));
            }
          }
        }
      }
    }
    if (otherList.length != 0) {
      for (int i = 0; i < otherList.length; i++) {
        if (i != otherList.length - 1) {
          full = full + otherList[i] + "~!";
        } else {
          full = full + otherList[i];
        }
      }
    }
    http.post(urlWhatsApp, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "user_type": userType,
      "level": level,
      "phoneNo": phoneNo,
      "name": name,
      "companyName": "",
      "remark": "",
      "vtag": "",
      "number": userID.toString() + '_' + number.toString(),
      "url": '',
      "nameCard": '',
      "system": 'android',
      "details": full.toString(),
    }).then((res) {
      Navigator.of(context).pop();
      _toast('Done');
    }).catchError((err) {
      Navigator.of(context).pop();
      _toast(err.toString());
      print("Scan name card error: " + err.toString());
    });
  }

  void _onLoading1() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () {},
        child: Dialog(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.12,
            width: MediaQuery.of(context).size.width * 0.1,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
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
            ),
          ),
        ),
      ),
    );
  }

  void _assign() async {
    if (handlerData == false || hListStatus == false) {
      if (click == false) {
        if (this.mounted) {
          setState(() {
            click = true;
          });
        }
        _assignCheck();
      }
    } else {
      _assignCheck();
    }
  }

  void _assignCheck() {
    if (handlerData == false || hListStatus == false) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _assignCheck();
      });
    } else {
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
                                    _assignDone();
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
                                child: Text("Assign handler for this lead",
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
                                    child: (handler.length == 0)
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
                                                setModalState, handler),
                                          ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    _selectHandler();
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
    }
  }

  void _selectHandler() {
    String handlerSelected = "";
    Navigator.of(context).pop();
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
                            bool add = true;
                            if (handlerSelected == "-" ||
                                handlerSelected == "") {
                            } else {
                              if (handler.length != 0) {
                                for (var each in handler) {
                                  if (handlerSelected == each.toString()) {
                                    add = false;
                                    break;
                                  }
                                }
                                if (add == true) {
                                  if (this.mounted) {
                                    setState(() {
                                      handler.add(handlerSelected);
                                    });
                                  }
                                }
                              } else {
                                if (this.mounted) {
                                  setState(() {
                                    handler.add(handlerSelected);
                                  });
                                }
                              }
                            }
                            Navigator.pop(context);
                            _assign();
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
                        handlerSelected = allHandler[index].handler;
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

  List<Widget> _allHandlers(List<Handler> allHandler) {
    List widgetList = <Widget>[];
    for (int i = 0; i < allHandler.length; i++) {
      Widget widget1 = Text(
        allHandler[i].handler,
        style: TextStyle(
          fontSize: font14,
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  void _assignDone() async {
    if (assignDoneClick == false) {
      if (this.mounted) {
        setState(() {
          assignDoneClick = true;
        });
      }
      String handlerIDs = '';
      for (int j = 0; j < handler.length; j++) {
        for (int i = 0; i < allHandler.length; i++) {
          if (handler[j] == allHandler[i].handler) {
            if (handlerIDs == "") {
              handlerIDs = allHandler[i].handlerID;
            } else {
              handlerIDs = handlerIDs + "," + allHandler[i].handlerID;
            }
          }
        }
      }
      Navigator.of(context).pop();
      _onLoading1();
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.mobile) {
        http.post(assignURL, body: {
          "companyID": companyID,
          "branchID": branchID,
          "userID": userID,
          "level": level,
          "user_type": userType,
          "id": phoneNo,
          "selected_branch": '',
          "handler": handlerIDs,
          "type": 'phone',
        }).then((res) async {
          if (res.body == "success") {
            if (this.mounted) {
              setState(() {
                assignDone = true;
                noHandler = false;
              });
            }
            Future.delayed(const Duration(seconds: 3), () {
              if (this.mounted) {
                setState(() {
                  assignDone = false;
                });
              }
            });
            Navigator.of(context).pop();
            _toast("Handler updated");
          } else {
            Navigator.of(context).pop();
            _toast("At least one handler needed");
          }
          if (this.mounted) {
            setState(() {
              assignDoneClick = false;
            });
          }
        }).catchError((err) {
          Navigator.of(context).pop();
          print("Assign error: " + err.toString());
          if (this.mounted) {
            setState(() {
              assignDoneClick = false;
            });
          }
        });
      } else {
        Navigator.of(context).pop();
        _toast("No Internet, data can't update");
      }
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

  void openMapsSheet() async {
    if (vProfileData == true) {
      if (vProfileDetails[0].company != '') {
        try {
          final availableMaps = await MapLauncher.installedMaps;
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return SafeArea(
                child: SingleChildScrollView(
                  child: Container(
                    child: Wrap(
                      children: _availableMaps(availableMaps),
                    ),
                  ),
                ),
              );
            },
          );
        } catch (e) {
          _toast("Something's wrong");
        }
      } else {
        _toast("No company name");
      }
    } else {
      _toast('Data still loading, please try again later');
    }
  }

  List<Widget> _availableMaps(List<AvailableMap> availableMaps) {
    List widgetList = <Widget>[];
    for (var map in availableMaps) {
      Widget widget1 = ListTile(
        onTap: () {
          map.showMarker(
            coords:
                Coords(double.parse('3.091752'), double.parse("101.689575")),
            title: vProfileDetails[0].company,
            description: "Location",
          );
          Navigator.of(context).pop();
        },
        title: Text(map.mapName),
        leading: Image(
          image: map.icon,
          height: 30.0,
          width: 30.0,
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  Future requestPermission() async {
    var status =
        await PermissionHandler().requestPermissions([pageState.list[0].group]);
    if (status.toString() ==
        "{PermissionGroup.contacts: PermissionStatus.granted}") {
      _saveContact();
    }
  }

  void _saveContact() {
    if (vProfileData == true) {
      contact.givenName = vProfileDetails[0].name;
      contact.phones = [
        Item(
            label: "mobile",
            value: "+" +
                widget.vdata.phoneNo.substring(0, 2) +
                ' ' +
                widget.vdata.phoneNo.substring(2))
      ];
      if (vProfileDetails[0].company != '') {
        contact.company = vProfileDetails[0].company;
      }
      if (vProfileDetails[0].email != '') {
        contact.emails = [Item(label: "work", value: vProfileDetails[0].email)];
      }
      if (vProfileDetails[0].area != '') {
        address.city = vProfileDetails[0].area;
      }
      if (vProfileDetails[0].state != '') {
        address.region = vProfileDetails[0].state;
      }
      if (vProfileDetails[0].country != '') {
        address.country = vProfileDetails[0].country;
      }
      if (vProfileDetails[0].industry != '') {
        contact.jobTitle = vProfileDetails[0].industry;
      }
      if (vProfileDetails[0].dob != '') {
        int year, month, date;
        year = int.parse(vProfileDetails[0].dob.substring(0, 4));
        month = int.parse(vProfileDetails[0].dob.substring(5, 7));
        date = int.parse(vProfileDetails[0].dob.substring(8, 10));
        contact.birthday = DateTime(year, month, date);
      }
      contact.postalAddresses = [address];
      ContactsService.addContact(contact);
      _toast('Saved to contact');
    } else {
      _toast('Data still loading, please try again later');
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

  void _editVProfile() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      VProfileData vprofile = VProfileData(
        name: vProfileDetails[0].name,
        email: vProfileDetails[0].email,
        company: vProfileDetails[0].company,
        ic: vProfileDetails[0].ic,
        dob: vProfileDetails[0].dob,
        gender: (vProfileDetails[0].gender == "")
            ? ""
            : _gender(vProfileDetails[0].gender),
        position: vProfileDetails[0].position,
        industry: vProfileDetails[0].industry,
        occupation: vProfileDetails[0].occupation,
        country: vProfileDetails[0].country,
        state: vProfileDetails[0].state,
        area: vProfileDetails[0].area,
        created: vProfileDetails[0].created,
        lastActive: vProfileDetails[0].lastActive,
      );
      Navigator.of(context).push(PageTransition(
        type: PageTransitionType.rippleRightDown,
        child: (isScan == false)
            ? EditVProfile(
                vprofileData: vprofile,
                handler: handler,
                vdata: widget.vdata,
                vtag: vTag,
              )
            : EditVProfile(
                vprofileData: vprofile,
                handler: handler,
                vdata: widget.vdata,
                vtag: vTag,
                details: full,
              ),
      ));
    } else {
      _toast("Please check your Internet connection");
    }
  }

  String _gender(String genderType) {
    String gender;
    switch (genderType.toLowerCase()) {
      case "m":
        gender = "Male";
        break;
      case "f":
        gender = "Female";
        break;
      case "o":
        gender = "Other";
        break;
    }
    return gender;
  }

  void _onSubmit() async {
    if (isSend == false) {
      if (_addRemark.text == "") {
        _toast("Please key in something");
      } else {
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          if (this.mounted) {
            setState(() {
              isSend = true;
            });
          }
          http.post(urlSaveRemark, body: {
            "companyID": companyID,
            "branchID": branchID,
            "userID": userID,
            "level": level,
            "user_type": userType,
            "phone_number": phoneNo,
            "remark": _addRemark.text,
          }).then((res) async {
            if (res.body == "success") {
              VDataDetails vdata = new VDataDetails(
                companyID: widget.vdata.companyID,
                branchID: widget.vdata.branchID,
                userID: widget.vdata.userID,
                level: widget.vdata.level,
                userType: widget.vdata.userType,
                name: widget.vdata.name,
                phoneNo: widget.vdata.phoneNo,
                status: widget.vdata.status,
                email: widget.vdata.email,
              );
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VProfile(vdata: vdata)));
              _addRemark.text = "";
            } else {
              Navigator.pop(context);
              _addRemark.text = "";
              _toast("Please contact VVIN help desk");
            }
          }).catchError((err) {
            Navigator.pop(context);
            _addRemark.text = "";
            _toast("No Internet Connection, data can't save");
            print("On submit error: " + err.toString());
          });
        } else {
          _toast("Please check your Internet connection");
        }
      }
    }
  }

  void checkConnection() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String pathName = dir.path.toString() + "/attachment.png";
    if (File(pathName).existsSync() == true) {
      try {
        final dir = Directory(pathName);
        dir.deleteSync(recursive: true);
      } catch (err) {}
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      getAllHandler();
      getHandler(); //Data handler
      getVProfileData();
      getViews();
      getRemarks();
      getVTag();
    } else {
      _toast("No Internet connection! Can't show");
    }
  }

  void getAllHandler() {
    companyID = companyID;
    branchID = branchID;
    userID = userID;
    level = level;
    userType = userType;
    http.post(urlAllHandlers, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "user_type": userType,
      "level": level,
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        // print(jsonData);
        for (var data in jsonData) {
          Handler handler = Handler(
            handler: data["handler"],
            position: data["position"],
            handlerID: data["handlerID"],
          );
          allHandler.add(handler);
        }
      }
      if (this.mounted) {
        setState(() {
          hListStatus = true;
        });
      }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Setup Data error: " + err.toString());
    });
  }

  void getVTag() {
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

  void getVProfileData() {
    http.post(urlVProfile, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "phone_number": phoneNo,
    }).then((res) {
      // print("VProfile body: " + res.body);
      if (res.body == "nodata") {
        VProfileData vprofile = VProfileData(
          name: name,
          email: "",
          company: "",
          ic: "",
          dob: "",
          gender: "",
          position: "",
          industry: "",
          occupation: "",
          country: "",
          state: "",
          area: "",
          app: "",
          channel: "",
          created: "",
          lastActive: "",
          img: "",
          vformID: "",
        );
        vProfileDetails.add(vprofile);
      } else {
        var jsonData = json.decode(res.body);
        // print("VProfile body: " + jsonData.toString());
        for (var data in jsonData) {
          VProfileData vprofile = VProfileData(
            name: name,
            email: data['email'] ?? "",
            company: data['company'] ?? "",
            ic: data['ic'] ?? "",
            dob: data['dob'] ?? "",
            gender: data['gender'] ?? "",
            position: data['position'] ?? "",
            industry: data['industry'] ?? "",
            occupation: data['occupation'] ?? "",
            country: data['country'] ?? "",
            state: data['state'] ?? "",
            area: data['area'] ?? "",
            app: data['app'] ?? "",
            channel: data['channel'] ?? "",
            created: data['created'].toString().substring(0, 10) ?? "",
            lastActive: data['lastActive'] ?? "",
            img: data['img'] ?? "",
            vformID: data['vform_id'] ?? "",
          );
          vProfileDetails.add(vprofile);
          if (vProfileDetails[0].app == 'VForm') {
            getResponse();
          }
          if (this.mounted) {
            setState(() {
              status = data['status'];
            });
          }
        }
      }
      if (this.mounted) {
        setState(() {
          vProfileData = true;
        });
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get VProfile data error: " + err.toString());
    });
  }

  void getResponse() {
    http.post(responseURL, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "vform_id": vProfileDetails[0].vformID,
      "phone_number": phoneNo,
    }).then((res) {
      // print("getResponse body: " + res.body);
      if (res.body != 'nodata') {
        var jsonData = json.decode(res.body);
        vformResponse = jsonData;
      } else {
        if (this.mounted) {
          setState(() {
            noResponse = true;
          });
        }
      }
      if (this.mounted) {
        setState(() {
          response = true;
        });
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get response error: " + err.toString());
    });
  }

  void getHandler() {
    http.post(urlHandler, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "phone_number": phoneNo,
    }).then((res) {
      // print("getHandler body: " + res.body);
      if (res.body == "nodata") {
        handler = [];
      } else {
        var jsonData = json.decode(res.body);
        handler = jsonData;
      }
      if (this.mounted) {
        setState(() {
          handlerData = true;
        });
      }
      if (handler.length == 0) {
        if (this.mounted) {
          setState(() {
            noHandler = true;
          });
        }
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get handler error: " + err.toString());
    });
  }

  void getViews() {
    http.post(urlViews, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "phone_number": phoneNo,
    }).then((res) {
      // print("VProfileViews body: " + res.body);
      if (res.body == "nodata") {
        View views = View(
          date: "",
          link: "",
        );
        vProfileViews.add(views);
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          View views = View(
            date: data['date'],
            link: data['link'],
          );
          vProfileViews.add(views);
        }
      }
      if (this.mounted) {
        setState(() {
          viewsData = true;
        });
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get view error: " + err.toString());
    });
  }

  void getRemarks() {
    http.post(urlRemarks, body: {
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "phone_number": phoneNo,
    }).then((res) {
      // print("VProfileRemarks body: " + res.body);
      if (res.body == "nodata") {
        Remarks remark = Remarks(
          date: "",
          remark: "",
          system: "",
        );
        vProfileRemarks.add(remark);
      } else {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          Remarks remark = Remarks(
            date: data['date'],
            remark: data['remark'],
            system: data['system'],
          );
          vProfileRemarks.add(remark);
        }
      }
      if (this.mounted) {
        setState(() {
          remarksData = true;
        });
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get remark error: " + err.toString());
    });
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.of(context).pop();
    return Future.value(false);
  }

  void setStatus(newVal) {
    http.post(urlChangeStatus, body: {
      "phone_number": phoneNo,
      "companyID": companyID,
      "branchID": branchID,
      "userID": userID,
      "level": level,
      "user_type": userType,
      "status": newVal,
    }).then((res) {
      if (res.body == "success") {
        if (this.mounted) {
          setState(() {
            status = newVal;
          });
        }
        _toast("Status changed");
      } else {
        if (this.mounted) {
          setState(() {
            status = status;
          });
        }
        _toast("Status can't change, please contact VVIN help desk");
      }
    }).catchError((err) {
      if (this.mounted) {
        setState(() {
          status = status;
        });
      }
      _toast("Status can't change, please check your Internet connection");
      print("Set status error: " + err.toString());
    });
  }
}

class Details extends StatefulWidget {
  final List<VProfileData> vProfileDetails;
  final List handler;
  final VDataDetails vdata;
  final List vtag;
  const Details({
    Key key,
    this.vProfileDetails,
    this.handler,
    this.vdata,
    this.vtag,
  }) : super(key: key);

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
  int emailLength;
  File file;
  List<String> phoneList = [];
  List<String> otherList = [];
  bool ready = false;

  @override
  void initState() {
    emailLength = (widget.vProfileDetails[0].email.length / 18).ceil();
    setup();
    super.initState();
  }

  void setup() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String pathName = dir.path.toString() + "/attachment.png";
    if (this.mounted) {
      setState(() {
        file = File(pathName);
        ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return Scaffold(
      body: (ready == false)
          ? Container()
          : Container(
              padding: EdgeInsets.fromLTRB(
                  0, ScreenUtil().setHeight(20), 0, ScreenUtil().setHeight(20)),
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          _editVProfile();
                        },
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                              0, 0, ScreenUtil().setHeight(20), 0),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: font16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: ScrollPhysics(),
                      child: Column(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    width: ScreenUtil().setHeight(2),
                                    color: Colors.grey.shade300),
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: (widget.handler.length == 0)
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  "Handler",
                                                  style: TextStyle(
                                                      fontSize: font16,
                                                      color: Color.fromRGBO(
                                                          128, 128, 128, 1)),
                                                )
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: _handlerLength(
                                                  widget.handler.length),
                                            ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    (widget.handler.length == 0)
                                        ? Flexible(
                                            flex: 1,
                                            child: Container(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Flexible(
                                                    child: Text(
                                                      "-",
                                                      style: TextStyle(
                                                        fontSize: font16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Flexible(
                                            flex: 1,
                                            child: Column(
                                              children: _handler(),
                                            ),
                                          ),
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: (emailLength == 0)
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  "Email",
                                                  style: TextStyle(
                                                      fontSize: font16,
                                                      color: Color.fromRGBO(
                                                          128, 128, 128, 1)),
                                                )
                                              ],
                                            )
                                          : Column(
                                              children: _emailLength(),
                                            ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                  (widget.vProfileDetails[0]
                                                              .email ==
                                                          "")
                                                      ? "-"
                                                      : widget
                                                          .vProfileDetails[0]
                                                          .email,
                                                  style: TextStyle(
                                                    fontSize: font16,
                                                  ),
                                                  textAlign: TextAlign.left),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Company",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .company ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .company,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              "IC/Passport",
                                              style: TextStyle(
                                                  fontSize: font16,
                                                  color: Color.fromRGBO(
                                                      128, 128, 128, 1)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0].ic ==
                                                        "")
                                                    ? "-"
                                                    : widget
                                                        .vProfileDetails[0].ic,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              "Date of Birth",
                                              style: TextStyle(
                                                  fontSize: font16,
                                                  color: Color.fromRGBO(
                                                      128, 128, 128, 1)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .dob ==
                                                        "")
                                                    ? "-"
                                                    : _dateFormat(widget
                                                        .vProfileDetails[0]
                                                        .dob),
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Gender",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              (widget.vProfileDetails[0]
                                                          .gender ==
                                                      "")
                                                  ? "-"
                                                  : _gender(widget
                                                      .vProfileDetails[0]
                                                      .gender),
                                              style: TextStyle(
                                                fontSize: font16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Position",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .position ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .position,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Industry",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .industry ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .industry,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Occupation",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .occupation ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .occupation,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Country",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .country ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .country,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                (widget.vProfileDetails[0].country ==
                                        "Malaysia")
                                    ? SizedBox(
                                        height: ScreenUtil().setHeight(10),
                                      )
                                    : SizedBox(
                                        height: 0,
                                      ),
                                (widget.vProfileDetails[0].country ==
                                        "Malaysia")
                                    ? Row(
                                        children: <Widget>[
                                          Flexible(
                                            flex: 1,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: <Widget>[
                                                Text(
                                                  "State",
                                                  style: TextStyle(
                                                      fontSize: font16,
                                                      color: Color.fromRGBO(
                                                          128, 128, 128, 1)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                            width: ScreenUtil().setWidth(20),
                                          ),
                                          Flexible(
                                            flex: 1,
                                            child: Container(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Flexible(
                                                    child: Text(
                                                      (widget.vProfileDetails[0]
                                                                  .state ==
                                                              "")
                                                          ? "-"
                                                          : widget
                                                              .vProfileDetails[
                                                                  0]
                                                              .state,
                                                      style: TextStyle(
                                                        fontSize: font16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      )
                                    : Row(),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Area",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .area ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .area,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "App",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .app ==
                                                        "")
                                                    ? "-"
                                                    : widget
                                                        .vProfileDetails[0].app,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Channel",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .channel ==
                                                        "")
                                                    ? "-"
                                                    : widget.vProfileDetails[0]
                                                        .channel,
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Created",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                _dateFormat(widget
                                                    .vProfileDetails[0]
                                                    .created),
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(10),
                                ),
                                Row(
                                  children: <Widget>[
                                    Flexible(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text(
                                            "Last Active",
                                            style: TextStyle(
                                                fontSize: font16,
                                                color: Color.fromRGBO(
                                                    128, 128, 128, 1)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: ScreenUtil().setWidth(20),
                                    ),
                                    Flexible(
                                      flex: 1,
                                      child: Container(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                (widget.vProfileDetails[0]
                                                            .lastActive !=
                                                        "")
                                                    ? _dateFormat(widget
                                                        .vProfileDetails[0]
                                                        .lastActive)
                                                    : "-",
                                                style: TextStyle(
                                                  fontSize: font16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: ScreenUtil().setHeight(30),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    width: ScreenUtil().setHeight(2),
                                    color: Colors.grey.shade300),
                              ),
                            ),
                            child: Container(
                              margin:
                                  EdgeInsets.all(ScreenUtil().setHeight(20)),
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "TAGS",
                                        style: TextStyle(
                                          fontSize: font16,
                                          color:
                                              Color.fromRGBO(128, 128, 128, 1),
                                        ),
                                      )
                                    ],
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(0.5),
                                    child: Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                            margin: EdgeInsets.fromLTRB(
                                                ScreenUtil().setHeight(10),
                                                0,
                                                0,
                                                0),
                                            child: Wrap(
                                              direction: Axis.horizontal,
                                              alignment: WrapAlignment.start,
                                              children: _vtagLength(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          (widget.vProfileDetails[0].img != "" ||
                                  isScan == true)
                              ? Container(
                                  margin: EdgeInsets.all(
                                      ScreenUtil().setHeight(20)),
                                  child: Column(
                                    children: <Widget>[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            "Attachment",
                                            style: TextStyle(
                                              fontSize: font16,
                                              color: Color.fromRGBO(
                                                  128, 128, 128, 1),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: ScreenUtil().setHeight(20),
                                      ),
                                      (isScan == false)
                                          ? InkWell(
                                              onTap: () {
                                                Navigator.push(context,
                                                    MaterialPageRoute(
                                                        builder: (_) {
                                                  return ImageScreen(
                                                    image: widget
                                                        .vProfileDetails[0].img,
                                                  );
                                                }));
                                              },
                                              child: Hero(
                                                tag: 'imageHero',
                                                child: Container(
                                                  height: ScreenUtil()
                                                      .setHeight(500),
                                                  width: ScreenUtil()
                                                      .setHeight(500),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.rectangle,
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                10.0)),
                                                    image: DecorationImage(
                                                      image: CachedNetworkImageProvider(
                                                          widget
                                                              .vProfileDetails[
                                                                  0]
                                                              .img),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (_) {
                                                    return ImageScreen(
                                                      fileImage: pickedImage,
                                                    );
                                                  }));
                                                },
                                                child: Hero(
                                                  tag: 'imageHero',
                                                  child: Container(
                                                    height: 177,
                                                    width: 280,
                                                    decoration: BoxDecoration(
                                                      image: DecorationImage(
                                                          image: FileImage(
                                                              pickedImage),
                                                          fit: BoxFit.contain),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                )
                              : Container(),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  List<Widget> _handlerLength(int length) {
    List widgetList = <Widget>[];
    for (var i = 0; i < length; i++) {
      Widget widget1 = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          (i == 0)
              ? Text(
                  "Handler",
                  style: TextStyle(
                      fontSize: font16,
                      color: Color.fromRGBO(128, 128, 128, 1)),
                )
              : Text(""),
        ],
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _handler() {
    List widgetList = <Widget>[];
    for (var i in widget.handler) {
      Widget widget1 = Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Flexible(
              child: Text(
                i.toString(),
                style: TextStyle(
                  fontSize: font16,
                ),
              ),
            ),
          ],
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _emailLength() {
    List widgetList = <Widget>[];
    for (var i = 0; i < emailLength; i++) {
      Widget widget1 = Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          (i == 0)
              ? Text(
                  "Email",
                  style: TextStyle(
                      fontSize: font16,
                      color: Color.fromRGBO(128, 128, 128, 1)),
                )
              : Text(""),
        ],
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  List<Widget> _vtagLength() {
    List widgetList = <Widget>[];
    for (int i = 0; i < widget.vtag.length ?? 0; i++) {
      Widget widget1 = Container(
        width: ScreenUtil().setWidth((widget.vtag[i].length * 28)),
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
              widget.vtag[i],
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
      widgetList.add(widget1);
    }
    return widgetList;
  }

  void _editVProfile() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      VProfileData vprofile = VProfileData(
        name: widget.vProfileDetails[0].name,
        email: widget.vProfileDetails[0].email,
        company: widget.vProfileDetails[0].company,
        ic: widget.vProfileDetails[0].ic,
        dob: widget.vProfileDetails[0].dob,
        gender: (widget.vProfileDetails[0].gender == "")
            ? ""
            : _gender(widget.vProfileDetails[0].gender),
        position: widget.vProfileDetails[0].position,
        industry: widget.vProfileDetails[0].industry,
        occupation: widget.vProfileDetails[0].occupation,
        country: widget.vProfileDetails[0].country,
        state: widget.vProfileDetails[0].state,
        area: widget.vProfileDetails[0].area,
        created: widget.vProfileDetails[0].created,
        lastActive: widget.vProfileDetails[0].lastActive,
      );
      Navigator.of(context).push(PageTransition(
        type: PageTransitionType.rippleRightDown,
        child: (isScan == false)
            ? EditVProfile(
                vprofileData: vprofile,
                handler: widget.handler,
                vdata: widget.vdata,
                vtag: widget.vtag,
              )
            : EditVProfile(
                vprofileData: vprofile,
                handler: widget.handler,
                vdata: widget.vdata,
                vtag: widget.vtag,
                details: full,
              ),
      ));
    } else {
      _toast("Please check your Internet connection");
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

  String _dateFormat(String fullDate) {
    String result, date, month, year;
    date = fullDate.substring(8, 10);
    month = checkMonth(fullDate.substring(5, 7));
    year = fullDate.substring(0, 4);
    result = date + " " + month + " " + year;
    return result;
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

  String _gender(String genderType) {
    String gender;
    switch (genderType.toLowerCase()) {
      case "m":
        gender = "Male";
        break;
      case "f":
        gender = "Female";
        break;
      case "o":
        gender = "Other";
        break;
    }
    return gender;
  }
}

class Views extends StatefulWidget {
  final List<View> vProfileViews;
  const Views({Key key, this.vProfileViews}) : super(key: key);

  @override
  _ViewsState createState() => _ViewsState();
}

class _ViewsState extends State<Views> {
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  double font28 = ScreenUtil().setSp(64.4, allowFontScalingSelf: false);

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Container(
              height: ScreenUtil().setHeight(80),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border(bottom: BorderSide(color: Colors.grey.shade300))),
              child: Center(
                child: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        text: (widget.vProfileViews[0].date == "")
                            ? "0"
                            : widget.vProfileViews.length.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: font28,
                            color: Colors.black),
                      ),
                      TextSpan(
                        text: ' Total Views',
                        style: TextStyle(fontSize: font18, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            (widget.vProfileViews[0].date == "")
                ? Container()
                : Flexible(
                    child: SingleChildScrollView(
                      physics: ScrollPhysics(),
                      child: ListView.builder(
                        itemCount: widget.vProfileViews.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemBuilder: (BuildContext context, int index) =>
                            Container(
                          color: Colors.white,
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.fromLTRB(
                            ScreenUtil().setHeight(10),
                            ScreenUtil().setHeight(20),
                            ScreenUtil().setHeight(10),
                            ScreenUtil().setHeight(20),
                          ),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    widget.vProfileViews[index].date.toString(),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: font12,
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Flexible(
                                      child: Text(
                                    widget.vProfileViews[index].link,
                                    style: TextStyle(
                                      fontSize: font14,
                                    ),
                                  ))
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class Remark extends StatefulWidget {
  final List<Remarks> vProfileRemarks;
  final VDataDetails vdata;
  const Remark({Key key, this.vProfileRemarks, this.vdata}) : super(key: key);

  @override
  _RemarkState createState() => _RemarkState();
}

class _RemarkState extends State<Remark> {
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
  final TextEditingController _addRemark = TextEditingController();
  String urlSaveRemark = ip + "saveRemark.php";
  bool isSend = false;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                InkWell(
                  onTap: () {
                    _addRemarks();
                  },
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0, ScreenUtil().setHeight(20),
                        ScreenUtil().setHeight(20), 0),
                    child: Text(
                      "Add Remark",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: font14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: ScrollPhysics(),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount: widget.vProfileRemarks.length,
                  itemBuilder: (BuildContext context, int index) => Container(
                    color: Colors.white,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(
                      horizontal: ScreenUtil().setHeight(10),
                      vertical: ScreenUtil().setHeight(15),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.vProfileRemarks[index].date
                                  .toUpperCase()
                                  .substring(0, 10),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: font12,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            (widget.vProfileRemarks[index].system == "no")
                                ? Container()
                                : Container(
                                    padding: EdgeInsets.all(0.5),
                                    width: ScreenUtil().setHeight(180),
                                    height: ScreenUtil().setHeight(40),
                                    child: FlatButton(
                                      child: Text(
                                        "System",
                                        style: TextStyle(
                                          fontSize: font12,
                                        ),
                                      ),
                                      textColor: Colors.white,
                                      color: Colors.blue,
                                      onPressed: () {},
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                      ),
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
                              child: Text(
                                widget.vProfileRemarks[index].remark,
                                style: TextStyle(
                                  fontSize: font14,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addRemarks() {
    showGeneralDialog(
        barrierDismissible: false,
        barrierColor: Colors.grey.withOpacity(0.5),
        transitionBuilder: (context, a1, a2, widget) {
          final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
          return Transform(
            transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
            child: Opacity(
              opacity: a1.value,
              child: AlertDialog(
                shape: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                elevation: 1.0,
                title: Text(
                  "Add new remark",
                  style: TextStyle(
                    fontSize: font16,
                  ),
                ),
                content: Container(
                  decoration: BoxDecoration(
                      color: Color.fromRGBO(235, 235, 255, 1),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  height: MediaQuery.of(context).size.height * 0.2,
                  child: TextField(
                    style: TextStyle(
                      fontSize: font14,
                    ),
                    maxLines: 5,
                    controller: _addRemark,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
                actions: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      // FloatingActionButton(
                      //   child: Icon(
                      //     Icons.mic,
                      //     // color: (start == false) ? Colors.pink : Colors.grey,
                      //   ),
                      //   mini: true,
                      //   onPressed: () {
                      //     initSpeechState();
                      //     startListening();
                      //     // setState(() {
                      //     //   start = true;
                      //     // });
                      //   },
                      //   backgroundColor:
                      //   // Colors.pink,
                      //   (start == false)
                      //   ? Colors.pink
                      //   : Colors.grey,
                      // ),
                      // SizedBox(
                      //   width: MediaQuery.of(context).size.width * 0.2,
                      // ),
                      FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: font14,
                          ),
                        ),
                      ),
                      FlatButton(
                        onPressed: _onSubmit,
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: font14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
        context: context,
        pageBuilder: (context, animation1, animation2) {});
  }

  void _onSubmit() async {
    if (isSend == false) {
      if (_addRemark.text == "") {
        _toast("Please key in something");
      } else {
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          if (this.mounted) {
            setState(() {
              isSend = true;
            });
          }
          http.post(urlSaveRemark, body: {
            "companyID": widget.vdata.companyID,
            "branchID": widget.vdata.branchID,
            "userID": widget.vdata.userID,
            "level": widget.vdata.level,
            "user_type": widget.vdata.userType,
            "phone_number": widget.vdata.phoneNo,
            "remark": _addRemark.text,
          }).then((res) async {
            if (res.body == "success") {
              VDataDetails vdata = new VDataDetails(
                companyID: widget.vdata.companyID,
                branchID: widget.vdata.branchID,
                userID: widget.vdata.userID,
                level: widget.vdata.level,
                userType: widget.vdata.userType,
                name: widget.vdata.name,
                phoneNo: widget.vdata.phoneNo,
                status: widget.vdata.status,
                email: widget.vdata.email,
              );
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VProfile(vdata: vdata)));
              _addRemark.text = "";
            } else {
              Navigator.pop(context);
              _addRemark.text = "";
              _toast("Please contact VVIN help desk");
            }
          }).catchError((err) {
            Navigator.pop(context);
            _addRemark.text = "";
            _toast("No Internet Connection, data can't save");
            print("On submit error: " + err.toString());
          });
        } else {
          _toast("Please check your Internet connection");
        }
      }
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
}

class ImageScreen extends StatefulWidget {
  final String image;
  final File fileImage;
  const ImageScreen({Key key, this.image, this.fileImage}) : super(key: key);

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
            "Name Card",
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
            child: (widget.image != null)
                ? Hero(
                    tag: 'imageHero',
                    child: Container(
                      child: PhotoView(
                        imageProvider: CachedNetworkImageProvider(widget.image),
                      ),
                    ),
                  )
                : Hero(
                    tag: 'imageHero',
                    child: Container(
                      child: PhotoView(
                        imageProvider: FileImage(pickedImage),
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
