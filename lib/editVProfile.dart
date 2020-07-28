import 'dart:async';
import 'dart:convert';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:ndialog/ndialog.dart';
import 'package:geocoder/geocoder.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/VProfile.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/data.dart';
import 'package:vvin/reminder.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminderDB.dart';

final ScrollController controller = ScrollController();
final TextEditingController _nameController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _companyController = TextEditingController();
final TextEditingController _icController = TextEditingController();
final TextEditingController _positionController = TextEditingController();
final TextEditingController _occupationController = TextEditingController();
final TextEditingController _areaController = TextEditingController();

class EditVProfile extends StatefulWidget {
  final VProfileData vprofileData;
  final List handler;
  final List vtag;
  final VDataDetails vdata;
  final String details;
  const EditVProfile(
      {Key key,
      this.vprofileData,
      this.handler,
      this.vdata,
      this.vtag,
      this.details})
      : super(key: key);

  @override
  _EditVProfileState createState() => _EditVProfileState();
}

enum UniLinksType { string, uri }

class _EditVProfileState extends State<EditVProfile> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  double _scaleFactor = 1.0;
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  String urlDetails = ip + "cardDetails.php";
  String urlHandler = ip + "getHandler.php";
  String urlVTag = ip + "vtag.php";
  String urlSaveEditVProfile = ip + "saveEditVProfile.php";
  String urlSaveHandler = ip + "saveHandler.php";
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  int genderIndex, industryIndex, countryIndex, handlerIndex;
  String handler,
      email,
      companyID,
      branchID,
      userID,
      level,
      userType,
      selectedTag,
      now,
      details;
  bool saveHandler, saveData, allHandler, allTag, nameCard, gotData;
  List<Gender> genderList = [];
  List<Handler> handlerList = [];
  List<Handler> handlerList1 = [];
  List<Industry> industryList = [];
  List<Country> countryList = [];
  List<States> statesList = [];
  List vtagList = [];
  List<String> otherList = [];
  List tags = <Widget>[];
  List texts = <Widget>[];

  List<String> industry = [
    "-",
    "Architecture",
    "Banking & Finance",
    "Construction",
    "Construction Service",
    "Creative",
    "Dealer",
    "Distributor",
    "Education",
    "Fashion",
    "Food & Beverages",
    "Health Care",
    "Hospitality",
    "Information Technology",
    "Interior Design",
    "Manufacturing",
    "Media",
    "Non-Profit Organisation",
    "Property & Real Estate",
    "Public Service",
    "Retail",
    "Telecommunication",
    "Transportation & Logistics",
    "Others"
  ];

  List<String> gender = ["-", "Female", "Male", "Other"];

  List<String> country = [
    "-",
    "Malaysia",
    "Afghanistan",
    "Albania",
    "Algeria",
    "American Samoa",
    "Andorra",
    "Angola",
    "Anguilla",
    "Antarctica",
    "Antigua and/or Barbuda",
    "Argentina",
    "Armenia",
    "Aruba",
    "Australia",
    "Austria",
    "Azerbaijian",
    "Bahamas",
    "Bahrain",
    "Bangladesh",
    "Barbados",
    "Belarus",
    "Belgium",
    "Belize",
    "Benin",
    "Bermuda",
    "Bhutan",
    "Bolivia",
    "Bosnia and Herzegovina",
    "Botswana",
    "Bouvet Island",
    "Brazil",
    "British lndian Ocean Territory",
    "Brunei Darussalam",
    "Bulgaria",
    "Burkina Faso",
    "Burundi",
    "Cambodia",
    "Cameroon",
    "Canada",
    "Cape Verde",
    "Cayman Islands",
    "Central African Republic",
    "Chad",
    "Chile",
    "China",
    "Christmas Island",
    "Cocos (Keeling) Islands",
    "Colombia",
    "Comoros",
    "Congo",
    "Cook Islands",
    "Costa Rica",
    "Croatia (Hrvatska)",
    "Cuba",
    "Cyprus",
    "Czech Republic",
    "Denmark",
    "Djibouti",
    "Dominica",
    "Dominican Republic",
    "East Timor",
    "Ecudaor",
    "Egypt",
    "El Salvador",
    "Equatorial Guinea",
    "Eritrea",
    "Estonia",
    "Ethiopia",
    "Falkland Islands (Malvinas)",
    "Faroe Islands",
    "Fiji",
    "Finland",
    "France",
    "France, Metropolitan",
    "French Guiana",
    "French Polynesia",
    "French Southern Territories",
    "Gabon",
    "Gambia",
    "Georgia",
    "Germany",
    "Ghana",
    "Gibraltar",
    "Greece",
    "Greenland",
    "Grenada",
    "Guadeloupe",
    "Guam",
    "Guatemala",
    "Guinea",
    "Guinea-Bissau",
    "Guyana",
    "Haiti",
    "Heard and Mc Donald Islands",
    "Honduras",
    "Hong Kong",
    "Hungary",
    "Iceland",
    "India",
    "Indonesia",
    "Iran (Islamic Republic of)",
    "Iraq",
    "Ireland",
    "Israel",
    "Italy",
    "Ivory Coast",
    "Jamaica",
    "Japan",
    "Jordan",
    "Kazakhstan",
    "Kenya",
    "Kiribati",
    "Korea, Democratic Republic of (North Korea)",
    "Korea, Republic of (South Korea)",
    "Kuwait",
    "Kyrgyzstan",
    "Laos",
    "Latvia",
    "Lebanon",
    "Lesotho",
    "Liberia",
    "Libyan Arab Jamahiriya",
    "Liechtenstein",
    "Lithuania",
    "Luxembourg",
    "Macau",
    "Macedonia",
    "Madagascar",
    "Malawi",
    "Maldives",
    "Mali",
    "Malta",
    "Marshall Islands",
    "Martinique",
    "Mauritania",
    "Mauritius",
    "Mayotte",
    "Mexico",
    "Micronesia, Federated States of",
    "Moldova, Republic of",
    "Monaco",
    "Mongolia",
    "Montserrat",
    "Morocco",
    "Mozambique",
    "Myanmar",
    "Namibia",
    "Nauru",
    "Nepal",
    "Netherlands",
    "Netherlands Antilles",
    "New Caledonia",
    "New Zealand",
    "Nicaragua",
    "Niger",
    "Nigeria",
    "Niue",
    "Norfork Island",
    "Northern Mariana Islands",
    "Norway",
    "Oman",
    "Pakistan",
    "Palau",
    "Panama",
    "Papua New Guinea",
    "Paraguay",
    "Peru",
    "Philippines",
    "Pitcairn",
    "Poland",
    "Portugal",
    "Puerto Rico",
    "Qatar",
    "Reunion",
    "Romania",
    "Russian Federation",
    "Rwanda",
    "Saint Kitts and Nevis",
    "Saint Lucia",
    "Saint Vincent and the Grenadines",
    "Samoa",
    "San Marino",
    "Sao Tome and Principe",
    "Saudi Arabia",
    "Senegal",
    "Seychelles",
    "Sierra Leone",
    "Singapore",
    "Slovakia",
    "Slovenia",
    "Solomon Islands",
    "Somalia",
    "South Africa",
    "South Georgia South Sandwich Islands",
    "Spain",
    "Sri Lanka",
    "St. Helena",
    "St. Pierre and Miquelon",
    "Sudan",
    "Suriname",
    "Svalbarn and Jan Mayen Islands",
    "Swaziland",
    "Sweden",
    "Switzerland",
    "Syrian Arab Republic",
    "Taiwan",
    "Tajikistan",
    "Tanzania, United Republic of",
    "Thailand",
    "Togo",
    "Tokelau",
    "Tonga",
    "Trinidad and Tobago",
    "Tunisia",
    "Turkey",
    "Turkmenistan",
    "Turks and Caicos Islands",
    "Tuvalu",
    "Uganda",
    "Ukraine",
    "United Arab Emirates",
    "United Kingdom",
    "United States",
    "United States minor outlying islands",
    "Uruguay",
    "Uzbekistan",
    "Vanuatu",
    "Vatican City State",
    "Venezuela",
    "Vietnam",
    "Virgin Islands (U.S.)",
    "Virigan Islands (British)",
    "Wallis and Futuna Islands",
    "Western Sahara",
    "Yemen",
    "Yugoslavia",
    "Zaire",
    "Zambia",
    "Zimbabwe",
  ];

  List<String> states = [
    "-",
    "Johor",
    "Kedah",
    "Kelantan",
    "Melaka",
    "Negeri Sembilan",
    "Pahang",
    "Perak",
    "Perlis",
    "Pulau Pinang",
    "Sabah",
    "Sarawak",
    "Selangor",
    "Terengganu",
    "WP Kuala Lumpur",
    "WP Labuan",
    "WP Putrajaya"
  ];

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.white,
    ));
    check();
    _init();
    _nameController.text = widget.vprofileData.name;
    _emailController.text = widget.vprofileData.email;
    _companyController.text = widget.vprofileData.company;
    _icController.text = widget.vprofileData.ic;
    _positionController.text = widget.vprofileData.position;
    _occupationController.text = widget.vprofileData.occupation;
    _areaController.text = widget.vprofileData.area;
    handlerIndex = 0;
    handler = selectedTag = "";
    saveData = saveHandler = allHandler = allTag = nameCard = gotData = false;
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

  @override
  void dispose() {
    if (_sub != null) _sub.cancel();
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
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
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
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
              "Edit VProfile",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                ScreenUtil().setHeight(10),
                0,
                ScreenUtil().setHeight(10),
                ScreenUtil().setHeight(10),
              ),
              child: Center(
                child: SizedBox(
                  height: ScreenUtil().setHeight(60),
                  child: TextField(
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: font18,
                      height: 1,
                    ),
                    textAlign: TextAlign.center,
                    controller: _nameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.all(ScreenUtil().setHeight(10)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: ScrollPhysics(),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    ScreenUtil().setHeight(40),
                    ScreenUtil().setHeight(20),
                    ScreenUtil().setHeight(40),
                    ScreenUtil().setHeight(40),
                  ),
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          (widget.handler.length > 0)
                              ? Text(
                                  "Handler",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: font14,
                                  ),
                                )
                              : (widget.vdata.level == "0" ||
                                      widget.vdata.level == "4")
                                  ? Text(
                                      "Handler",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: font14,
                                      ),
                                    )
                                  : Container(),
                        ],
                      ),
                      SizedBox(
                        height: ScreenUtil().setHeight(4),
                      ),
                      (widget.vdata.level == "0" || widget.vdata.level == "4")
                          ? (widget.handler.length > 0)
                              ? Container(
                                  height: (widget.handler.length *
                                      ScreenUtil().setHeight(80)),
                                  child: ListView.builder(
                                      itemCount: widget.handler.length,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Container(
                                          margin: EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            0,
                                            ScreenUtil().setHeight(20),
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.fromLTRB(
                                                      ScreenUtil()
                                                          .setHeight(10),
                                                      0,
                                                      0,
                                                      0),
                                                  height: ScreenUtil()
                                                      .setHeight(60),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        style:
                                                            BorderStyle.solid),
                                                  ),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Flexible(
                                                        child: Text(
                                                          widget.handler[index],
                                                          style: TextStyle(
                                                            fontSize: font14,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width:
                                                    ScreenUtil().setWidth(20),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  _deleteHandler(index);
                                                },
                                                child: Container(
                                                  height: ScreenUtil()
                                                      .setHeight(60),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade500,
                                                        style:
                                                            BorderStyle.solid),
                                                  ),
                                                  child: Icon(
                                                    Icons.remove,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                )
                              : Container()
                          : (widget.handler.length > 0)
                              ? Container(
                                  height: (widget.handler.length *
                                      ScreenUtil().setHeight(80)),
                                  child: ListView.builder(
                                      itemCount: widget.handler.length,
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        return Container(
                                          margin: EdgeInsets.fromLTRB(
                                            0,
                                            0,
                                            0,
                                            ScreenUtil().setHeight(20),
                                          ),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Container(
                                                  height: ScreenUtil()
                                                      .setHeight(60),
                                                  padding: EdgeInsets.fromLTRB(
                                                      ScreenUtil()
                                                          .setHeight(10),
                                                      0,
                                                      0,
                                                      0),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    border: Border.all(
                                                        color: Colors.grey,
                                                        style:
                                                            BorderStyle.solid),
                                                  ),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Flexible(
                                                        child: Text(
                                                          widget.handler[index],
                                                          style: TextStyle(
                                                            fontSize: font14,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                )
                              : Container(),
                      (widget.vdata.level == "0" || widget.vdata.level == "4")
                          ? Row(
                              children: <Widget>[
                                Expanded(
                                  child: Container(
                                    height: 30,
                                    margin: EdgeInsets.fromLTRB(
                                      0,
                                      0,
                                      0,
                                      ScreenUtil().setHeight(20),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: Colors.grey.shade400,
                                          style: BorderStyle.solid),
                                    ),
                                    child: InkWell(
                                      child: OutlineButton.icon(
                                        color: Colors.white,
                                        label: Text(
                                          'Add Handler',
                                          style: TextStyle(
                                              fontSize: font14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: _addHandler,
                                        textColor: Colors.blue,
                                        icon: Icon(
                                          Icons.add,
                                          size: ScreenUtil().setHeight(40),
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Email",
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
                                style: TextStyle(
                                  fontSize: font14,
                                ),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
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
                            (gotData == true)
                                ? InkWell(
                                    onTap: () {
                                      _showBottomSheet("email");
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
                                : Container()
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ScreenUtil().setHeight(20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Company",
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
                                style: TextStyle(
                                  height: 1,
                                  fontSize: font14,
                                ),
                                controller: _companyController,
                                // onSubmitted: (String inputText) {
                                //   checkAddress();
                                // },
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  // suffix: IconButton(
                                  //     onPressed: () {
                                  //       checkAddress();
                                  //     },
                                  //     icon: Icon(
                                  //         MaterialCommunityIcons.map_search,
                                  //         color: Colors.blue)),
                                  contentPadding: EdgeInsets.only(
                                      left: ScreenUtil().setHeight(10),
                                      bottom: ScreenUtil().setHeight(20),
                                      top: ScreenUtil().setHeight(-15),
                                      right: ScreenUtil().setHeight(20)),
                                ),
                              ),
                            ),
                            (gotData == true)
                                ? InkWell(
                                    onTap: () {
                                      _showBottomSheet("company");
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
                                : Container()
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ScreenUtil().setHeight(20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "IC/Passport Number",
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
                                style: TextStyle(
                                  height: 1,
                                  fontSize: font14,
                                ),
                                controller: _icController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
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
                      SizedBox(
                        height: ScreenUtil().setHeight(20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Date of Birth",
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
                              onTap: _dobBottomSheet,
                              child: Container(
                                margin: EdgeInsets.fromLTRB(
                                  0,
                                  0,
                                  0,
                                  ScreenUtil().setHeight(20),
                                ),
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
                                          widget.vprofileData.dob,
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
                        height: ScreenUtil().setHeight(10),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Gender",
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
                                _showBottomSheet("gender");
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
                                          widget.vprofileData.gender,
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
                                      width: ScreenUtil().setHeight(10),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Position",
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
                                style: TextStyle(
                                  height: 1,
                                  fontSize: font14,
                                ),
                                controller: _positionController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                      left: ScreenUtil().setHeight(10),
                                      bottom: ScreenUtil().setHeight(20),
                                      top: ScreenUtil().setHeight(-15),
                                      right: ScreenUtil().setHeight(20)),
                                ),
                              ),
                            ),
                            (gotData == true)
                                ? InkWell(
                                    onTap: () {
                                      _showBottomSheet("position");
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
                                : Container()
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ScreenUtil().setHeight(20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Industry",
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
                                _showBottomSheet("industry");
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
                                          widget.vprofileData.industry,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Occupation",
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
                                style: TextStyle(
                                  height: 1,
                                  fontSize: font14,
                                ),
                                controller: _occupationController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                      left: ScreenUtil().setHeight(10),
                                      bottom: ScreenUtil().setHeight(20),
                                      top: ScreenUtil().setHeight(-15),
                                      right: ScreenUtil().setHeight(20)),
                                ),
                              ),
                            ),
                            (gotData == true)
                                ? InkWell(
                                    onTap: () {
                                      _showBottomSheet("occupation");
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
                                : Container()
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ScreenUtil().setHeight(20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Country",
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
                                _showBottomSheet("country");
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
                                          widget.vprofileData.country,
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
                      (widget.vprofileData.country == "Malaysia")
                          ? Container(
                              child: Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "State",
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
                                            _showBottomSheet("state");
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
                                                  color: Colors.grey,
                                                  style: BorderStyle.solid),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Expanded(
                                                  child: Container(
                                                    height: ScreenUtil()
                                                        .setHeight(60),
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            ScreenUtil()
                                                                .setHeight(10),
                                                            ScreenUtil()
                                                                .setHeight(16),
                                                            0,
                                                            0),
                                                    child: Text(
                                                      widget.vprofileData.state,
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
                                                  width:
                                                      ScreenUtil().setWidth(10),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Area",
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
                                style: TextStyle(
                                  height: 1,
                                  fontSize: font14,
                                ),
                                controller: _areaController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.only(
                                      left: ScreenUtil().setHeight(10),
                                      bottom: ScreenUtil().setHeight(20),
                                      top: ScreenUtil().setHeight(-15),
                                      right: ScreenUtil().setHeight(20)),
                                ),
                              ),
                            ),
                            (gotData == true)
                                ? InkWell(
                                    onTap: () {
                                      _showBottomSheet("area");
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
                                : Container()
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ScreenUtil().setHeight(20),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Tags",
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
                                child: (widget.vtag.length == 0)
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            "",
                                            style: TextStyle(
                                                fontSize: font14,
                                                color: Colors.grey),
                                          )
                                        ],
                                      )
                                    : Wrap(
                                        direction: Axis.horizontal,
                                        alignment: WrapAlignment.start,
                                        children: _tags(widget.vtag.length),
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
                      SizedBox(
                        height: ScreenUtil().setHeight(40),
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
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _tags(int length) {
    tags.clear();
    for (int i = 0; i < length; i++) {
      Widget widget1 = InkWell(
        onTap: () {
          _deleteTag(i);
        },
        child: Container(
          width: ScreenUtil().setWidth((widget.vtag[i].length * 20) + 62.8),
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
                  fontSize: font14,
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
      tags.add(widget1);
    }
    return tags;
  }

  void _deleteTag(int index) {
    String vtag = widget.vtag[index];
    if (this.mounted) {
      setState(() {
        widget.vtag.removeAt(index);
        vtagList.insert(1, vtag);
      });
    }
  }

  void _selectHandler() {
    FocusScope.of(context).requestFocus(new FocusNode());
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
                            if (selectedTag != "") {
                              for (int j = 0; j < vtagList.length; j++) {
                                if (vtagList[j] == selectedTag) {
                                  vtagList.removeAt(j);
                                }
                              }
                              if (this.mounted) {
                                setState(() {
                                  widget.vtag.add(selectedTag);
                                  selectedTag = "";
                                });
                              }
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
                        if (index != 0) {
                          selectedTag = vtagList[index];
                        } else {
                          selectedTag = '';
                        }
                      },
                      children: _text('vtagList'),
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

  List<Widget> _text(String type) {
    List widgetList = <Widget>[];
    switch (type) {
      case 'vtagList':
        List list = vtagList;
        for (var each in list) {
          Widget widget1 = Text(
            each,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      case 'genderList':
        List<Gender> list = genderList;
        for (var each in list) {
          Widget widget1 = Text(
            each.gender,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      case 'industryList':
        List<Industry> list = industryList;
        for (var each in list) {
          Widget widget1 = Text(
            each.industry,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      case 'countryList':
        List<Country> list = countryList;
        for (var each in list) {
          Widget widget1 = Text(
            each.country,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      case 'statesList':
        List<States> list = statesList;
        for (var each in list) {
          Widget widget1 = Text(
            each.state,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      case 'handlerList':
        List<Handler> list = handlerList;
        for (var each in list) {
          Widget widget1 = Text(
            each.handler,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
        break;
      default:
        List list = otherList;
        for (var each in list) {
          Widget widget1 = Text(
            each,
            style: TextStyle(
              fontSize: font14,
            ),
          );
          widgetList.add(widget1);
        }
    }
    return widgetList;
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.pop(context, true);
    Navigator.pop(context, true);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VProfile(
            vdata: widget.vdata,
          ),
        ));
    return Future.value(false);
  }

  void _dobBottomSheet() {
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
                          padding: EdgeInsets.all(10),
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
                            padding: EdgeInsets.all(10),
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
                          },
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      color: Colors.white,
                      child: CupertinoDatePicker(
                        maximumDate: DateTime.now(),
                        mode: CupertinoDatePickerMode.date,
                        backgroundColor: Colors.transparent,
                        initialDateTime: (widget.vprofileData.dob == "")
                            ? DateTime.parse("1970-01-01")
                            : DateTime.parse(widget.vprofileData.dob),
                        onDateTimeChanged: (dob) {
                          if (this.mounted) {
                            setState(() {
                              widget.vprofileData.dob =
                                  dob.toString().substring(0, 10);
                            });
                          }
                        },
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
  }

  void _addHandler() {
    FocusScope.of(context).requestFocus(new FocusNode());
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
                            if (handlerIndex != 0) {
                              Navigator.pop(context);
                              if (this.mounted) {
                                setState(() {
                                  widget.handler.add(handler);
                                  handlerList.removeAt(handlerIndex);
                                  handlerIndex = 0;
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
                          if (this.mounted) {
                            setState(() {
                              handlerIndex = index;
                              handler = handlerList[index].handler;
                            });
                          }
                        },
                        children: _text('handlerList'),
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
  }

  void checkAddress() async {
    try {
      final query = _companyController.text;
      var addresses = await Geocoder.local.findAddressesFromQuery(query);
      var first = addresses.first;
      List latlongList = first.coordinates.toString().split(",");
      String latatitude = latlongList[0].toString().substring(1);
      String longtitude =
          latlongList[1].toString().substring(0, latlongList[1].length - 1);

      final coordinates =
          Coordinates(double.parse(latatitude), double.parse(longtitude));
      addresses =
          await Geocoder.local.findAddressesFromCoordinates(coordinates);
      first = addresses.first;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => NDialog(
          dialogStyle: DialogStyle(titleDivider: true),
          title: Text(
            "Do you want use this in area field?",
            style: TextStyle(color: Colors.blue, fontSize: 16),
          ),
          content: Text(first.addressLine, style: TextStyle(fontSize: 14)),
          actions: <Widget>[
            FlatButton(
                child: Text("Yes"),
                onPressed: () {
                  _areaController.text = first.addressLine;
                  Navigator.pop(context);
                }),
            FlatButton(
                child: Text("No"), onPressed: () => Navigator.pop(context)),
          ],
        ),
      );
    } catch (err) {
      _toast("No result");
    }
  }

  void _showBottomSheet(String type) {
    FocusScope.of(context).requestFocus(new FocusNode());
    switch (type) {
      case "gender":
        {
          int position;
          if (widget.vprofileData.gender == "") {
            position = 0;
          } else {
            for (int i = 0; i < genderList.length; i++) {
              if (widget.vprofileData.gender == genderList[i].gender) {
                position = genderList[i].position;
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
                                  Navigator.pop(context);
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
                                  widget.vprofileData.gender =
                                      genderList[index].gender;
                                });
                              }
                            },
                            children: _text("genderList"),
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
        break;
      case "industry":
        {
          int position;
          if (widget.vprofileData.industry == "") {
            position = 0;
          } else {
            for (int i = 0; i < industryList.length; i++) {
              if (widget.vprofileData.industry == industryList[i].industry) {
                position = industryList[i].position;
              }
            }
          }
          if (position == null) {
            position = 0;
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
                                  Navigator.pop(context);
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
                                  widget.vprofileData.industry =
                                      industryList[index].industry;
                                });
                              }
                            },
                            children: _text('industryList'),
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
        break;
      case "country":
        {
          int position;
          if (widget.vprofileData.country == "") {
            position = 0;
          } else {
            for (int i = 0; i < countryList.length; i++) {
              if (widget.vprofileData.country == countryList[i].country) {
                position = countryList[i].position;
              }
            }
          }
          if (position == null) {
            position = 0;
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
                                  Navigator.pop(context);
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
                                  widget.vprofileData.country =
                                      countryList[index].country;
                                });
                              }
                            },
                            children: _text('countryList'),
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
        break;
      case "state":
        {
          int position;
          if (widget.vprofileData.state == "") {
            position = 0;
          } else {
            for (int i = 0; i < statesList.length; i++) {
              if (widget.vprofileData.state == statesList[i].state) {
                position = statesList[i].position;
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
                                  Navigator.pop(context);
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
                                  widget.vprofileData.state =
                                      statesList[index].state;
                                });
                              }
                            },
                            children: _text('statesList'),
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
        break;
      case "email":
        {
          int position = 0;
          for (int i = 0; i < otherList.length; i++) {
            if (_emailController.text == otherList[i]) {
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
                                  Navigator.pop(context);
                                  if (position != 0) {
                                    if (this.mounted) {
                                      setState(() {
                                        _emailController.text =
                                            otherList[position];
                                      });
                                    }
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
                            scrollController: FixedExtentScrollController(
                                initialItem: position),
                            onSelectedItemChanged: (int index) {
                              if (position != index) {
                                if (this.mounted) {
                                  setState(() {
                                    position = index;
                                  });
                                }
                              }
                            },
                            children: _text('otherList'),
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
        break;
      case "company":
        {
          int position = 0;
          for (int i = 0; i < otherList.length; i++) {
            if (_companyController.text == otherList[i]) {
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
                                  Navigator.pop(context);
                                  if (position != 0) {
                                    if (this.mounted) {
                                      setState(() {
                                        _companyController.text =
                                            otherList[position];
                                      });
                                    }
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
                            scrollController: FixedExtentScrollController(
                                initialItem: position),
                            onSelectedItemChanged: (int index) {
                              if (position != index) {
                                if (this.mounted) {
                                  setState(() {
                                    position = index;
                                  });
                                }
                              }
                            },
                            children: _text('otherList'),
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
        break;
      case "position":
        {
          int position = 0;
          for (int i = 0; i < otherList.length; i++) {
            if (_positionController.text == otherList[i]) {
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
                                  Navigator.pop(context);
                                  if (position != 0) {
                                    if (this.mounted) {
                                      setState(() {
                                        _positionController.text =
                                            otherList[position];
                                      });
                                    }
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
                            scrollController: FixedExtentScrollController(
                                initialItem: position),
                            onSelectedItemChanged: (int index) {
                              if (position != index) {
                                if (this.mounted) {
                                  setState(() {
                                    position = index;
                                  });
                                }
                              }
                            },
                            children: _text('otherList'),
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
        break;
      case "occupation":
        {
          int position = 0;
          for (int i = 0; i < otherList.length; i++) {
            if (_occupationController.text == otherList[i]) {
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
                                  Navigator.pop(context);
                                  if (position != 0) {
                                    if (this.mounted) {
                                      setState(() {
                                        _occupationController.text =
                                            otherList[position];
                                      });
                                    }
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
                            scrollController: FixedExtentScrollController(
                                initialItem: position),
                            onSelectedItemChanged: (int index) {
                              if (position != index) {
                                if (this.mounted) {
                                  setState(() {
                                    position = index;
                                  });
                                }
                              }
                            },
                            children: _text('otherList'),
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
        break;
      case "area":
        {
          String tempText = '';
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
                                  Navigator.pop(context);
                                  if (tempText != "-") {
                                    if (this.mounted) {
                                      setState(() {
                                        _areaController.text =
                                            _areaController.text +
                                                " " +
                                                tempText;
                                      });
                                    }
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
                            children: _text('otherList'),
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
        break;
    }
  }

  void checkConnection() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      _onLoading1();
      setupData();
      getTag();
      if (widget.details == null) {
        getDetails();
      } else {
        getParsingDetails();
      }
    }
  }

  void getParsingDetails() {
    otherList = widget.details.split("~!");
    otherList.insert(0, '-');
    if (this.mounted) {
      setState(() {
        gotData = true;
      });
    }
    for (int i = 0; i < otherList.length; i++) {
      if (otherList[i].toLowerCase().contains('@') &&
          otherList[i].toString().contains('.com')) {
        if (this.mounted) {
          setState(() {
            _emailController.text = otherList[i];
          });
        }
      }
      if (otherList[i].toLowerCase().contains('sdn bhd') ||
          otherList[i].toLowerCase().contains('company')) {
        if (this.mounted) {
          setState(() {
            _companyController.text = otherList[i];
          });
        }
      }
      if (otherList[i].toLowerCase().contains('jalan')) {
        if (this.mounted) {
          setState(() {
            _areaController.text = otherList[i];
          });
        }
      }
    }
    if (this.mounted) {
      setState(() {
        nameCard = true;
      });
    }
    if (allHandler == true && allTag == true && nameCard == true) {
      Navigator.pop(context);
    }
  }

  void getDetails() {
    http.post(urlDetails, body: {
      "companyID": widget.vdata.companyID,
      "branchID": widget.vdata.branchID,
      "userID": widget.vdata.userID,
      "user_type": widget.vdata.userType,
      "level": widget.vdata.level,
      "phoneNo": widget.vdata.phoneNo,
    }).then((res) {
      if (res.body != "") {
        otherList = res.body.split("~!");
        otherList.insert(0, '-');
        if (this.mounted) {
          setState(() {
            gotData = true;
          });
        }
      }
      for (int i = 0; i < otherList.length; i++) {
        if (otherList[i].toLowerCase().contains('@') &&
            otherList[i].toString().contains('.com')) {
          if (this.mounted) {
            setState(() {
              _emailController.text = otherList[i];
            });
          }
        }
        if (otherList[i].toLowerCase().contains('sdn bhd') ||
            otherList[i].toLowerCase().contains('company')) {
          if (this.mounted) {
            setState(() {
              _companyController.text = otherList[i];
            });
          }
        }
        if (otherList[i].toLowerCase().contains('jalan')) {
          if (this.mounted) {
            setState(() {
              _areaController.text = otherList[i];
            });
          }
        }
      }
      if (this.mounted) {
        setState(() {
          nameCard = true;
        });
      }
      if (allHandler == true && allTag == true && nameCard == true) {
        Navigator.pop(context);
      }
    }).catchError((err) {
      print("Setup Data error: " + (err).toString());
    });
  }

  void setupData() {
    http.post(urlHandler, body: {
      "companyID": widget.vdata.companyID,
      "branchID": widget.vdata.branchID,
      "userID": widget.vdata.userID,
      "user_type": widget.vdata.userType,
      "level": widget.vdata.level,
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        for (var data in jsonData) {
          Handler handler = Handler(
            handler: data["handler"],
            position: data["position"],
            handlerID: data["handlerID"],
          );
          handlerList.add(handler);
          handlerList1.add(handler);
        }
        for (int i = 0; i < widget.handler.length; i++) {
          for (int j = 0; j < handlerList.length; j++) {
            if (widget.handler[i] == handlerList[j].handler) {
              handlerList.removeAt(j);
            }
          }
        }
        for (int i = 0; i < gender.length; i++) {
          Gender genderforEach = Gender(gender: gender[i], position: i);
          genderList.add(genderforEach);
        }
        for (int i = 0; i < industry.length; i++) {
          Industry industryforEach =
              Industry(industry: industry[i], position: i);
          industryList.add(industryforEach);
        }
        for (int i = 0; i < country.length; i++) {
          Country countryforEach = Country(country: country[i], position: i);
          countryList.add(countryforEach);
        }
        for (int i = 0; i < states.length; i++) {
          States stateforEach = States(state: states[i], position: i);
          statesList.add(stateforEach);
        }
      } else {
        _toast("Something wrong, please contact VVIN IT help desk");
      }
      if (this.mounted) {
        setState(() {
          allHandler = true;
        });
      }
      if (allHandler == true && allTag == true && nameCard == true) {
        Navigator.pop(context);
      }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Setup Data error: " + (err).toString());
    });
  }

  void getTag() {
    http.post(urlVTag, body: {
      "companyID": widget.vdata.companyID,
      "branchID": widget.vdata.branchID,
      "userID": widget.vdata.userID,
      "level": widget.vdata.level,
      "user_type": widget.vdata.userType,
      "phone_number": "all",
    }).then((res) {
      if (res.body != "nodata") {
        var jsonData = json.decode(res.body);
        vtagList = jsonData;
        vtagList.insert(0, "-");
      } else {
        vtagList.add("-");
      }
      for (int i = 0; i < widget.vtag.length; i++) {
        for (int j = 0; j < vtagList.length; j++) {
          if (vtagList[j] == widget.vtag[i]) {
            vtagList.removeAt(j);
          }
        }
      }
      if (this.mounted) {
        setState(() {
          allTag = true;
        });
      }
      if (allHandler == true && allTag == true && nameCard == true) {
        Navigator.pop(context);
      }
    }).catchError((err) {
      _toast("No Internet Connection");
      print("Setup Data error: " + (err).toString());
    });
  }

  void _onLoading1() {
    showGeneralDialog(
      barrierColor: Colors.grey.withOpacity(0.5),
      transitionBuilder: (context, a1, a2, widget) {
        final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
        return Transform(
          transform: Matrix4.translationValues(0.0, curvedValue * -200, 0.0),
          child: Opacity(
            opacity: a1.value,
            child: WillPopScope(
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
                ),
              ),
              onWillPop: () {},
            ),
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 300),
      barrierDismissible: false,
      context: context,
      pageBuilder: (BuildContext context, Animation animation,
          Animation secondaryAnimation) {},
    );
  }

  void _deleteHandler(int i) {
    if (this.mounted) {
      setState(() {
        widget.handler.removeAt(i);
      });
    }
    handlerList.clear();
    for (int i = 0; i < handlerList1.length; i++) {
      Handler handler = Handler(
        handler: handlerList1[i].handler,
        position: handlerList1[i].position,
        handlerID: handlerList1[i].handlerID,
      );
      handlerList.add(handler);
    }

    if (widget.handler.length != 0) {
      for (int i = 0; i < widget.handler.length; i++) {
        for (int j = 0; j < handlerList.length; j++) {
          if (widget.handler[i] == handlerList[j].handler) {
            handlerList.removeAt(j);
          }
        }
      }
    }
  }

  void _save() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      _onLoading1();
      String vtag = "";
      if (widget.vprofileData.gender == "-" ||
          widget.vprofileData.gender == "") {
        if (this.mounted) {
          setState(() {
            widget.vprofileData.gender = "";
          });
        }
      } else {
        widget.vprofileData.gender =
            widget.vprofileData.gender.toUpperCase().substring(0, 1);
      }
      if (widget.vprofileData.industry == "-") {
        if (this.mounted) {
          setState(() {
            widget.vprofileData.industry = "";
          });
        }
      }
      if (widget.vprofileData.state == "-") {
        if (this.mounted) {
          setState(() {
            widget.vprofileData.state = "";
          });
        }
      }
      if (widget.vprofileData.country == "-") {
        if (this.mounted) {
          setState(() {
            widget.vprofileData.country = "";
          });
        }
      }
      for (int i = 0; i < widget.vtag.length; i++) {
        if (i == 0) {
          vtag = widget.vtag[i];
        } else {
          vtag = vtag + "," + widget.vtag[i];
        }
      }

      http.post(urlSaveEditVProfile, body: {
        "companyID": widget.vdata.companyID,
        "branchID": widget.vdata.branchID,
        "userID": widget.vdata.userID,
        "level": widget.vdata.level,
        "user_type": widget.vdata.userType,
        "phoneNo": widget.vdata.phoneNo,
        "name": _nameController.text ?? "",
        "email": _emailController.text ?? "",
        "company": _companyController.text ?? "",
        "ic": _icController.text ?? "",
        "dob": widget.vprofileData.dob ?? "",
        "gender": widget.vprofileData.gender ?? "",
        "position": _positionController.text ?? "",
        "industry": widget.vprofileData.industry ?? "",
        "occupation": _occupationController.text ?? "",
        "country": widget.vprofileData.country ?? "",
        "state": widget.vprofileData.state ?? "",
        "area": _areaController.text ?? "",
        "vtag": vtag,
      }).then((res) {
        // print("VProfile data: " + res.body);
        if (res.body == "success") {
          _saveHandler();
        } else {
          _toast("Something wrong, please contact VVIN IT help desk");
        }
      }).catchError((err) {
        _toast(err.toString());
        print("Save error: " + (err).toString());
      });
    } else {
      _toast("Please check your Internet connection");
    }
  }

  void _saveHandler() {
    if (widget.handler.length == 0) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      VDataDetails vdata1 = new VDataDetails(
        companyID: widget.vdata.companyID,
        branchID: widget.vdata.branchID,
        userID: widget.vdata.userID,
        level: widget.vdata.level,
        userType: widget.vdata.userType,
        date: widget.vdata.date,
        name: _nameController.text,
        phoneNo: widget.vdata.phoneNo,
        status: widget.vdata.status,
        email: widget.vdata.email,
      );
      Navigator.of(context).pop();
      Navigator.of(context).push(PageTransition(
        type: PageTransitionType.slideParallaxDown,
        child: VProfile(vdata: vdata1),
      ));
    } else {
      for (int i = 0; i < widget.handler.length; i++) {
        for (int j = 0; j < handlerList1.length; j++) {
          if (widget.handler[i] == handlerList1[j].handler) {
            http.post(urlSaveHandler, body: {
              "companyID": widget.vdata.companyID,
              "branchID": widget.vdata.branchID,
              "userID": widget.vdata.userID,
              "handlerID": handlerList1[j].handlerID,
              "level": widget.vdata.level,
              "user_type": widget.vdata.userType,
              "phoneNo": widget.vdata.phoneNo,
            }).then((res) {
              // print("Add handler: " + res.body.toString());
              if (i == widget.handler.length - 1 && res.body == "success") {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                VDataDetails vdata1 = new VDataDetails(
                  companyID: widget.vdata.companyID,
                  branchID: widget.vdata.branchID,
                  userID: widget.vdata.userID,
                  level: widget.vdata.level,
                  userType: widget.vdata.userType,
                  date: widget.vdata.date,
                  name: _nameController.text,
                  phoneNo: widget.vdata.phoneNo,
                  status: widget.vdata.status,
                  email: widget.vdata.email,
                );
                Navigator.of(context).pop();
                Navigator.of(context).push(PageTransition(
                  type: PageTransitionType.slideParallaxDown,
                  child: VProfile(vdata: vdata1),
                ));
              }
            }).catchError((err) {
              _toast("No Internet Connection");
              print("Save Handler error: " + (err).toString());
            });
          }
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
