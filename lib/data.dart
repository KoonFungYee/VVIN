import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_dialog/flutter_custom_dialog.dart';

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
  String companyID, userID, level, userType, image, name, phone, email, website, address;
  EditCompanyDetails(
      {this.companyID,
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
  String title, subtitle, date, notiID, status;
  Noti({this.title, this.subtitle, this.date, this.notiID, this.status});
}

class Myworks {
  String date, title, link, category, qr, url, urlName, id, priority;
  bool offLine;
  List handlers;
  Myworks({this.date, this.title, this.link, this.category, this.qr, this.url, this.urlName, this.offLine, this.id, this.handlers, this.priority});
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
      userID,
      level,
      userType,
      date,
      name,
      phoneNo,
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
      this.userID,
      this.level,
      this.userType,
      this.date,
      this.name,
      this.phoneNo,
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
      img;
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
      this.img});
}

class View{
  String date, link;
  View({this.date, this.link});
}

class Remarks{
  String date, remark, system;
  Remarks({this.date, this.remark, this.system});
}

class Gender{
  String gender;
  int position;
  Gender({this.gender, this.position});
}

class Handler{
  String handler, handlerID;
  int position;
  Handler({this.handler, this.handlerID, this.position});
}

class Industry{
  String industry;
  int position;
  Industry({this.industry, this.position});
}

class Country{
  String country;
  int position;
  Country({this.country, this.position});
}

class States{
  String state;
  int position;
  States({this.state, this.position});
}

class NotificationDetail{
  String title, subtitle1, subtitle2;
  NotificationDetail({this.title, this.subtitle1, this.subtitle2});
}

class Links{
  String link_type, link, link_id;
  int position;
  Links({this.link_type, this.link, this.link_id, this.position});
}

class VDataFilter{
  String startDate, endDate, type, status, app, channel;
  VDataFilter({this.startDate, this.endDate, this.type, this.status, this.app, this.channel});
}

class Setting{
  String assign, unassign, userID, companyID, level, userType;
  Setting({this.assign, this.unassign, this.userID, this.companyID, this.level, this.userType});
}

class WhatsappForward{
  String url, userID, companyID, level, userType;
  List vtagList;
  WhatsappForward({this.url, this.userID, this.companyID, this.level, this.userType, this.vtagList});
}

YYDialog YYAlertDialogWithScaleIn() {
  return YYDialog().build()
    ..width = 240
    ..borderRadius = 4.0
    ..duration = Duration(milliseconds: 200)
    ..animatedFunc = (child, animation) {
      return ScaleTransition(
        child: child,
        scale: Tween(begin: 0.0, end: 1.0).animate(animation),
      );
    }
    ..text(
      padding: EdgeInsets.all(18.0),
      text: "Are you sure you want to close application?",
      color: Colors.black,
      fontSize: 14.0,
    )
    ..doubleButton(
      padding: EdgeInsets.only(top: 24.0),
      gravity: Gravity.center,
      text1: "NO",
      onTap1: () {
      },
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
