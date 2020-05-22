import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sk_onboarding_screen/flutter_onboarding.dart';
import 'package:sk_onboarding_screen/sk_onboarding_screen.dart';
import 'package:vvin/data.dart';
import 'package:vvin/vanalytics.dart';

class OnBoarding extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _globalKey = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    initial();
    super.initState();
  }

  Future<void> initial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('first', '1');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressAppBar,
      child: Scaffold(
        key: _globalKey,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: AppBar(
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        body: SKOnboardingScreen(
          bgColor: Colors.white,
          themeColor: const Color(0xFFf74269),
          pages: pages,
          skipClicked: (value) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VAnalytics(),
              ),
            );
          },
          getStartedClicked: (value) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VAnalytics(),
              ),
            );
          },
        ),
      ),
    );
  }

  final pages = [
    SkOnboardingModel(
        title: 'New Features added',
        description: 'Add Reminder, Save Contact, Scan Name Card, Open Map',
        titleColor: Colors.black,
        descripColor: const Color(0xFF929794),
        imagePath: 'assets/images/onboard2.png'),
    SkOnboardingModel(
        title: 'Add Reminder',
        description: 'Setup a reminder',
        titleColor: Colors.black,
        descripColor: const Color(0xFF929794),
        imagePath: 'assets/images/onboard4.png'),
    SkOnboardingModel(
        title: 'Reminder List',
        description: 'View all the reminders',
        titleColor: Colors.black,
        descripColor: const Color(0xFF929794),
        imagePath: 'assets/images/onboard1.png'),
    SkOnboardingModel(
        title: 'Open Map',
        description: 'Open map application and search for company name',
        titleColor: Colors.black,
        descripColor: const Color(0xFF929794),
        imagePath: 'assets/images/onboard3.png'),
  ];

  Future<bool> _onBackPressAppBar() async {
    YYAlertDialogWithScaleIn();
    return Future.value(false);
  }
}
