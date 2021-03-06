import 'package:awesome_page_transitions/awesome_page_transitions.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:bouncing_widget/bouncing_widget.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_open_whatsapp/flutter_open_whatsapp.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:menu_button/menu_button.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:route_transitions/route_transitions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vvin/animator.dart';
import 'package:vvin/data.dart';
import 'package:vvin/vprofile.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:empty_widget/empty_widget.dart';
import 'dart:convert';
import 'package:vvin/whatsappForward.dart';

class VDataStatus extends StatefulWidget {
  VDataInfo vdataInfo;
  VDataStatus({Key key, this.vdataInfo}) : super(key: key);

  @override
  _VDataStatusState createState() => _VDataStatusState();
}

class _VDataStatusState extends State<VDataStatus> {
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);
  final TextEditingController _dialogSearchController = TextEditingController();
  String urlVData = ip + "vdata.php";
  String urlChangeStatus = ip + "vdataChangeStatus.php";
  String urlMyWorks = ip + "myWorks2.php";
  String urlVTag = ip + "vtag.php";
  List<VDataDetails> vDataDetails = [];
  List<Map> offlineVData;
  List<Myworks> myWorks = [];
  List<Myworks> myWorks1 = [];
  List<RadioItem> radioItems = [];
  List vtagList = [];
  List vTag;
  double _scaleFactor = 1.0;
  String companyID,
      branchID,
      userID,
      level,
      userType,
      type,
      channel,
      apps,
      link_id,
      _byStatus,
      _byExecutive,
      _byVTag,
      _byBranch,
      search,
      startDate,
      endDate;
  bool vDataReady, nodata, myworksReady, vTagData;
  int total, totalLink;
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
    companyID = widget.vdataInfo.companyID;
    branchID = widget.vdataInfo.branchID;
    userID = widget.vdataInfo.userID;
    level = widget.vdataInfo.level;
    userType = widget.vdataInfo.userType;
    type = widget.vdataInfo.type;
    channel = widget.vdataInfo.channel;
    apps = widget.vdataInfo.apps;
    link_id = widget.vdataInfo.link_id;
    _byStatus = widget.vdataInfo.byStatus;
    _byExecutive = widget.vdataInfo.byExecutive;
    _byVTag = widget.vdataInfo.byVTag;
    search = widget.vdataInfo.search;
    startDate = widget.vdataInfo.startDate;
    endDate = widget.vdataInfo.endDate;
    total = widget.vdataInfo.total;
    vDataDetails = widget.vdataInfo.vDataList;
    totalLink = 0;
    vTagData = myworksReady = nodata = false;
    vDataReady = true;
    getLink();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 750, height: 1334, allowFontScaling: false);
    double remark = MediaQuery.of(context).size.width * 0.30;
    double cWidth = MediaQuery.of(context).size.width * 0.30;
    return Scaffold(
      backgroundColor: Color.fromRGBO(235, 235, 255, 1),
      body: (vDataReady == true)
          ? (nodata == true)
              ? Center(
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: EmptyListWidget(
                        packageImage: PackageImage.Image_2,
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
                )
              : SmartRefresher(
                  enablePullDown: true,
                  enablePullUp: (vDataDetails.length != total) ? true : false,
                  header: MaterialClassicHeader(),
                  footer: CustomFooter(
                    builder: (BuildContext context, LoadStatus mode) {
                      Widget body;
                      if (mode == LoadStatus.idle) {
                        body = SpinKitRing(
                          lineWidth: 2,
                          color: Colors.blue,
                          size: 20.0,
                          duration: Duration(milliseconds: 600),
                        );
                      } else if (mode == LoadStatus.loading) {
                        body = SpinKitRing(
                          lineWidth: 2,
                          color: Colors.blue,
                          size: 20.0,
                          duration: Duration(milliseconds: 600),
                        );
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
                    itemCount: vDataDetails.length,
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
                                              vDataDetails[index].date,
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
                                                          vDataDetails[index]
                                                              .name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.blue,
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
                                                          vDataDetails[index]
                                                              .phoneNo,
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
                                                width:
                                                    ScreenUtil().setWidth(10)),
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
                                                          vDataDetails[index]
                                                              .handler,
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
                                                                FontWeight
                                                                    .w600),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: <Widget>[
                                                      Flexible(
                                                        child: Text(
                                                          vDataDetails[index]
                                                              .remark,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontSize: font12,
                                                              color:
                                                                  Colors.grey),
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
                                              launch("tel:+" +
                                                  vDataDetails[index].phoneNo);
                                            },
                                            child: Container(
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setWidth(98),
                                              child: Icon(
                                                Icons.call,
                                                size: ScreenUtil()
                                                    .setHeight(32.2),
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
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setWidth(98),
                                              child: Icon(
                                                FontAwesomeIcons.whatsapp,
                                                color: Colors.white,
                                                size: ScreenUtil()
                                                    .setHeight(32.2),
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
                                              height:
                                                  ScreenUtil().setHeight(60),
                                              width: ScreenUtil().setWidth(98),
                                              child: Icon(
                                                Icons.email,
                                                color: Colors.white,
                                                size: ScreenUtil()
                                                    .setHeight(32.2),
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
                                      menuButton(
                                          vDataDetails[index].status, index),
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
          : Container(
              height: MediaQuery.of(context).size.height * 0.6,
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
    );
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
      ..width = MediaQuery.of(context).size.width * 0.85
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

  void _redirectWhatsApp(int index) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
        FlutterOpenWhatsapp.sendSingleMessage(vDataDetails[index].phoneNo, "");
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
      ..width = MediaQuery.of(context).size.width * 0.85
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

  void _redirectVProfile(int index) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      VDataDetails vdata = new VDataDetails(
        companyID: companyID,
        branchID: branchID,
        userID: userID,
        level: level,
        userType: userType,
        name: vDataDetails[index].name,
        phoneNo: vDataDetails[index].phoneNo,
        email: vDataDetails[index].email,
        status: vDataDetails[index].status,
      );
      Navigator.of(context).push(PageRouteTransition(
          animationType: AnimationType.scale,
          builder: (context) => VProfile(vdata: vdata)));
    } else {
      _toast("No Internet Connection!");
    }
  }

  void _onRefresh() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.mobile) {
      if (this.mounted) {
        setState(() {
          vDataReady = false;
          nodata = false;
        });
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
        "start_date": startDate,
        "end_date": endDate,
        "count": "0",
        "offline": "no"
      }).then((res) {
        // print("Refresh vdata body: " + res.body.toString());
        if (res.body == "nodata") {
          if (this.mounted) {
            setState(() {
              nodata = true;
              vDataReady = true;
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
              vDataReady = true;
            });
          }
        }
      }).catchError((err) {
        print("Get refresh vdataAll error: " + (err).toString());
      });
      _refreshController.refreshCompleted();
    } else {
      _toast("No Internet connection, data can't load");
      _refreshController.refreshCompleted();
    }
  }

  void _onLoading() {
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
      "count": vDataDetails.length.toString(),
      "offline": "no"
    }).then((res) {
      // print("Get More VData body: " + res.body.toString());
      if (res.body == "nodata") {
        if (this.mounted) {
          setState(() {
            vDataReady = true;
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
          vDataDetails.add(vdata);
        }
        if (this.mounted) {
          setState(() {
            total = jsonData[0]['total'];
            vDataReady = true;
          });
        }
      }
    }).catchError((err) {
      print("Get more data error: " + (err).toString());
    });
    _refreshController.loadComplete();
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
        setStatus(index, status);
      },
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: const BorderRadius.all(Radius.circular(3.0)),
          color: Colors.white),
      onMenuButtonToggle: (isToggle) {},
    );
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
}
