import 'dart:async';
import 'dart:convert';
import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity/connectivity.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ndialog/ndialog.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uni_links/uni_links.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/calendarEvent.dart';
import 'package:vvin/data.dart';
import 'package:vvin/notifications.dart';
import 'package:vvin/reminder.dart';
import 'package:vvin/reminderDB.dart';
import 'package:vvin/vformResponse.dart';
import 'package:http/http.dart' as http;

class VForm extends StatefulWidget {
  final String title;
  final String id;
  final String companyID;
  final String branchID;
  final String userID;
  final String level;
  final String userType;
  VForm(
      {Key key,
      this.title,
      this.id,
      this.companyID,
      this.branchID,
      this.userID,
      this.level,
      this.userType})
      : super(key: key);

  @override
  _VFormState createState() => _VFormState();
}

enum UniLinksType { string, uri }

class _VFormState extends State<VForm> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  StreamSubscription _sub;
  UniLinksType _type = UniLinksType.string;
  NotificationAppLaunchDetails notificationAppLaunchDetails;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  SharedPreferences prefs;
  String urlVForm = ip + "vform.php";
  String urlDelete = ip + "deleteResponse.php";
  String now, total, search, companyID, userID, branchID, userType, level;
  bool nodata, more, ready;
  List vform = [];
  

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    search = '';
    check();
    _init();
    initial();
    ready = nodata = false;
    more = true;
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
              widget.title,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: font14,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        body: Container(
          margin: EdgeInsets.fromLTRB(ScreenUtil().setHeight(10),
              ScreenUtil().setHeight(10), ScreenUtil().setHeight(10), 0),
          child: Column(
            children: <Widget>[
              Card(
                child: Container(
                  margin: EdgeInsets.only(
                    left: ScreenUtil().setHeight(20),
                  ),
                  height: ScreenUtil().setHeight(75),
                  child: TextField(
                    onChanged: _search,
                    style: TextStyle(
                      fontSize: font14,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.fromLTRB(
                          0, 0, 0, ScreenUtil().setHeight(10)),
                      hintText: "Search",
                      suffix: IconButton(
                        padding: const EdgeInsets.all(1.0),
                        iconSize: ScreenUtil().setHeight(40),
                        icon: Icon(Icons.keyboard_hide),
                        onPressed: () {
                          FocusScope.of(context).requestFocus(new FocusNode());
                        },
                      ),
                      suffixIcon: Icon(
                        Icons.search,
                        size: ScreenUtil().setHeight(50),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: ScreenUtil().setHeight(5),
              ),
              Container(
                padding:
                    EdgeInsets.fromLTRB(ScreenUtil().setHeight(10), 0, 0, 0),
                child: Row(
                  children: <Widget>[
                    Text("Total Responses: ",
                        style: TextStyle(
                            color: Color.fromRGBO(61, 73, 100, 1),
                            fontSize: font12)),
                    (total == null)
                        ? JumpingText('Loading...',
                            style: TextStyle(
                                fontSize: font12,
                                color: Color.fromRGBO(61, 73, 100, 1)))
                        : Text(total,
                            style: TextStyle(
                                color: Color.fromRGBO(61, 73, 100, 1),
                                fontSize: font12)),
                  ],
                ),
              ),
              SizedBox(
                height: ScreenUtil().setHeight(10),
              ),
              (nodata == true)
                  ? Center(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: EmptyListWidget(
                            packageImage: PackageImage.Image_2,
                            // title: 'No Data',
                            subTitle: 'No Responses',
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
                  : (ready == false)
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.75,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                JumpingText('Loading...'),
                                SizedBox(
                                    height: MediaQuery.of(context).size.height *
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
                            onLoading: _onLoading,
                            child: ListView.builder(
                                itemCount: vform.length,
                                itemBuilder: (context, int index) {
                                  return WidgetANimator(
                                    Card(
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.fromLTRB(
                                                ScreenUtil().setHeight(10),
                                                ScreenUtil().setHeight(15),
                                                ScreenUtil().setHeight(10),
                                                0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                _date(index),
                                                popupMenuButton(index),
                                              ],
                                            ),
                                          ),
                                          Divider(),
                                          InkWell(
                                            onTap: () {
                                              _vformResponse(index);
                                            },
                                            child: _content(index),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  void _vformResponse(int index) {
    List list = vform[index].toString().split(':');
    String length = list[0].toString().substring(1);
    Navigator.of(context).push(
      PageRouteTransition(
        animationType: AnimationType.scale,
        builder: (context) => VFormResponse(
          id: (int.parse(total) - index).toString(),
          vformID: widget.id,
          reponseID: vform[index][length]['1']['id'],
          companyID: widget.companyID,
          branchID: widget.branchID,
          userID: widget.userID,
          level: widget.level,
          userType: widget.userType,
          title: widget.title,
          data: vform[index],
        ),
      ),
    );
  }

  Future<void> _search(String value) async {
    if (this.mounted) {
      setState(() {
        search = value.toLowerCase();
        nodata = false;
      });
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlVForm, body: {
        "companyID": widget.companyID,
        "branchID": widget.branchID,
        "userID": widget.userID,
        "level": widget.level,
        "user_type": widget.userType,
        "id": widget.id,
        "limit": '0',
        "search": search,
      }).then((res) {
        if (res.body == "nodata") {
          if (this.mounted) {
            setState(() {
              nodata = true;
              ready = true;
            });
          }
        } else {
          vform.clear();
          var jsonData = json.decode(res.body);
          if (this.mounted) {
            setState(() {
              total = jsonData[0]['total'];
            });
          }
          int listLength = int.parse(jsonData[0]['total']);
          if (listLength > 30) {
            for (int i = 0; i < 30; i++) {
              vform.add(jsonData[i]['data']);
            }
          } else {
            for (int i = 0; i < listLength; i++) {
              vform.add(jsonData[i]['data']);
            }
          }
          if (this.mounted) {
            setState(() {
              ready = true;
            });
          }
        }
      }).catchError((err) {
        _toast(err.toString());
        print("Search error: " + (err).toString());
      });
    } else {
      _toast("Please check your Internet Connection");
    }
  }

  Future<void> _delete(int index) async {
    List list = vform[index].toString().split(':');
    String length = list[0].toString().substring(1);
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      Navigator.pop(context);
      http
          .post(urlDelete, body: {
            "companyID": widget.companyID,
            "branchID": widget.branchID,
            "userID": widget.userID,
            "level": widget.level,
            "user_type": widget.userType,
            "id": widget.id,
            "response_id": vform[index][length]['1']['id'],
          })
          .then((res) {})
          .catchError((err) {
            _toast(err.toString());
            print("Delete error: " + (err).toString());
          });
    } else {
      _toast("Please check your Internet Connection");
    }
    _toast('Response #' + (int.parse(total) - index).toString() + ' deleted');
    vform.removeAt(index);
    if (this.mounted) {
      setState(() {
        ready = true;
        total = (int.parse(total) - 1).toString();
      });
    }
  }

  Widget _date(int index) {
    List list = vform[index].toString().split(':');
    String length = list[0].toString().substring(1);
    Widget widget1 = Text(
      vform[index][length]['1']['date'] +
          ' | Response #' +
          (int.parse(total) - index).toString(),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Color.fromRGBO(165, 165, 165, 1),
        fontSize: font12,
      ),
    );
    return widget1;
  }

  Widget _content(int index) {
    Widget widget1;
    List list = vform[index].toString().split(':');
    String length = list[0].toString().substring(1);
    if (int.parse(length) >= 2) {
      widget1 = Container(
        padding: EdgeInsets.fromLTRB(ScreenUtil().setHeight(10), 0,
            ScreenUtil().setHeight(10), ScreenUtil().setHeight(10)),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Flexible(
                  child: Text(
                    vform[index][length]['1']['title'],
                    style: TextStyle(
                      color: Color.fromRGBO(120, 120, 120, 1),
                      fontSize: font12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                    (vform[index][length]['1']['answer'].length < 6)
                        ? (vform[index][length]['1']['answer'] == '')
                            ? '-'
                            : vform[index][length]['1']['answer']
                        : (vform[index][length]['1']['answer']
                                    .toString()
                                    .substring(0, 5) ==
                                'https')
                            ? 'Click to view the image'
                            : vform[index][length]['1']['answer'],
                    style: TextStyle(
                      color: Color.fromRGBO(20, 23, 32, 1),
                      fontSize: font14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
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
                    vform[index][length]['2']['title'],
                    style: TextStyle(
                      color: Color.fromRGBO(120, 120, 120, 1),
                      fontSize: font12,
                    ),
                    overflow: TextOverflow.ellipsis,
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
                    (vform[index][length]['2']['answer'].length < 6)
                        ? (vform[index][length]['2']['answer'] == '')
                            ? '-'
                            : vform[index][length]['2']['answer']
                        : (vform[index][length]['2']['answer']
                                    .toString()
                                    .substring(0, 5) ==
                                'https')
                            ? 'Click to view the image'
                            : vform[index][length]['2']['answer'],
                    style: TextStyle(
                      color: Color.fromRGBO(20, 23, 32, 1),
                      fontSize: font14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          ],
        ),
      );
    } else {
      if (int.parse(length) == 1) {
        widget1 = Container(
          padding: EdgeInsets.fromLTRB(ScreenUtil().setHeight(10), 0,
              ScreenUtil().setHeight(10), ScreenUtil().setHeight(10)),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      vform[index][length]['1']['title'],
                      style: TextStyle(
                        color: Color.fromRGBO(120, 120, 120, 1),
                        fontSize: font12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
                      (vform[index][length]['1']['answer'].length < 6)
                          ? (vform[index][length]['1']['answer'] == '')
                              ? '-'
                              : vform[index][length]['1']['answer']
                          : (vform[index][length]['1']['answer']
                                      .toString()
                                      .substring(0, 5) ==
                                  'https')
                              ? 'Click to view the image'
                              : vform[index][length]['1']['answer'],
                      style: TextStyle(
                        color: Color.fromRGBO(20, 23, 32, 1),
                        fontSize: font14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      }
    }
    return widget1;
  }

  void _onRefresh() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlVForm, body: {
        "companyID": widget.companyID,
        "branchID": widget.branchID,
        "userID": widget.userID,
        "level": widget.level,
        "user_type": widget.userType,
        "id": widget.id,
        "count": '0',
        "search": search,
      }).then((res) {
        vform.clear();
        var jsonData = json.decode(res.body);
        if (this.mounted) {
          setState(() {
            total = jsonData[0]['total'];
          });
        }
        int listLength = int.parse(jsonData[0]['total']);
        if (listLength > 30) {
          for (int i = 0; i < 30; i++) {
            vform.add(jsonData[i]['data']);
          }
        } else {
          for (int i = 0; i < listLength; i++) {
            vform.add(jsonData[i]['data']);
          }
        }
        if (this.mounted) {
          setState(() {
            ready = true;
          });
        }
        _refreshController.refreshCompleted();
      }).catchError((err) {
        _toast(err.toString());
        print("VForm Responses onLoading error: " + (err).toString());
      });
      _refreshController.refreshCompleted();
    } else {
      _toast("No Internet connection, data can't load");
      _refreshController.refreshCompleted();
    }
  }

  void _onLoading() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      http.post(urlVForm, body: {
        "companyID": widget.companyID,
        "branchID": widget.branchID,
        "userID": widget.userID,
        "level": widget.level,
        "user_type": widget.userType,
        "id": widget.id,
        "count": vform.length.toString(),
        "search": search,
      }).then((res) {
        if (res.body == "nodata") {
          if (this.mounted) {
            setState(() {
              ready = true;
            });
          }
          _refreshController.loadComplete();
        } else {
          var jsonData = json.decode(res.body);
          int listLength = int.parse(jsonData[0]['total']);
          if (listLength > 30) {
            for (int i = 0; i < 30; i++) {
              vform.add(jsonData[i]['data']);
            }
          } else {
            for (int i = 0; i < listLength; i++) {
              vform.add(jsonData[i]['data']);
            }
          }
          if (this.mounted) {
            setState(() {
              ready = true;
            });
          }
          _refreshController.loadComplete();
        }
      }).catchError((err) {
        _toast(err.toString());
        print("VForm Responses onLoading error: " + (err).toString());
      });
      _refreshController.loadComplete();
    } else {
      _toast("No Internet connection, data can't load");
      _refreshController.loadComplete();
    }
  }

  Future<void> initial() async {
    http.post(urlVForm, body: {
      "companyID": widget.companyID,
      "branchID": widget.branchID,
      "userID": widget.userID,
      "level": widget.level,
      "user_type": widget.userType,
      "id": widget.id,
      "limit": '0',
      "search": search,
    }).then((res) {
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            nodata = true;
            ready = true;
            total = '0';
          });
        }
      } else {
        vform.clear();
        var jsonData = json.decode(res.body);
        if (this.mounted) {
          setState(() {
            total = jsonData[0]['total'];
          });
        }
        int listLength = int.parse(jsonData[0]['total']);
        if (listLength > 30) {
          for (int i = 0; i < 30; i++) {
            vform.add(jsonData[i]['data']);
          }
        } else {
          for (int i = 0; i < listLength; i++) {
            vform.add(jsonData[i]['data']);
          }
        }
        if (this.mounted) {
          setState(() {
            ready = true;
          });
        }
      }
    }).catchError((err) {
      _toast(err.toString());
      print("Get VForm Responses error: " + (err).toString());
    });
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
                value: "delete",
                child: Text(
                  "Delete",
                  style: TextStyle(
                    fontSize: font12,
                  ),
                ),
              ),
            ],
        onSelected: (selectedItem) async {
          switch (selectedItem) {
            case "delete":
              {
                _showVersionDialog(context, index);
              }
              break;
          }
        });
  }

  _showVersionDialog(context, int index) async {
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        String title =
            "Delete response #" + (int.parse(total) - index).toString();
        String message = "Are you sure you want to delete this response";
        return NDialog(
          dialogStyle: DialogStyle(titleDivider: true),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            FlatButton(
              child: Text("Yes"),
              onPressed: () => _delete(index),
            ),
            FlatButton(
              child: Text("No"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onBackPressAppBar() async {
    Navigator.pop(context);
    return Future.value(false);
  }
}
