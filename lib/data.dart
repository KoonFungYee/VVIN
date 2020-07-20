import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

String ip = 'http://211.25.23.149/api/';
double font10 = ScreenUtil().setSp(23, allowFontScalingSelf: false);
double font11 = ScreenUtil().setSp(25.3, allowFontScalingSelf: false);
double font12 = ScreenUtil().setSp(27.6, allowFontScalingSelf: false);
double font13 = ScreenUtil().setSp(29.9, allowFontScalingSelf: false);
double font14 = ScreenUtil().setSp(32.2, allowFontScalingSelf: false);
double font15 = ScreenUtil().setSp(34.5, allowFontScalingSelf: false);
double font16 = ScreenUtil().setSp(36.8, allowFontScalingSelf: false);
double font18 = ScreenUtil().setSp(41.4, allowFontScalingSelf: false);
double font20 = ScreenUtil().setSp(46, allowFontScalingSelf: false);

class VDataInfo {
  List<VDataDetails> vDataList;
  int total;
  final String companyID,
      branchID,
      userID,
      level,
      userType,
      type,
      channel,
      apps,
      link_id,
      byStatus,
      byExecutive,
      byVTag,
      search,
      startDate,
      endDate;
  VDataInfo({
    this.companyID,
    this.branchID,
    this.userID,
    this.level,
    this.userType,
    this.type,
    this.channel,
    this.apps,
    this.link_id,
    this.byStatus,
    this.byExecutive,
    this.byVTag,
    this.search,
    this.startDate,
    this.endDate,
    this.total,
    this.vDataList,
  });
}

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

class CurrentIndex {
  int index;
  CurrentIndex({this.index});
}

class EditCompanyDetails {
  String companyID,
      branchID,
      userID,
      level,
      userType,
      image,
      name,
      phone,
      email,
      website,
      address;
  EditCompanyDetails(
      {this.companyID,
      this.branchID,
      this.userID,
      this.level,
      this.userType,
      this.image,
      this.name,
      this.phone,
      this.email,
      this.website,
      this.address});
}

class Noti {
  String title, subtitle, date, notiID, status, vdataStatus;
  Noti(
      {this.title,
      this.subtitle,
      this.date,
      this.notiID,
      this.status,
      this.vdataStatus});
}

class Myworks {
  String date, title, link, category, qr, urlName, id, branchID, branchName;
  bool offLine;
  List handlers;
  Myworks(
      {this.date,
      this.title,
      this.link,
      this.category,
      this.qr,
      this.urlName,
      this.offLine,
      this.id,
      this.handlers,
      this.branchID,
      this.branchName});
}

class TopView {
  String name, status, channel, views, phoneNo;
  TopView({this.name, this.status, this.channel, this.views, this.phoneNo});
}

class LeadData {
  String date, number;
  LeadData({this.date, this.number});
}

class VDataDetails {
  String companyID,
      branchID,
      userID,
      level,
      userType,
      branch,
      date,
      name,
      phoneNo,
      email,
      handler,
      remark,
      status,
      type,
      app,
      channel,
      link,
      fromVAnalytics;
  VDataDetails(
      {this.companyID,
      this.branchID,
      this.userID,
      this.level,
      this.userType,
      this.date,
      this.name,
      this.phoneNo,
      this.email,
      this.handler,
      this.remark,
      this.status,
      this.app,
      this.type,
      this.channel,
      this.link,
      this.fromVAnalytics});
}

class Link {
  String link, type;
  Link({this.link, this.type});
}

class VProfileData {
  String name,
      email,
      company,
      ic,
      dob,
      gender,
      position,
      industry,
      occupation,
      country,
      state,
      area,
      app,
      channel,
      created,
      lastActive,
      img,
      vformID;
  VProfileData(
      {this.name,
      this.email,
      this.company,
      this.ic,
      this.dob,
      this.gender,
      this.position,
      this.industry,
      this.occupation,
      this.country,
      this.state,
      this.area,
      this.app,
      this.channel,
      this.created,
      this.lastActive,
      this.img,
      this.vformID});
}

class Branch {
  String branchName, branchID;
  Branch({this.branchName, this.branchID});
}

class View {
  String date, link;
  View({this.date, this.link});
}

class Remarks {
  String date, remark, system;
  Remarks({this.date, this.remark, this.system});
}

class Gender {
  String gender;
  int position;
  Gender({this.gender, this.position});
}

class Handler {
  String handler, handlerID;
  List branches;
  int position;
  Handler({this.handler, this.handlerID, this.position, this.branches});
}

class Industry {
  String industry;
  int position;
  Industry({this.industry, this.position});
}

class Country {
  String country;
  int position;
  Country({this.country, this.position});
}

class States {
  String state;
  int position;
  States({this.state, this.position});
}

class NotificationDetail {
  String title, subtitle1, subtitle2;
  NotificationDetail({this.title, this.subtitle1, this.subtitle2});
}

class Links {
  String link_type, link, link_id;
  int position;
  Links({this.link_type, this.link, this.link_id, this.position});
}

class VDataFilter {
  String startDate, endDate, type, status, app, channel;
  VDataFilter(
      {this.startDate,
      this.endDate,
      this.type,
      this.status,
      this.app,
      this.channel});
}

class Setting {
  String assign, unassign, userID, companyID, branchID, level, userType;
  Setting(
      {this.assign,
      this.unassign,
      this.userID,
      this.companyID,
      this.branchID,
      this.level,
      this.userType});
}

class WhatsappForward {
  String url, userID, companyID, branchID, level, userType, branch;
  List vtagList;
  WhatsappForward(
      {this.url,
      this.userID,
      this.companyID,
      this.branchID,
      this.level,
      this.userType,
      this.branch,
      this.vtagList});
}

YYDialog YYAlertDialogWithScaleIn() {
  return YYDialog().build()
    ..width = ScreenUtil().setHeight(450)
    ..borderRadius = 4.0
    ..duration = Duration(milliseconds: 200)
    ..animatedFunc = (child, animation) {
      return ScaleTransition(
        child: child,
        scale: Tween(begin: 0.0, end: 1.0).animate(animation),
      );
    }
    ..text(
      alignment: Alignment.center,
      padding: EdgeInsets.all(18.0),
      text: "Close application?",
      color: Colors.black,
      fontSize: 14.0,
    )
    ..divider(color: Colors.grey)
    ..doubleButton(
      withDivider: true,
      gravity: Gravity.center,
      text1: "NO",
      onTap1: () {},
      color1: Colors.blue,
      fontSize1: 14.0,
      text2: "YES",
      onTap2: () {
        SystemNavigator.pop();
      },
      color2: Colors.blue,
      fontSize2: 14.0,
    )
    ..show();
}

class CustomAnimationWidget extends StatefulWidget {
  final AnimationController controller;
  final Widget child;

  const CustomAnimationWidget({Key key, this.controller, this.child})
      : super(key: key);

  @override
  _CustomAnimationWidgetState createState() => _CustomAnimationWidgetState();
}

class _CustomAnimationWidgetState extends State<CustomAnimationWidget> {
  static final Tween<Offset> tweenOffset = Tween<Offset>(
    begin: const Offset(0, 40),
    end: const Offset(0, 0),
  );

  static final Tween<double> tweenScale = Tween<double>(begin: 0.7, end: 1.0);
  Animation<double> animation;

  @override
  void initState() {
    animation =
        CurvedAnimation(parent: widget.controller, curve: Curves.decelerate);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      child: widget.child,
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return Transform.translate(
          offset: tweenOffset.evaluate(animation),
          child: Transform.scale(
            scale: tweenScale.evaluate(animation),
            child: Opacity(
              child: child,
              opacity: animation.value,
            ),
          ),
        );
      },
    );
  }
}
