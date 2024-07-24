import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:dac_pract/Bottamnav/Contacts.dart';
import 'package:dac_pract/Bottamnav/calls.dart';
import 'package:dac_pract/phone_state.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  static final List<Widget> _widgetOptions = <Widget>[
    CallLogScreen(),
    const LogsClass(title: 'Permission_Status'),
    const ContactScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page?.round() ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "C-DAC",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF002D56),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              children: _widgetOptions,
            ),
          ),
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        backgroundColor: Color(0xFF002D56),
        items: <TabItem>[
          TabItem(
            icon: Icons.call,
            title: 'Calls',
          ),
          TabItem(icon: Icons.message, title: 'SMS'),
          TabItem(icon: Icons.contacts, title: 'Contact'),
        ],
        onTap: (int index) {
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        },
        initialActiveIndex: _currentPage,
        style: TabStyle.reactCircle,
        height: 60,
      ),
    );
  }
}
