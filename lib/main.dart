import 'dart:core';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzdata.initializeTimeZones(); // Initialize time zones
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm Clock',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AlarmSettingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AlarmSettingScreen extends StatefulWidget {
  @override
  _AlarmSettingScreenState createState() => _AlarmSettingScreenState();
}

class _AlarmSettingScreenState extends State<AlarmSettingScreen> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _alarmEnabled = true;
  String _selectedAlarmTone = 'Default Tone';
  bool _isAlarmTime = false;

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Define the _alarms list
  List<Alarm> _alarms = [];

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
  }

  Future<void> _initializeLocalNotifications() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid, iOS: null);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  void _showAlarmTimeToast() async {
    if (_alarmEnabled) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final timeUntilAlarm = selectedDateTime.isBefore(now)
          ? selectedDateTime.add(Duration(days: 1)).difference(now)
          : selectedDateTime.difference(now);

      Fluttertoast.showToast(
        msg: 'Alarm set for ${_selectedTime.format(context)}\n'
            'Alarm will ring in ${timeUntilAlarm.inHours} hours and ${timeUntilAlarm.inMinutes.remainder(60)} minutes',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 5,
        backgroundColor: Colors.deepPurple,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Check if it's the alarm time
      if (timeUntilAlarm <= Duration(seconds: 0)) {
        setState(() {
          _isAlarmTime = true;
        });
      }

      // Schedule the alarm notification
      await _scheduleAlarmNotification(timeUntilAlarm);
    }
  }

  Future<void> _scheduleAlarmNotification(Duration timeUntilAlarm) async {
    final String timeZoneName = tz.local.name;

    final tz.TZDateTime scheduledTime =
    tz.TZDateTime.now(tz.getLocation(timeZoneName)).add(timeUntilAlarm);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'alarm_channel_id',
      'Alarm Notification',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Alarm Notification',
      'It\'s time for your alarm!',
      scheduledTime,
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Alarm'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Alarm Time:',
              style: TextStyle(fontSize: 18),
            ),
            ElevatedButton(
              onPressed: () {
                // Show a time picker and set the selected time
                showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                ).then((pickedTime) {
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                    });
                  }
                });
              },
              child: Text(
                '${_selectedTime.format(context)}',
                style: TextStyle(fontSize: 24),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Alarm Tone:',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: _selectedAlarmTone,
                  onChanged: (value) {
                    setState(() {
                      _selectedAlarmTone = value!;
                    });
                  },
                  items: ['Default Tone', 'Custom Tone 1', 'Custom Tone 2']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Enable Alarm:',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: 10),
                Switch(
                  value: _alarmEnabled,
                  onChanged: (value) {
                    setState(() {
                      _alarmEnabled = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save the alarm
                final newAlarm = Alarm(
                  time: _selectedTime,
                  tone: _selectedAlarmTone,
                  enabled: _alarmEnabled,
                );

                setState(() {
                  _alarms.add(newAlarm);
                });

                // Show the toast message
                _showAlarmTimeToast();

                // For demonstration, print the alarms
                print(_alarms);

                // Optionally, you can navigate back to the alarm management screen.
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class Alarm {
  final TimeOfDay time;
  final String tone;
  final bool enabled;

  Alarm({
    required this.time,
    required this.tone,
    required this.enabled,
  });
}
