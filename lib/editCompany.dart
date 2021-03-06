import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/companyDB.dart';
import 'package:vvin/more.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/profile.dart';
import 'package:vvin/data.dart';
import 'package:vvin/reminder.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:vvin/reminderDB.dart';

final ScrollController controller = ScrollController();
final TextEditingController _nameController = TextEditingController();
final TextEditingController _phoneController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _websiteController = TextEditingController();
final TextEditingController _addressController = TextEditingController();

class EditCompany extends StatefulWidget {
  final EditCompanyDetails company;
  final List<UserData> userData;
  const EditCompany({Key key, this.company, this.userData}) : super(key: key);

  @override
  _EditCompanyState createState() => _EditCompanyState();
}

enum UniLinksType { string, uri }

class _EditCompanyState extends State<EditCompany> {
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
  SharedPreferences prefs;
  UniLinksType _type = UniLinksType.string;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  String urlEditCompany = ip + "editCompanyProfile.php";
  String urlUploadImage = ip + "uploadImage.php";
  File _image;
  int number;
  String userID,
      companyID,
      branchID,
      level,
      userType,
      image,
      name,
      phone,
      email,
      website,
      address,
      now,
      status;

  @override
  void initState() {
    _init();
    check();
    companyID = widget.company.companyID;
    branchID = widget.company.branchID;
    userID = widget.company.userID;
    level = widget.company.level;
    userType = widget.company.userType;
    image = widget.company.image;
    _nameController.text = widget.company.name;
    _phoneController.text = widget.company.phone;
    _emailController.text = widget.company.email;
    _websiteController.text = widget.company.website;
    _addressController.text = widget.company.address;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.white,
    ));
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {});
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
          List list = payload.substring(8).split('~!');
          List data = [];
          String handler = list[5];
          data.add(handler);
          data.add(widget.userData[0].userID);
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
              userData: widget.userData,
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
              "Edit Profile",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.black,
                  fontSize: font18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: controller,
          child: Column(
            children: <Widget>[
              Container(
                padding:
                    EdgeInsets.fromLTRB(0, ScreenUtil().setHeight(20), 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    InkWell(
                      onTap: _camera,
                      child: Stack(
                        children: <Widget>[
                          Positioned(
                            top: ScreenUtil().setHeight(20),
                            left: ScreenUtil().setWidth(20),
                            child: Container(
                              padding: EdgeInsets.all(200.0),
                              width: ScreenUtil().setWidth(200),
                              height: ScreenUtil().setHeight(200),
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: CachedNetworkImageProvider(image),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: ScreenUtil().setHeight(240),
                            width: ScreenUtil().setWidth(240),
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(105, 105, 105, 0.5),
                              shape: BoxShape.rectangle,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                          Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              margin: EdgeInsets.all(ScreenUtil().setWidth(95)),
                              height: ScreenUtil().setWidth(60),
                              width: ScreenUtil().setWidth(60),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: ScreenUtil().setWidth(50),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(
                  ScreenUtil().setHeight(20),
                ),
                color: Colors.white,
                margin: EdgeInsets.fromLTRB(
                    ScreenUtil().setHeight(60),
                    ScreenUtil().setHeight(20),
                    ScreenUtil().setHeight(60),
                    ScreenUtil().setHeight(20)),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Name",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: font14),
                        )
                      ],
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(5),
                    ),
                    Container(
                      height: ScreenUtil().setHeight(55),
                      color: Color.fromRGBO(235, 235, 255, 1),
                      child: TextField(
                        style: TextStyle(
                          height: 1,
                          fontSize: font15,
                        ),
                        controller: _nameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue)),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(20),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Phone",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                            fontSize: font14,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(5),
                    ),
                    Container(
                      height: ScreenUtil().setHeight(55),
                      color: Color.fromRGBO(235, 235, 255, 1),
                      child: TextField(
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          height: 1,
                          fontSize: font15,
                        ),
                        controller: _phoneController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue)),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(20),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Email",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: font14,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(5),
                    ),
                    Container(
                      height: ScreenUtil().setHeight(55),
                      color: Color.fromRGBO(235, 235, 255, 1),
                      child: TextField(
                        style: TextStyle(
                          height: 1,
                          fontSize: font15,
                        ),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue)),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(20),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Website",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                            fontSize: font14,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(5),
                    ),
                    Container(
                      height: ScreenUtil().setHeight(55),
                      color: Color.fromRGBO(235, 235, 255, 1),
                      child: TextField(
                        style: TextStyle(
                          height: 1,
                          fontSize: font15,
                        ),
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue)),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(20),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          "Address",
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                            fontSize: font14,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(5),
                    ),
                    Container(
                      padding: EdgeInsets.all(
                        ScreenUtil().setHeight(0),
                      ),
                      height: ScreenUtil().setHeight(240),
                      color: Color.fromRGBO(235, 235, 255, 1),
                      child: TextField(
                        maxLines: 5,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          height: ScreenUtil().setHeight(2),
                          fontSize: font15,
                        ),
                        controller: _addressController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.lightBlue)),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: ScreenUtil().setHeight(20),
                    ),
                    BouncingWidget(
                      scaleFactor: _scaleFactor,
                      onPressed: _saveEditCompany,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: ScreenUtil().setHeight(70),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Color.fromRGBO(34, 175, 240, 1),
                        ),
                        child: Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Roboto',
                              fontSize: font15,
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
      ),
    );
  }

  Future<bool> _onBackPressAppBar() async {
    UserData userData = UserData(
        companyID: companyID,
        branchID: branchID,
        userID: userID,
        userType: userType,
        level: level,
      );
      List<UserData> list = [];
      list.add(userData);
    Navigator.pop(
        context,
        MaterialPageRoute(
          builder: (context) => Profile(
            userData: list,
          ),
        ));
    return Future.value(false);
  }

  void _camera() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return CupertinoActionSheet(
              title: Text(
                "Action",
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: font13,
                ),
              ),
              cancelButton: CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: font20,
                  ),
                ),
              ),
              actions: <Widget>[
                CupertinoActionSheetAction(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _image = await ImagePicker.pickImage(
                        source: ImageSource.gallery);
                    _saveProfilePicture();
                  },
                  child: Text(
                    "Browse Gallery",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: font20,
                    ),
                  ),
                ),
                CupertinoActionSheetAction(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _image =
                        await ImagePicker.pickImage(source: ImageSource.camera);
                    _saveProfilePicture();
                  },
                  child: Text(
                    "Take Photo",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: font20,
                    ),
                  ),
                ),
              ],
            );
          });
    } else {
      _toast("No Internet Connection");
    }
  }

  void _saveProfilePicture() async {
    String base64Image = base64Encode(_image.readAsBytesSync());
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlUploadImage, body: {
        "encoded_string": base64Image,
        "companyID": companyID,
        "branchID": branchID,
        "userID": userID,
        "level": level,
        "user_type": userType,
      }).then((res) {
        if (res.body.toString() != "nodata") {
          if (this.mounted) {
            setState(() {
              image = res.body.toString();
            });
          }
          _toast("Image changed");
          _downloadImage(image, "company", "profile");
        } else {
          _toast("Image can't save, please contact VVIN help desk");
        }
      }).catchError((err) {
        print("Upload image error: " + err.toString());
      });
    } else {
      _toast("No Internet Connection, image can't change");
    }
  }

  void _saveEditCompany() async {
    name = _nameController.text;
    phone = _phoneController.text;
    email = _emailController.text.toLowerCase();
    website = _websiteController.text;
    address = _addressController.text;

    if (_isEmailValid(email)) {
      if (name != "" &&
          phone != "" &&
          email != "" &&
          website != "" &&
          address != "") {
        var connectivityResult = await (Connectivity().checkConnectivity());
        if (connectivityResult == ConnectivityResult.wifi ||
            connectivityResult == ConnectivityResult.mobile) {
          http.post(urlEditCompany, body: {
            "companyID": companyID,
            "branchID": branchID,
            "userID": userID,
            "level": level,
            "user_type": userType,
            "name": name,
            "phone": phone,
            "email": email,
            "website": website,
            "address": address,
          }).then((res) async {
            if (res.body == "success") {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => More(),
                ),
              );
              setData();
              _toast("Update successfully");
            } else {
              _toast("Update failed, please contact VVIN help desk");
            }
          }).catchError((err) {
            _toast(err.toString());
            print("Save Edit Company error: " + (err).toString());
          });
        } else {
          _toast("No Internet Connection, data can't save");
        }
      } else {
        _toast("Please fill in all column");
      }
    } else {
      _toast("Your email address format is incorrectly");
    }
  }

  bool _isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  Future<void> setData() async {
    Database db = await CompanyDB.instance.database;
    await db.rawInsert('DELETE FROM details WHERE id > 0');
    await db.rawInsert(
        'INSERT INTO details (name, phone, email, website, address) VALUES("' +
            name +
            '","' +
            phone +
            '","' +
            email +
            '","' +
            website +
            '","' +
            address +
            '")');
  }

  Future<String> get _localDevicePath async {
    final _devicePath = await getApplicationDocumentsDirectory();
    return _devicePath.path;
  }

  Future _downloadImage(String url, String path, String name) async {
    final _response = await http.get(url);
    if (_response.statusCode == 200) {
      final _file = await _localImage(path: path, name: name);
      await _file.writeAsBytes(_response.bodyBytes);
    }
  }

  Future<File> _localImage({String path, String name}) async {
    String _path = await _localDevicePath;

    var _newPath = await Directory("$_path/$path").create();
    return File("${_newPath.path}/$name.jpg");
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
