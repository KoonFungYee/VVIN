import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:fake_whatsapp/fake_whatsapp.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/reminder.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvin/data.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vdata.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:google_api_availability/google_api_availability.dart';

_WhatsAppForwardState pageState;

class Item1 {
  Item1(this.group, this.status);
  PermissionGroup group;
  PermissionStatus status;
}

class WhatsAppForward extends StatefulWidget {
  final WhatsappForward whatsappForward;
  WhatsAppForward({Key key, this.whatsappForward}) : super(key: key);

  @override
  _WhatsAppForwardState createState() {
    pageState = _WhatsAppForwardState();
    return pageState;
  }
}

enum UniLinksType { string, uri }

class _WhatsAppForwardState extends State<WhatsAppForward> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  final ScrollController controller = ScrollController();
  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _companycontroller = TextEditingController();
  final TextEditingController _remarkcontroller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchVTagController = TextEditingController();
  final ScrollController whatsappController = ScrollController();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  Whatsapp _whatsapp = Whatsapp();
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  var _phonecontroller = MaskedTextController(mask: '000000000000000000');
  double _scaleFactor = 1.0;
  String urlWhatsApp = ip + "whatsappForward.php";
  File pickedImage;
  bool _phoneEmpty, _nameEmpty, _phoneInvalid, isImageLoaded, isSend, gotGoogle;
  List<String> phoneList = [];
  List<String> otherList = [];
  List seletedVTag = [];
  List vTagList = [];
  List<ContactInfo> contactList = [];
  List<ContactInfo> contactList1 = [];
  List<Item1> list = List<Item1>();
  List<RadioItem> radioItems = [];
  List<RadioItem> vTagItems = [];
  String pathName,
      base64Image,
      tempText,
      number,
      platform,
      selectedName,
      selectedPhone,
      selectedVTag,
      companyID,
      userID,
      branchID,
      userType,
      level;

  @override
  void initState() {
    check();
    _init();
    try {
      _namecontroller.text = widget.whatsappForward.name ?? '';
      _phonecontroller.text = widget.whatsappForward.phone ?? '';
      seletedVTag = widget.whatsappForward.vtag ?? [];
      vTagList = widget.whatsappForward.vtagList ?? [];
      if (vTagList[0] == '-') {
        vTagList.removeAt(0);
      }
    } catch (e) {}
    list.clear();
    list.add(Item1(PermissionGroup.values[2], PermissionStatus.denied));
    gotGoogle = isSend = isImageLoaded = false;
    selectedVTag =
        selectedName = selectedPhone = tempText = base64Image = number = "";
    initialise();
    checkGoogle();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        _showNotification();
      },
    );
    super.initState();
  }

  Future<void> checkGoogle([bool showDialog = false]) async {
    GooglePlayServicesAvailability playStoreAvailability;
    try {
      playStoreAvailability = await GoogleApiAvailability.instance
          .checkGooglePlayServicesAvailability(showDialog);
    } catch (e) {
      playStoreAvailability = GooglePlayServicesAvailability.unknown;
    }
    if (Platform.isAndroid) {
      if (playStoreAvailability.toString() ==
          'GooglePlayServicesAvailability.success') {
        gotGoogle = true;
      }
    }
  }

  Future<void> initialise() async {
    bool whatsapp = await _whatsapp.isWhatsappInstalled();
    if (whatsapp == true) {
      platform = "android";
    } else {
      platform = "ios";
    }
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
    String now = DateTime.now().millisecondsSinceEpoch.toString();
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
    YYDialog.init(context);
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            controller: controller,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.97,
              child: Column(
                children: <Widget>[
                  Flexible(
                    child: Scaffold(
                      resizeToAvoidBottomInset: true,
                      body: SingleChildScrollView(
                        physics: ScrollPhysics(),
                        controller: whatsappController,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(
                              ScreenUtil().setHeight(30),
                              ScreenUtil().setHeight(20),
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
                                      _onBackPressAppBar();
                                    },
                                  )
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(
                                    "Whatsapp Forward",
                                    style: TextStyle(
                                        fontSize: font18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(50),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Recipient Name Card",
                                    style: TextStyle(
                                        color: Colors.black, fontSize: font14),
                                  ),
                                ],
                              ),
                              (isImageLoaded)
                                  ? Container()
                                  : Column(
                                      children: <Widget>[
                                        SizedBox(
                                          height: ScreenUtil().setHeight(5),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Flexible(
                                              child: RichText(
                                                text: TextSpan(children: [
                                                  TextSpan(
                                                    text:
                                                        "Snap a photo of the recipient’s name card to fill form faster.",
                                                    style: TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: font14),
                                                  ),
                                                  TextSpan(
                                                    text:
                                                        " *Please make sure the photo is horizontally.",
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: font14),
                                                  ),
                                                ]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              SizedBox(
                                height: ScreenUtil().setHeight(10),
                              ),
                              (isImageLoaded)
                                  ? Center(
                                      child: Container(
                                        height: 177,
                                        width: 280,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: FileImage(pickedImage),
                                              fit: BoxFit.contain),
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      children: <Widget>[
                                        Stack(
                                          children: <Widget>[
                                            Container(
                                              width: ScreenUtil().setWidth(140),
                                              height:
                                                  ScreenUtil().setHeight(140),
                                              decoration: BoxDecoration(
                                                color: Color.fromARGB(
                                                    100, 220, 220, 220),
                                                shape: BoxShape.rectangle,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10.0)),
                                              ),
                                            ),
                                            Positioned(
                                              top: ScreenUtil().setHeight(20),
                                              left: ScreenUtil().setWidth(20),
                                              child: Container(
                                                width:
                                                    ScreenUtil().setWidth(100),
                                                height:
                                                    ScreenUtil().setHeight(100),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.rectangle,
                                                  color: Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(10.0),
                                                  ),
                                                ),
                                                child: Icon(
                                                  FontAwesomeIcons.addressCard,
                                                  color: Colors.grey,
                                                  size: ScreenUtil()
                                                      .setHeight(40),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          margin: EdgeInsets.fromLTRB(
                                              ScreenUtil().setHeight(150),
                                              ScreenUtil().setHeight(40),
                                              0,
                                              0),
                                          child: Column(
                                            children: <Widget>[
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Flexible(
                                                    child: InkWell(
                                                      onTap: () {
                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                new FocusNode());
                                                        _scanner();
                                                      },
                                                      child: Text(
                                                        (gotGoogle == false)
                                                            ? 'Choose from contact book'
                                                            : "Take Photo / Choose from contact book",
                                                        style: TextStyle(
                                                            color: Colors.blue,
                                                            fontSize: font14),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                              SizedBox(
                                height: ScreenUtil().setHeight(30),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text("Recipient Phone Number",
                                      style: TextStyle(fontSize: font14)),
                                  Text(" - Required",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: font14,
                                          fontStyle: FontStyle.italic))
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Container(
                                height: ScreenUtil().setHeight(60),
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
                                      child: TextField(
                                        controller: _phonecontroller,
                                        style: TextStyle(
                                          height: 1,
                                          fontSize: font14,
                                        ),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: "eg. 6012XXXXXXXX",
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.only(
                                              left: ScreenUtil().setHeight(10),
                                              bottom:
                                                  ScreenUtil().setHeight(20),
                                              top: ScreenUtil().setHeight(-15),
                                              right:
                                                  ScreenUtil().setHeight(20)),
                                        ),
                                      ),
                                    ),
                                    (isImageLoaded == true)
                                        ? InkWell(
                                            onTap: () {
                                              if (phoneList.length != 0) {
                                                _showBottomSheet("phone");
                                              } else {
                                                _toast(
                                                    "No phone number detected");
                                              }
                                            },
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setHeight(60),
                                              child: Center(
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                              (_phoneEmpty == true)
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          "Phone number can't be empty",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: font12),
                                        )
                                      ],
                                    )
                                  : Row(),
                              (_phoneInvalid == true)
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          "Invalid phone number",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: font12),
                                        )
                                      ],
                                    )
                                  : Row(),
                              SizedBox(
                                height: ScreenUtil().setHeight(30),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text("Recipient Name"),
                                  Text(" - Required",
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: font14,
                                          fontStyle: FontStyle.italic))
                                ],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Container(
                                height: ScreenUtil().setHeight(60),
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
                                      child: TextField(
                                        controller: _namecontroller,
                                        style: TextStyle(
                                          height: 1,
                                          fontSize: font14,
                                        ),
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: "eg. David",
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.only(
                                              left: ScreenUtil().setHeight(10),
                                              bottom:
                                                  ScreenUtil().setHeight(20),
                                              top: ScreenUtil().setHeight(-15),
                                              right:
                                                  ScreenUtil().setHeight(20)),
                                        ),
                                      ),
                                    ),
                                    (isImageLoaded == true)
                                        ? InkWell(
                                            onTap: () {
                                              _showBottomSheet(
                                                  "_namecontroller");
                                            },
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setHeight(60),
                                              child: Center(
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                              (_nameEmpty == true)
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          "Name can't be empty",
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: font12),
                                        )
                                      ],
                                    )
                                  : Row(),
                              SizedBox(
                                height: ScreenUtil().setHeight(30),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[Text("Company Name")],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Container(
                                height: ScreenUtil().setHeight(60),
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
                                      child: TextField(
                                        controller: _companycontroller,
                                        style: TextStyle(
                                          height: 1,
                                          fontSize: font14,
                                        ),
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: "eg. JTApps Sdn Bhd",
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.only(
                                              left: ScreenUtil().setHeight(10),
                                              bottom:
                                                  ScreenUtil().setHeight(20),
                                              top: ScreenUtil().setHeight(-15),
                                              right:
                                                  ScreenUtil().setHeight(20)),
                                        ),
                                      ),
                                    ),
                                    (isImageLoaded == true)
                                        ? InkWell(
                                            onTap: () {
                                              _showBottomSheet(
                                                  "_companycontroller");
                                            },
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setHeight(60),
                                              child: Center(
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(30),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[Text("VTag")],
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
                                            ScreenUtil().setHeight(10),
                                            0,
                                            0,
                                            0),
                                        child: (seletedVTag.length == 0)
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    "Please Select",
                                                    style: TextStyle(
                                                        fontSize: font14,
                                                        color: Colors
                                                            .grey.shade600),
                                                  )
                                                ],
                                              )
                                            : Wrap(
                                                direction: Axis.horizontal,
                                                alignment: WrapAlignment.start,
                                                children: _selectedVTag(),
                                              ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        FocusScope.of(context)
                                            .requestFocus(new FocusNode());
                                        vTagListWidget();
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
                              SizedBox(
                                height: ScreenUtil().setHeight(30),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[Text("Remark")],
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(5),
                              ),
                              Container(
                                height: ScreenUtil().setHeight(60),
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
                                      child: TextField(
                                        controller: _remarkcontroller,
                                        style: TextStyle(
                                          height: 1,
                                          fontSize: font14,
                                        ),
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: "eg. from KLCC exhibition",
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.only(
                                              left: ScreenUtil().setHeight(10),
                                              bottom:
                                                  ScreenUtil().setHeight(20),
                                              top: ScreenUtil().setHeight(-15),
                                              right:
                                                  ScreenUtil().setHeight(20)),
                                        ),
                                      ),
                                    ),
                                    (isImageLoaded == true)
                                        ? InkWell(
                                            onTap: () {
                                              _showBottomSheet(
                                                  "_remarkcontroller");
                                            },
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setHeight(60),
                                              child: Center(
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container()
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: ScreenUtil().setHeight(50),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  BouncingWidget(
                                    scaleFactor: _scaleFactor,
                                    onPressed: _checking,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      height: ScreenUtil().setHeight(80),
                                      margin: EdgeInsets.fromLTRB(
                                          0,
                                          ScreenUtil().setHeight(10),
                                          ScreenUtil().setHeight(10),
                                          ScreenUtil().setHeight(10)),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        color: (isSend == false)
                                            ? Colors.blue
                                            : Colors.grey,
                                        border: Border(
                                          top: BorderSide(
                                              width: 1, color: Colors.grey),
                                          right: BorderSide(
                                              width: 1, color: Colors.grey),
                                          bottom: BorderSide(
                                              width: 1, color: Colors.grey),
                                          left: BorderSide(
                                              width: 1, color: Colors.grey),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Send',
                                          style: TextStyle(
                                            fontSize: font14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }

  void radioList() {
    RadioItem widget;
    radioItems.clear();
    for (var contact in contactList) {
      widget = RadioItem(
        padding: EdgeInsets.only(
          left: ScreenUtil().setHeight(12),
        ),
        text: contact.name ?? '' + ' (' + contact.phone ?? '' + ')',
        color: Colors.black,
        fontSize: font14,
      );
      radioItems.add(widget);
    }
    try {
      selectedName = contactList[0].name;
      selectedPhone = contactList[0].phone;
    } catch (e) {}
    YYListViewDialogListRadio();
  }

  YYDialog YYListViewDialogListRadio() {
    return YYDialog().build()
      ..width = MediaQuery.of(context).size.width * 0.85
      ..borderRadius = ScreenUtil().setHeight(8)
      ..text(
        padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
        alignment: Alignment.center,
        text: "Select Contact",
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
                controller: _searchController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.go,
                onSubmitted: (value) => _search(value),
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
      )
      ..listViewOfRadioButton(
          height: ScreenUtil().setHeight(1000),
          items: radioItems,
          intialValue: 0,
          color: Colors.white,
          activeColor: Colors.blue,
          onClickItemListener: (index) {
            selectedName = contactList[index].name;
            selectedPhone = contactList[index].phone;
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
            _searchController.text = '';
          },
          text2: "OK",
          color2: Colors.blue,
          fontSize2: font14,
          fontWeight2: FontWeight.bold,
          onTap2: () {
            if (this.mounted) {
              setState(() {
                _namecontroller.text = selectedName;
                _phonecontroller.text = selectedPhone;
                _searchController.text = '';
              });
            }
          })
      ..show();
  }

  void vTagListWidget() {
    RadioItem widget;
    vTagItems.clear();
    for (var vtag in vTagList) {
      widget = RadioItem(
        padding: EdgeInsets.only(
          left: ScreenUtil().setHeight(12),
        ),
        text: vtag,
        color: Colors.black,
        fontSize: font14,
      );
      vTagItems.add(widget);
    }
    try {
      selectedVTag = vTagList[0];
    } catch (e) {}
    YYListViewDialogListRadio1();
  }

  YYDialog YYListViewDialogListRadio1() {
    return YYDialog().build()
      ..width = MediaQuery.of(context).size.width * 0.85
      ..borderRadius = ScreenUtil().setHeight(8)
      ..text(
        padding: EdgeInsets.all(ScreenUtil().setHeight(20)),
        alignment: Alignment.center,
        text: "Select VTag",
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
                controller: _searchVTagController,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.go,
                onSubmitted: (value) => _searchVTag(value),
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
                      _searchVTag(_searchVTagController.text);
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
          items: vTagItems,
          intialValue: 0,
          color: Colors.white,
          activeColor: Colors.blue,
          onClickItemListener: (index) {
            selectedVTag = vTagList[index];
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
            _searchVTagController.text = '';
          },
          text2: "OK",
          color2: Colors.blue,
          fontSize2: font14,
          fontWeight2: FontWeight.bold,
          onTap2: () {
            bool add = true;
            for (var item in seletedVTag) {
              if (item == selectedVTag) {
                add = false;
              }
            }
            if (add == true && this.mounted) {
              setState(() {
                seletedVTag.add(selectedVTag);
                vTagList = widget.whatsappForward.vtagList;
              });
            }
            _searchVTagController.text = '';
          })
      ..show();
  }

  void _searchVTag(String value) {
    FocusScope.of(context).requestFocus(new FocusNode());
    Navigator.pop(context);
    List list = [];
    if (value != '') {
      for (var tag in vTagList) {
        if (tag.toLowerCase().contains(value.toLowerCase())) {
          list.add(tag);
        }
      }
      vTagList = list;
    } else {
      vTagList = widget.whatsappForward.vtagList;
      if (vTagList[0] == '-') {
        vTagList.removeAt(0);
      }
    }
    vTagListWidget();
  }

  Future<void> _search(String value) async {
    FocusScope.of(context).requestFocus(new FocusNode());
    Navigator.pop(context);
    contactList.clear();
    for (int i = 0; i < contactList1.length; i++) {
      if (contactList1[i].name.toLowerCase().contains(value.toLowerCase()) ||
          contactList1[i].phone.contains(value)) {
        ContactInfo info = ContactInfo(
          name: contactList1[i].name,
          phone: contactList1[i].phone,
        );
        contactList.add(info);
      }
    }
    radioList();
  }

  List<Widget> _selectedVTag() {
    List widgetList = <Widget>[];
    for (int i = 0; i < seletedVTag.length; i++) {
      Widget widget1 = InkWell(
        onTap: () {
          if (this.mounted) {
            setState(() {
              seletedVTag.removeAt(i);
            });
          }
        },
        child: Container(
          width: ScreenUtil().setWidth((seletedVTag[i].length * 16.8) + 62.8),
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
                seletedVTag[i],
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
      );
      widgetList.add(widget1);
    }
    return widgetList;
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

  void _checking() {
    bool send = true;
    if (this.mounted) {
      setState(() {
        if (_phonecontroller.text.isEmpty) {
          _phoneEmpty = true;
          send = false;
        } else {
          _phoneEmpty = false;
        }
      });
    }
    if (this.mounted) {
      setState(() {
        if (_namecontroller.text.isEmpty) {
          _nameEmpty = true;
          send = false;
        } else {
          _nameEmpty = false;
        }
      });
    }
    if (_phoneEmpty == false) {
      bool _isNumeric(String phoneNo) {
        if (phoneNo.length < 10) {
          return false;
        }
        return num.tryParse(phoneNo) != null;
      }

      bool valid = _isNumeric(_phonecontroller.text);
      if (valid == false) {
        if (this.mounted) {
          setState(() {
            _phoneInvalid = true;
          });
        }
      } else {
        if (this.mounted) {
          setState(() {
            _phoneInvalid = false;
          });
        }
      }

      if (valid == true && send == true) {
        String vtag;
        if (seletedVTag.length == 0) {
          vtag = "";
        } else {
          for (int i = 0; i < seletedVTag.length; i++) {
            if (i == 0) {
              vtag = seletedVTag[i];
            } else {
              vtag = vtag + "," + seletedVTag[i];
            }
          }
        }
        _send(vtag);
      }
    }
  }

  void _onLoading1() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: null,
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
                  JumpingText('Sending...'),
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

  void _send(String vtag) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      _onLoading1();
      if (isSend == false) {
        if (this.mounted) {
          setState(() {
            isSend = true;
          });
        }
        String full = "";
        if (otherList.length != 0) {
          for (int i = 1; i < otherList.length; i++) {
            if (i != otherList.length - 1) {
              full = full + otherList[i] + "~!";
            } else {
              full = full + otherList[i];
            }
          }
        }
        if (_phonecontroller.text.substring(0, 1) == "0") {
          _phonecontroller.text = "6" + _phonecontroller.text;
        }
        http.post(urlWhatsApp, body: {
          "companyID": widget.whatsappForward.companyID,
          "branchID": widget.whatsappForward.branchID,
          "userID": widget.whatsappForward.userID,
          "user_type": widget.whatsappForward.userType,
          "level": widget.whatsappForward.level,
          "phoneNo": _phonecontroller.text,
          "name": _namecontroller.text,
          "companyName": _companycontroller.text,
          "remark": _remarkcontroller.text,
          "vtag": vtag,
          "url": widget.whatsappForward.url,
          "nameCard": "",
          "number": widget.whatsappForward.userID + "_" + number,
          "system": platform,
          "details": full,
        }).then((res) async {
          Navigator.pop(context);
          if (platform == 'android') {
            FlutterOpenWhatsapp.sendSingleMessage(
                _phonecontroller.text,
                "Hello " +
                    _namecontroller.text +
                    "! Reply 'hi' to enable the URL link. " +
                    widget.whatsappForward.url +
                    res.body);
          } else {
            launch(res.body);
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VData(),
            ),
          );
        }).catchError((err) {
          print("WhatsApp Forward error: " + err.toString());
        });
      }
    } else {
      _toast("No Internet Connection");
    }
  }

  void _showBottomSheet(String type) {
    if (type == "phone") {
      int position;
      for (int i = 0; i < phoneList.length; i++) {
        if (_phonecontroller.text == phoneList[i]) {
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
                              Navigator.pop(context);
                              if (this.mounted) {
                                setState(() {
                                  _phonecontroller.text = phoneList[position];
                                });
                              }
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
                            FixedExtentScrollController(initialItem: position),
                        onSelectedItemChanged: (int index) {
                          if (position != index) {
                            if (this.mounted) {
                              setState(() {
                                position = index;
                              });
                            }
                          }
                        },
                        children: _phoneList(),
                      ),
                    ))
                  ],
                ),
              );
            },
          );
        },
      );
    } else {
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
                              if (tempText != "-") {
                                Navigator.pop(context);
                                if (this.mounted) {
                                  setState(() {
                                    _checkTextField(type).text =
                                        _checkTextField(type).text +
                                            " " +
                                            tempText;
                                    tempText = "";
                                  });
                                }
                              } else {
                                Navigator.pop(context);
                              }
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
                          tempText = otherList[index];
                        },
                        children: _otherList(),
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
  }

  List<Widget> _phoneList() {
    List widgetList = <Widget>[];
    for (var each in phoneList) {
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

  List<Widget> _otherList() {
    List widgetList = <Widget>[];
    for (var each in otherList) {
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

  TextEditingController _checkTextField(String textfield) {
    TextEditingController controller;
    switch (textfield) {
      case "_namecontroller":
        controller = _namecontroller;
        break;
      case "_companycontroller":
        controller = _companycontroller;
        break;
      case "_remarkcontroller":
        controller = _remarkcontroller;
        break;
    }
    return controller;
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
                  requestPermission();
                },
                child: Text(
                  "Choose from contact book",
                  style: TextStyle(
                    fontSize: font18,
                  ),
                ),
              ),
              (gotGoogle == false)
                  ? null
                  : CupertinoActionSheetAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        var tempStore = await ImagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (tempStore != null) {
                          if (this.mounted) {
                            setState(() {
                              pickedImage = tempStore;
                              isImageLoaded = true;
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
              (gotGoogle == false)
                  ? null
                  : CupertinoActionSheetAction(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        var tempStore = await ImagePicker.pickImage(
                            source: ImageSource.camera);
                        if (tempStore != null) {
                          if (this.mounted) {
                            setState(() {
                              pickedImage = tempStore;
                              isImageLoaded = true;
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

  Future requestPermission() async {
    var status =
        await PermissionHandler().requestPermissions([pageState.list[0].group]);
    if (status.toString() ==
        "{PermissionGroup.contacts: PermissionStatus.granted}") {
      getContact();
    }
  }

  Future<void> getContact() async {
    var contacts =
        (await ContactsService.getContacts(withThumbnails: false)).toList();
    contactList.clear();
    contactList1.clear();
    for (var contact in contacts) {
      try {
        RegExp patternNum = new RegExp(r'[0-9]');
        for (int i = 0; i < contact.phones.length; i++) {
          String phone = contact.phones.elementAt(i).value;
          String phoneNo = '';
          bool add = true;
          for (int j = 0; j < phone.length; j++) {
            if (j != 0) {
              if (patternNum.hasMatch(phone[j])) {
                phoneNo += phone[j];
              }
            } else {
              if (patternNum.hasMatch(phone[j])) {
                phoneNo = '6' + phone[j];
              }
            }
          }
          for (var list in contactList) {
            if (phoneNo == list.phone) {
              add = false;
              break;
            }
          }
          if (add == true) {
            ContactInfo info = ContactInfo(
              name: contact.displayName,
              phone: phoneNo,
            );
            contactList.add(info);
            contactList1.add(info);
          }
        }
      } catch (e) {}
    }
    radioList();
  }

  Future readText() async {
    pickedImage = await FlutterNativeImage.compressImage(pickedImage.path,
        quality: 40, percentage: 30);
    base64Image = base64Encode(pickedImage.readAsBytesSync());
    number = DateTime.now().millisecondsSinceEpoch.toString();
    http
        .post(urlWhatsApp, body: {
          "companyID": widget.whatsappForward.companyID,
          "branchID": widget.whatsappForward.branchID,
          "userID": widget.whatsappForward.userID,
          "user_type": widget.whatsappForward.userType,
          "level": widget.whatsappForward.level,
          "phoneNo": "",
          "name": "",
          "companyName": "",
          "remark": "",
          "vtag": "",
          "number": widget.whatsappForward.userID + "_" + number,
          "url": widget.whatsappForward.url,
          "nameCard": base64Image,
          "system": platform,
          "details": '',
        })
        .then((res) {})
        .catchError((err) {
          print("WhatsApp Forward Save Image error: " + (err).toString());
        });
    otherList.add("-");
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);

    RegExp patternNum = new RegExp(r'[0-9]');
    RegExp patternAlpa = new RegExp(r'[a-z]');
    RegExp patternBigAlpa = new RegExp(r'[A-Z]');
    for (TextBlock block in readText.blocks) {
      for (TextLine line in block.lines) {
        String temPhone = "";
        String number = '';
        int startIndex = 0;
        int endIndex = 0;
        bool save = true;
        for (int i = 0; i < line.text.length; i++) {
          if (patternNum.hasMatch(line.text[i]) ||
              patternAlpa.hasMatch(line.text[i]) ||
              patternBigAlpa.hasMatch(line.text[i])) {
            if (patternNum.hasMatch(line.text[i])) {
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
          }
          if (temPhone.length > 9 && number == 'string') {
            if (temPhone.substring(0, 1).toString() == "0") {
              phoneList.add("6" + temPhone);
            } else {
              phoneList.add(temPhone);
            }
            String text =
                line.text.substring(startIndex, endIndex - temPhone.length - 2);
            otherList.add(text);
            temPhone = '';
            number = '';
            startIndex = endIndex;
            endIndex = 0;
          } else if (temPhone.length > 9 && i == line.text.length - 1) {
            if (temPhone.substring(0, 1).toString() != "6") {
              phoneList.add("6" + temPhone);
            } else {
              phoneList.add(temPhone);
            }
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
    if (this.mounted) {
      setState(() {
        isImageLoaded = true;
        _phonecontroller.text = phoneList[0];
      });
    }
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.of(context).pop();
    return Future.value(false);
  }
}
