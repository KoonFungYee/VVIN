import 'dart:async';
import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/data.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:vvin/vprofile.dart';

class NotiDetail extends StatefulWidget {
  final NotificationDetail notification;
  final String companyID;
  final String level;
  final String userID;
  final String userType;
  const NotiDetail(
      {Key key,
      this.notification,
      this.companyID,
      this.level,
      this.userID,
      this.userType})
      : super(key: key);

  @override
  _NotiDetailState createState() => _NotiDetailState();
}

enum UniLinksType { string, uri }

class _NotiDetailState extends State<NotiDetail> {
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
  double font13 = ScreenUtil().setSp(30, allowFontScalingSelf: false);
  double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
  double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
  String urlHandler = "https://vvinoa.vvin.com/api/handler.php";
  String handlers = "https://vvinoa.vvin.com/api/getHandler.php";
  String assignURL = "https://vvinoa.vvin.com/api/assign.php";
  final ScrollController controller = ScrollController();
  String companyID, userID, level, userType, phoneNo;
  bool handlerStatus, hListStatus, click;
  List name = [];
  List number = [];
  List handler = [];
  List<Handler> allHandler = [];

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    check();
    handlerStatus = hListStatus = click = false;
    companyID = widget.companyID;
    userID = widget.userID;
    level = widget.level;
    userType = widget.userType;
    try {
      name = widget.notification.subtitle1.toString().split("Contact Number: ");
      number = name[1].toString().split("Make");
      phoneNo = number[0].toString();
    } catch (e) {}
    getHandler();
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

  @override
  void dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
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
                "Notification",
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
                padding: EdgeInsets.fromLTRB(10, 30, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        widget.notification.title,
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                            fontSize: font14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              (widget.notification.subtitle1.substring(0, 7) == "Details")
                  ? Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Details:",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: font12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Name: " + name[0].toString().substring(13),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: font12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Contact Number: " + number[0].toString(),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: font12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(10, 20, 10, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Make" +
                                    number[1].toString().substring(
                                        0, number[1].toString().length - 18),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: font12,
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  (level == '0') ? _assign() : _view();
                                },
                                child: Text(
                                  (level == '0') ? ' Assign Now' : ' View Now',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: font12,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              (widget.notification.subtitle2 != "")
                                  ? widget.notification.subtitle1 + ","
                                  : widget.notification.subtitle1,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: font12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              (widget.notification.subtitle2 != "")
                  ? Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              widget.notification.subtitle2.substring(1),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: font12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              (widget.notification.subtitle2 != "")
                  ? Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              "If you did not perform the action, kindly contact our customer support immediately at support@jtapps.com.my to secure your account.",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: font12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(),
              Padding(
                padding: EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        "Thank you.",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: font12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        "VVIN Team",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: font12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.pop(context);
    return Future.value(false);
  }

  void _view() {
    VDataDetails vdata = new VDataDetails(
        companyID: companyID,
        userID: userID,
        level: level,
        userType: userType,
        name: name[0].toString().substring(13),
        phoneNo: phoneNo,
        status: '',
      );
    Navigator.of(context).push(PageRouteTransition(
        animationType: AnimationType.scale,
        builder: (context) => VProfile(vdata: vdata)));
  }

  void _assign() async {
    if (handlerStatus == false || hListStatus == false) {
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
    if (handlerStatus == false || hListStatus == false) {
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

  void _assignDone() async {
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
        "userID": userID,
        "level": level,
        "user_type": userType,
        "id": phoneNo,
        "handler": handlerIDs,
        "type": 'phone',
      }).then((res) async {
        if (res.body == "success") {
          Navigator.of(context).pop();
          _toast("Handler updated");
        } else {
          Navigator.of(context).pop();
          _toast("Something's wrong");
        }
      }).catchError((err) {
        Navigator.of(context).pop();
        print("Assign error: " + (err).toString());
      });
    } else {
      Navigator.of(context).pop();
      _toast("No Internet, data can't update");
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

  void getHandler() async {
    if (phoneNo != null) {
      setupData();
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
            handlerStatus = true;
          });
        }
      }).catchError((err) {
        _toast(err.toString());
        print("Get handler error: " + (err).toString());
      });
    }
  }

  void setupData() {
    companyID = companyID;
    userID = userID;
    level = level;
    userType = userType;
    http.post(handlers, body: {
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
      print("Setup Data error: " + (err).toString());
    });
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
