import 'package:flutter/material.dart';
import 'phone_state_background_handler.dart';

class LogsClass extends StatefulWidget {
  const LogsClass({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<LogsClass> createState() => _LogsClassState();
}

class _LogsClassState extends State<LogsClass> {
  @override
  void initState() {
    super.initState();
    _startListenerAutomatically();
  }

  void _startListenerAutomatically() async {
    await PhoneStateBackgroundHandler.askForPermissionIfNeeded(context);
    if (PhoneStateBackgroundHandler.hasPermission) {
      await PhoneStateBackgroundHandler.fetchContactsAndInit();
      setState(() {
        // Update the UI to reflect the granted permission
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.grey),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Has Permission: ${PhoneStateBackgroundHandler.hasPermission}',
              style: TextStyle(
                fontSize: 16,
                color: PhoneStateBackgroundHandler.hasPermission
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (PhoneStateBackgroundHandler.hasPermission)
              Text(
                'Permission granted!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
