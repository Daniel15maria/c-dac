import 'dart:typed_data';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';

class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailScreen({Key? key, required this.contact})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName ?? 'Contact Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.avatar != null && contact.avatar!.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    MemoryImage(Uint8List.fromList(contact.avatar!.toList())),
              )
            else
              CircleAvatar(
                radius: 40,
                child: Text(
                  contact.initials(),
                  style: TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
            SizedBox(height: 16),
            Text(
              'Name: ${contact.displayName ?? 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Phone: ${contact.phones?.isNotEmpty ?? false ? contact.phones!.first.value ?? 'N/A' : 'N/A'}',
              style: TextStyle(fontSize: 18),
            ),
            // Add more fields as needed
          ],
        ),
      ),
    );
  }
}
