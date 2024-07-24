import 'dart:async';
import 'dart:developer';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(
  PhoneStateBackgroundEvent event,
  String number,
  int duration,
) async {
  log('Received event: $event, number: $number, duration: $duration s');

  // Ensure contacts are available
  await PhoneStateBackgroundHandler.ensureContactsFetched();

  // Get the contact name associated with the incoming number
  String? contactName =
      await PhoneStateBackgroundHandler.getContactName(number);
  String contactStatus =
      contactName != null ? "Known: $contactName" : "Unknown";
  log('Contact status for number $number: $contactStatus');

  // Check if the number is in the spam list
  bool isSpam = await reportSpamNumber(number);

  // Show notification with spam status
  if (contactName == null) {
    String notificationMessage = isSpam
        ? 'Incoming call from $number (SPAM-ALERT)'
        : 'Incoming call from $number (Unknown)';
    await PhoneStateBackgroundHandler.showNotification('Unknown Number', notificationMessage);
  }

  // Handle different phone state events
  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
      log('Incoming call start, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.incomingmissed:
      log('Incoming call missed, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.incomingreceived:
      log('Incoming call received, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.incomingend:
      log('Incoming call ended, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.outgoingstart:
      log('Outgoing call start, number: $number, duration: $duration s ($contactStatus)');
      break;
    case PhoneStateBackgroundEvent.outgoingend:
      log('Outgoing call ended, number: $number, duration: $duration s ($contactStatus)');
      break;
  }
}

class PhoneStateBackgroundHandler {
  static bool hasPermission = false;
  static Map<String, Contact> _contactsMap = {};
  static bool _contactsFetched = false;
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> askForPermissionIfNeeded(BuildContext context) async {
    final permission = await PhoneStateBackground.checkPermission();
    if (!permission) {
      await PhoneStateBackground.requestPermissions();
      hasPermission = await PhoneStateBackground.checkPermission();
    } else {
      hasPermission = true;
    }

    if (hasPermission) {
      await _fetchContacts();
      _contactsFetched = true;
    }
  }

  static Future<void> ensureContactsFetched() async {
    if (!_contactsFetched) {
      log('Contacts not fetched yet. Fetching...');
      await _fetchContacts();
      _contactsFetched = true;
    }
  }

  static Future<void> fetchContactsAndInit() async {
    await ensureContactsFetched();
    await init();
    await initialize();
  }

  static Future<void> _fetchContacts() async {
    try {
      Iterable<Contact> contacts = await ContactsService.getContacts();
      log('Fetched ${contacts.length} contacts');

      _contactsMap = {
        for (var contact in contacts)
          for (var phone in contact.phones!)
            normalizePhoneNumber(phone.value!): contact
      };

      log('Normalized contacts fetched: ${_contactsMap.length}');
      _contactsMap.forEach((key, value) {
        log('Stored contact: $key -> ${value.displayName}');
      });

      if (_contactsMap.isEmpty) {
        log('No contacts fetched. Retrying...');
        await _fetchContacts();
      } else {
        log('Contacts fetched successfully');
      }
    } catch (e) {
      log('Error fetching contacts: $e');
    }
  }

  static String normalizePhoneNumber(String phoneNumber) {
    // Remove non-numeric characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // Handle various country codes
    if (normalized.length > 10) {
      normalized = normalized.substring(normalized.length - 10);
    }
    log('Normalized phone number: $normalized');
    return normalized;
  }

  static Future<String?> getContactName(String phoneNumber) async {
    String normalizedNumber = normalizePhoneNumber(phoneNumber);
    log('Looking up contact for normalized number: $normalizedNumber');
    if (_contactsMap.containsKey(normalizedNumber)) {
      Contact contact = _contactsMap[normalizedNumber]!;
      log('Found contact: ${contact.displayName} for number: $normalizedNumber');
      return contact.displayName;
    } else {
      log('No contact found for number: $normalizedNumber');
      return null;
    }
  }

  static Future<bool> isContact(String phoneNumber) async {
    String normalizedIncomingNumber = normalizePhoneNumber(phoneNumber);
    log('Normalized incoming number: $normalizedIncomingNumber');

    log('_contactsMap contents:');
    _contactsMap.forEach((number, contact) {
      log('  $number: ${contact.displayName}');
    });

    log('_contactsMap size: ${_contactsMap.length}');

    return _contactsMap.containsKey(normalizedIncomingNumber);
  }

  static Future<void> init() async {
    await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
  }

  static Future<void> stop() async {
    await PhoneStateBackground.stopPhoneStateBackground();
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'Your channel description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }
}

Future<bool> reportSpamNumber(String phoneNumber) async {
  List<String> scamNumbers = [
    "+919360468002",
    "+442034567890",
    "+919345673812",
  ]; // Replace with your actual list

  String normalizedPhoneNumber = PhoneStateBackgroundHandler.normalizePhoneNumber(phoneNumber);
  bool isScam = scamNumbers.any((number) =>
      PhoneStateBackgroundHandler.normalizePhoneNumber(number) == normalizedPhoneNumber);

  if (isScam) {
    log('This number ($phoneNumber) is reported as a scam!');
  } else {
    log('This number ($phoneNumber) is not currently on the blacklist.');
  }

  return isScam;
}
