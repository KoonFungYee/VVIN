import 'dart:convert';
import 'dart:io';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_awesome_buttons/flutter_awesome_buttons.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ndialog/ndialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/data.dart';
import 'package:vvin/editVProfile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
// import 'package:speech_to_text/speech_to_text.dart';
// import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vvin/notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:scalable_image/scalable_image.dart';

class VProfile extends StatefulWidget {
  final VDataDetails vdata;
  const VProfile({Key key, this.vdata}) : super(key: key);

  @override
  _VProfileState createState() => _VProfileState();
}

enum UniLinksType { string, uri }

class _VProfileState extends State<VProfile>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // final SpeechToText speech = SpeechToText();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  SharedPreferences prefs;
  double _scaleFactor = 1.0;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final TextEditingController _addRemark = TextEditingController();
  TabController controller;
  List handler;
  List vTag;
  List<VProfileData> vProfileDetails = [];
  List<View> vProfileViews = [];
  List<Remarks> vProfileRemarks = [];
  String name,
      phoneNo,
      status,
      companyID,
      userID,
      level,
      userType,
      resultText,
      now,
      speechText;
  String urlVProfile = "https://vvinoa.vvin.com/api/vprofile.php";
  String urlHandler = "https://vvinoa.vvin.com/api/handler.php";
  String urlVTag = "https://vvinoa.vvin.com/api/vtag.php";
  String urlViews = "https://vvinoa.vvin.com/api/views.php";
  String urlRemarks = "https://vvinoa.vvin.com/api/remarks.php";
  String urlChangeStatus = "https://vvinoa.vvin.com/api/vdataChangeStatus.php";
  String urlSaveRemark = "https://vvinoa.vvin.com/api/saveRemark.php";
  bool vProfileData,
      handlerData,
      viewsData,
      remarksData,
      vTagData,
      hasSpeech,
      start,
      isSend;
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
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
    controller = TabController(vsync: this, length: 3, initialIndex: 0);
    check();
    _init();
    name = widget.vdata.name;
    phoneNo = widget.vdata.phoneNo;
    status = widget.vdata.status;
    companyID = widget.vdata.companyID;
    userID = widget.vdata.userID;
    level = widget.vdata.level;
    userType = widget.vdata.userType;
    vProfileData = false;
    handlerData = false;
    viewsData = false;
    remarksData = false;
    vTagData = false;
    hasSpeech = false;
    start = false;
    isSend = false;
    speechText = "";
    resultText = "";
    _addRemark.text = "";
    WidgetsBinding.instance.addObserver(this);
    // PermissionHandler().checkPermissionStatus(PermissionGroup.microphone);
    // askPermission();
    // initSpeechState();
    checkConnection();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        prefs = await SharedPreferences.getInstance();
        _showNotification();
        // Vibration.vibrate();
        // bool noti = false;
        // if (noti == false) {
        //   showDialog(
        //     barrierDismissible: false,
        //     context: context,
        //     builder: (BuildContext context) => NDialog(
        //       dialogStyle: DialogStyle(titleDivider: true),
        //       title: Text("New Notification"),
        //       content: Text("You have 1 new notification"),
        //       actions: <Widget>[
        //         FlatButton(
        //             child: Text("View"),
        //             onPressed: () {
        //               Navigator.of(context).pop();
        //               Navigator.of(context).pop();
        //               Navigator.of(context).pushReplacement(
        //                 MaterialPageRoute(
        //                   builder: (context) => Notifications(),
        //                 ),
        //               );
        //               prefs.setString('onMessage', now);
        //             }),
        //         FlatButton(
        //             child: Text("Later"),
        //             onPressed: () {
        //               Navigator.of(context).pop();
        //               Navigator.of(context).pop();
        //               if (this.mounted) {
        //                 setState(() {
        //                   noti = false;
        //                 });
        //               }
        //             }),
        //       ],
        //     ),
        //   );
        //   noti = true;
        // }
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
    // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
    // of the `IOSFlutterLocalNotificationsPlugin` class
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
              onPressed: () async {
                // Navigator.of(context, rootNavigator: true).pop();
                // await Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) =>
                //         SecondScreen(receivedNotification.payload),
                //   ),
                // );
              },
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getString('onMessage') != payload) {
        Navigator.of(context).pushReplacement(PageTransition(
          duration: Duration(milliseconds: 1),
          type: PageTransitionType.transferUp,
          child: Notifications(),
        ));
      }
      prefs.setString('onMessage', payload);
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
    WidgetsBinding.instance.removeObserver(this);
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
              actions: <Widget>[popupMenuButton()],
            ),
          ),
          body: Column(
            children: <Widget>[
              Container(
                margin:
                    EdgeInsets.fromLTRB(0, ScreenUtil().setHeight(15), 0, 0),
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
                height: ScreenUtil().setHeight(15),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  BouncingWidget(
                    scaleFactor: _scaleFactor,
                    onPressed: () async {
                      var connectivityResult =
                          await (Connectivity().checkConnectivity());
                      if (connectivityResult == ConnectivityResult.wifi ||
                          connectivityResult == ConnectivityResult.mobile) {
                        FlutterOpenWhatsapp.sendSingleMessage(phoneNo, "");
                      } else {
                        _toast("This feature need Internet connection");
                      }
                    },
                    child: ButttonWithIcon(
                      icon: FontAwesomeIcons.whatsapp,
                      title: "WhatsApp",
                      buttonColor: Color.fromRGBO(37, 211, 102, 1),
                      onPressed: () async {
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
                  ),
                ],
              ),
              SizedBox(
                height: ScreenUtil().setHeight(20),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: ScreenUtil().setWidth(320),
                    height: ScreenUtil().setHeight(60),
                    padding: EdgeInsets.all(
                      ScreenUtil().setHeight(10),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.0),
                      border: Border.all(
                          color: Colors.grey.shade400,
                          style: BorderStyle.solid),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                        isExpanded: true,
                        isDense: true,
                        items: data.map((item) {
                          return DropdownMenuItem(
                            child: Text(
                              item.toString(),
                              style: TextStyle(
                                fontSize: font14,
                              ),
                            ),
                            value: item.toString(),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          setStatus(newVal);
                        },
                        value: status,
                      ),
                    ),
                  ),
                ],
              ),
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
                  body: TabBarView(controller: controller, children: <Widget>[
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
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  JumpingText('Loading...'),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
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
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  JumpingText('Loading...'),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
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
                          )
                        : Container(
                            color: Colors.white,
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  JumpingText('Loading...'),
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
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
                  ]),
                ),
              ),
            ],
          )),
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
          value: "add remark",
          child: Text(
            "Add Remark",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: "edit",
          child: Text(
            "Edit",
            style: TextStyle(
              fontSize: font14,
            ),
          ),
        ),
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

          case "edit":
            {
              _editVProfile();
            }
            break;
        }
      },
    );
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
        child: EditVProfile(
          vprofileData: vprofile,
          handler: handler,
          vdata: widget.vdata,
          vtag: vTag,
        ),
      ));
    } else {
      _toast("Please check your Internet connection");
    }
  }

  String _gender(String gender) {
    switch (gender.toLowerCase()) {
      case "m":
        return "Male";
        break;
      case "f":
        return "Female";
        break;
      case "o":
        return "Other";
        break;
    }
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
            "userID": userID,
            "level": level,
            "user_type": userType,
            "phone_number": phoneNo,
            "remark": _addRemark.text,
          }).then((res) async {
            if (res.body == "success") {
              VDataDetails vdata = new VDataDetails(
                companyID: widget.vdata.companyID,
                userID: widget.vdata.userID,
                level: widget.vdata.level,
                userType: widget.vdata.userType,
                name: widget.vdata.name,
                phoneNo: widget.vdata.phoneNo,
                status: widget.vdata.status,
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
            print("On submit error: " + (err).toString());
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
      getVProfileData();
      getHandler();
      getViews();
      getRemarks();
      getVTag();
    } else {
      _toast("No Internet connection! Can't show");
    }
  }

  void getVTag() {
    http.post(urlVTag, body: {
      "companyID": companyID,
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
      print("Get VTag error: " + (err).toString());
    });
  }

  void getVProfileData() {
    http.post(urlVProfile, body: {
      "companyID": companyID,
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
          );
          vProfileDetails.add(vprofile);
        }
      }
      if (this.mounted) {
        setState(() {
          vProfileData = true;
        });
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get VProfile data error: " + (err).toString());
    });
  }

  void getHandler() {
    http.post(urlHandler, body: {
      "companyID": companyID,
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
    }).catchError((err) {
      _toast(err.toString());
      print("Get handler error: " + (err).toString());
    });
  }

  void getViews() {
    http.post(urlViews, body: {
      "companyID": companyID,
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
      print("Get view error: " + (err).toString());
    });
  }

  void getRemarks() {
    http.post(urlRemarks, body: {
      "companyID": companyID,
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
      print("Get remark error: " + (err).toString());
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
      print("Set status error: " + (err).toString());
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
  File file, pickedImage;
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
                                              children: <Widget>[
                                                for (var i = 0;
                                                    i < widget.handler.length;
                                                    i++)
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: <Widget>[
                                                      (i == 0)
                                                          ? Text(
                                                              "Handler",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      font16,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          128,
                                                                          128,
                                                                          128,
                                                                          1)),
                                                            )
                                                          : Text(""),
                                                    ],
                                                  ),
                                              ],
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
                                              children: <Widget>[
                                                for (var i in widget.handler)
                                                  Container(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
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
                                                  ),
                                              ],
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
                                              children: <Widget>[
                                                for (var i = 0;
                                                    i < emailLength;
                                                    i++)
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: <Widget>[
                                                      (i == 0)
                                                          ? Text(
                                                              "Email",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      font16,
                                                                  color: Color
                                                                      .fromRGBO(
                                                                          128,
                                                                          128,
                                                                          128,
                                                                          1)),
                                                            )
                                                          : Text(""),
                                                    ],
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
                                              children: <Widget>[
                                                for (int i = 0;
                                                    i < widget.vtag.length ?? 0;
                                                    i++)
                                                  Container(
                                                    width: ScreenUtil()
                                                        .setWidth((widget
                                                                .vtag[i]
                                                                .length *
                                                            28)),
                                                    margin: EdgeInsets.all(
                                                        ScreenUtil()
                                                            .setHeight(5)),
                                                    decoration: BoxDecoration(
                                                      color: Color.fromRGBO(
                                                          235, 235, 255, 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              100),
                                                    ),
                                                    padding: EdgeInsets.all(
                                                      ScreenUtil()
                                                          .setHeight(10),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
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
                                                  ),
                                              ],
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
                          (widget.vProfileDetails[0].img == "")
                              ? Container()
                              : Container(
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
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: ScreenUtil().setHeight(20),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(context,
                                              MaterialPageRoute(builder: (_) {
                                            return ImageScreen(
                                              image:
                                                  widget.vProfileDetails[0].img,
                                            );
                                          }));
                                        },
                                        child: Hero(
                                          tag: 'imageHero',
                                          child: Container(
                                            height: ScreenUtil().setHeight(500),
                                            width: ScreenUtil().setHeight(500),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10.0)),
                                              image: DecorationImage(
                                                image:
                                                    CachedNetworkImageProvider(
                                                        widget
                                                            .vProfileDetails[0]
                                                            .img),
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
                    ),
                  )
                ],
              ),
            ),
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

  String _gender(String gender) {
    switch (gender.toLowerCase()) {
      case "m":
        return "Male";
        break;
      case "f":
        return "Female";
        break;
      case "o":
        return "Other";
        break;
    }
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
  const Remark({Key key, this.vProfileRemarks}) : super(key: key);

  @override
  _RemarkState createState() => _RemarkState();
}

class _RemarkState extends State<Remark> {
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Row(
          children: <Widget>[
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
}

class ImageScreen extends StatefulWidget {
  final String image;
  const ImageScreen({Key key, this.image}) : super(key: key);

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
            child: Hero(
              tag: 'imageHero',
              child: ScalableImage(
                imageProvider: NetworkImage(widget.image),
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
