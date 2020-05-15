import 'dart:convert';
import 'dart:io';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/forgot.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:vvin/vanalytics.dart';
import 'package:menu_button/menu_button.dart';

final TextEditingController _emcontroller = TextEditingController();
final TextEditingController _passcontroller = TextEditingController();
final ScrollController controller = ScrollController();
final String urlLogin = "https://vvinoa.vvin.com/api/login.php";
final String urlToken = "https://vvinoa.vvin.com/api/saveToken.php";
FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
String token, _email, _password, _mySelection;
bool login, visible;
List data;

class Login extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<Login> {
  String system, version, manufacture, model;
  SharedPreferences prefs;
  double _scaleFactor = 1.0;
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font15 = ScreenUtil().setSp(34.5, allowFontScalingSelf: false);
  double font25 = ScreenUtil().setSp(57.5, allowFontScalingSelf: false);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.white,
    ));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    token = "";
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {});
    _firebaseMessaging.getToken().then((fbtoken) {
      token = fbtoken;
      // print(fbtoken);
    });
    login = false;
    visible = false;
    setup();
    checkPlatform();
  }

  void setup() async {
    prefs = await SharedPreferences.getInstance();
    _emcontroller.text = prefs.getString('email');
    _email = "";
    _password = "";
    _passcontroller.text = '';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: true);
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            ScreenUtil().setHeight(1),
          ),
          child: AppBar(
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        body: SingleChildScrollView(
          controller: controller,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              ScreenUtil().setHeight(60),
              ScreenUtil().setHeight(100),
              ScreenUtil().setHeight(60),
              ScreenUtil().setHeight(60),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  width: ScreenUtil().setWidth(400),
                  height: ScreenUtil().setHeight(200),
                ),
                SizedBox(
                  height: ScreenUtil().setHeight(20),
                ),
                Text(
                  "Sign in",
                  style: TextStyle(
                    fontSize: font25,
                  ),
                ),
                (login == true)
                    ? Default()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          SizedBox(
                            height: ScreenUtil().setHeight(20),
                          ),
                          Text(
                            "Please enter your credentials to proceed.",
                            style:
                                TextStyle(fontSize: font14, color: Colors.grey),
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(60),
                          ),
                          Container(
                              child: Row(
                            children: <Widget>[
                              Text(
                                "Email address",
                                style: TextStyle(
                                    fontSize: font14,
                                    fontWeight: FontWeight.w500),
                              )
                            ],
                          )),
                          SizedBox(
                            height: ScreenUtil().setHeight(10),
                          ),
                          Container(
                            height: ScreenUtil().setHeight(80),
                            child: TextField(
                              style: TextStyle(
                                height: 1,
                                fontSize: font15,
                              ),
                              controller: _emcontroller,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                suffix: IconButton(
                                  onPressed: () {
                                    _emcontroller.text = "";
                                  },
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Colors.blue,
                                    size: ScreenUtil().setHeight(30),
                                  ),
                                ),
                                contentPadding: EdgeInsets.fromLTRB(
                                    ScreenUtil().setHeight(10),
                                    0,
                                    0,
                                    ScreenUtil().setHeight(30)),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey)),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(40),
                          ),
                          Container(
                              child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                "Password",
                                style: TextStyle(
                                    fontSize: font14,
                                    fontWeight: FontWeight.w500),
                              ),
                              GestureDetector(
                                onTap: _onForgot,
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                      fontSize: font14, color: Colors.grey),
                                ),
                              )
                            ],
                          )),
                          SizedBox(
                            height: ScreenUtil().setHeight(10),
                          ),
                          Container(
                            height: ScreenUtil().setHeight(80),
                            child: TextField(
                              style: TextStyle(
                                height: ScreenUtil().setHeight(2),
                                fontSize: font15,
                              ),
                              keyboardType: TextInputType.text,
                              controller: _passcontroller,
                              decoration: InputDecoration(
                                suffixIcon: (visible == false)
                                    ? IconButton(
                                        onPressed: () {
                                          if (this.mounted) {
                                            setState(() {
                                              visible = true;
                                            });
                                          }
                                        },
                                        icon: Icon(FontAwesomeIcons.eyeSlash,
                                            color: Colors.blue,
                                            size: ScreenUtil().setHeight(30)),
                                      )
                                    : IconButton(
                                        onPressed: () {
                                          if (this.mounted) {
                                            setState(() {
                                              visible = false;
                                            });
                                          }
                                        },
                                        icon: Icon(FontAwesomeIcons.eye,
                                            color: Colors.blue,
                                            size: ScreenUtil().setHeight(30)),
                                      ),
                                contentPadding: EdgeInsets.fromLTRB(
                                    ScreenUtil().setHeight(10),
                                    ScreenUtil().setHeight(10),
                                    0,
                                    ScreenUtil().setHeight(10)),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey)),
                              ),
                              obscureText: (visible == false) ? true : false,
                            ),
                          ),
                          SizedBox(
                            height: ScreenUtil().setHeight(50),
                          ),
                          BouncingWidget(
                            scaleFactor: _scaleFactor,
                            onPressed: _onLogin,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: ScreenUtil().setHeight(80),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: Color.fromRGBO(34, 175, 240, 1),
                              ),
                              child: Center(
                                child: Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: font15,
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
    );
  }

  void _onLogin() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    _email = _emcontroller.text.toLowerCase();
    _password = _passcontroller.text;

    if (_email != "" && _password != "") {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.mobile) {
        _onLoading1();
        http.post(urlLogin, body: {
          "username": _email.toLowerCase(),
          "password": _password,
        }).then((res) async {
          var extractdata = json.decode(res.body);
          // print("Login body: " + (extractdata).toString());
          data = extractdata;

          if (data[0] == "success") {
            data.removeAt(0);
            if (data.length == 1) {
              setState(() {
                _mySelection = data[0];
              });
              _onProceed();
            } else {
              Navigator.pop(context);
              setState(() {
                login = true;
                _mySelection = data[0];
              });
            }
          } else {
            Navigator.pop(context);
            FocusScope.of(context).requestFocus(new FocusNode());
            _toast("Login Failed");
          }
        }).catchError((err) {
          Navigator.pop(context);
          FocusScope.of(context).requestFocus(new FocusNode());
          _toast(err.toString());
          print("On Login error: " + (err).toString());
        });
      } else {
        _toast("No Internet Connection!");
      }
    } else {
      _toast("Please fill in email address and password");
    }
  }

  Future<void> _onProceed() async {
    FocusScope.of(context).requestFocus(new FocusNode());
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlToken, body: {
        "email": _email,
        "companyName": _mySelection,
        "lastLogin": DateTime.now().toString(),
        "token": token,
        "system": system,
        "version": version,
        "manufacture": manufacture,
        "model": model,
      }).then((res) async {
        if (res.body != "failed") {
          var data = json.decode(res.body);
          // print("On proceed body: " + (data).toString());
          await prefs.setString('email', _email);
          await prefs.setString('companyID', data[0]);
          await prefs.setString('userID', data[1]);
          await prefs.setString('level', data[2]);
          await prefs.setString('user_type', data[4]);
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VAnalytics(name: data[3])));
        } else {
          Navigator.pop(context);
          _toast("Please contact VVIN IT desk");
        }
      }).catchError((err) {
        Navigator.pop(context);
        _toast("Please contact VVIN IT desk");
        print("On proceed error: " + err.toString());
      });
    } else {
      _toast("No Internet Connection!");
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

  void _onForgot() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Forgot()));
  }

  Future<bool> _onBackPressAppBar() async {
    SystemNavigator.pop();
    return Future.value(false);
  }

  bool _isEmailValid(String email) {
    return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
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
                ),
                onWillPop: () {},
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {});
  }

  Future<void> checkPlatform() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      system = "android " + androidInfo.version.release.toString();
      version = "version " + androidInfo.version.sdkInt.toString();
      manufacture = androidInfo.manufacturer.toString();
      model = androidInfo.model.toString();
    }

    if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      system = iosInfo.systemName.toString();
      version = iosInfo.systemVersion.toString();
      manufacture = iosInfo.name.toString();
      model = iosInfo.model.toString();
    }
  }
}

class Default extends StatefulWidget {
  @override
  _Default createState() => _Default();
}

class _Default extends State<Default> {
  double _scaleFactor = 1.0;
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font15 = ScreenUtil().setSp(34.5, allowFontScalingSelf: false);
  String system, version, manufacture, model;

  @override
  void initState() {
    checkPlatform();
    _mySelection = data[0];
    super.initState();
  }

  Future<void> checkPlatform() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      system = "android " + androidInfo.version.release.toString();
      version = "version " + androidInfo.version.sdkInt.toString();
      manufacture = androidInfo.manufacturer.toString();
      model = androidInfo.model.toString();
    }

    if (Platform.isIOS) {
      var iosInfo = await DeviceInfoPlugin().iosInfo;
      system = iosInfo.systemName.toString();
      version = iosInfo.systemVersion.toString();
      manufacture = iosInfo.name.toString();
      model = iosInfo.model.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      height: ScreenUtil().setHeight(60),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                _mySelection,
                style: TextStyle(fontSize: font14),
              ),
            ),
            SizedBox(
              width: ScreenUtil().setWidth(50),
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
    return Column(
      children: <Widget>[
        SizedBox(
          height: ScreenUtil().setHeight(60),
        ),
        Row(
          children: <Widget>[
            Text(
              "Please select a company",
              style: TextStyle(fontSize: font15, fontWeight: FontWeight.w500),
            )
          ],
        ),
        SizedBox(
          height: ScreenUtil().setHeight(20),
        ),
        MenuButton(
          child: button,
          items: data,
          scrollPhysics: AlwaysScrollableScrollPhysics(),
          topDivider: true,
          itemBuilder: (value) => Container(
            height: ScreenUtil().setHeight(60),
            width: MediaQuery.of(context).size.width * 0.8,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 10),
            child: Text(value, style: TextStyle(fontSize: font14)),
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
              _mySelection = value;
            });
          },
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.all(Radius.circular(3.0)),
              color: Colors.white),
          onMenuButtonToggle: (isToggle) {},
        ),
        SizedBox(
          height: ScreenUtil().setHeight(60),
        ),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: ScreenUtil().setHeight(80),
          ),
          child: BouncingWidget(
            scaleFactor: _scaleFactor,
            onPressed: _onProceed,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: ScreenUtil().setHeight(80),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Color.fromRGBO(34, 175, 240, 1),
              ),
              child: Center(
                child: Text(
                  'Proceed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: font14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onProceed() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      _onLoading1();
      http.post(urlToken, body: {
        "email": _email,
        "companyName": _mySelection,
        "lastLogin": DateTime.now().toString(),
        "token": token,
        "system": system,
        "version": version,
        "manufacture": manufacture,
        "model": model,
      }).then((res) async {
        // print("Level: " + res.body);
        if (res.body != "failed") {
          var data = json.decode(res.body);
          // print("On proceed body: " + (data).toString());
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('email', _email);
          await prefs.setString('companyID', data[0]);
          await prefs.setString('userID', data[1]);
          await prefs.setString('level', data[2]);
          await prefs.setString('user_type', data[4]);
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VAnalytics(name: data[3])));
        } else {
          Navigator.pop(context);
          _toast("Please contact VVIN IT desk");
        }
      }).catchError((err) {
        Navigator.pop(context);
        _toast(err.toString());
        print("On proceed error: " + err.toString());
      });
    } else {
      _toast("No Internet Connection!");
    }
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
                ),
                onWillPop: () {},
              ),
            ),
          );
        },
        transitionDuration: Duration(milliseconds: 300),
        barrierDismissible: false,
        context: context,
        pageBuilder: (context, animation1, animation2) {});
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