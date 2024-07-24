import 'dart:async';
import 'dart:typed_data';
import 'package:dac_pract/Bottamnav/ContactsDetilScreen.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static List<Contact> _contacts = [];
  static Map<String, Contact> _contactsMap = {};
  static bool _contactsFetched =
      false; // Flag to check if contacts are already fetched
  final _contactsStreamController = StreamController<List<Contact>>.broadcast();
  bool isFilterApplied = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _contactsStreamController.close();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    // Request contacts permission
    PermissionStatus permissionStatus = await Permission.contacts.request();
    if (permissionStatus == PermissionStatus.granted) {
      await _fetchContacts(); // Fetch contacts immediately after permission is granted
    } else {
      // Handle permission denied
      print('Contacts permission denied');
    }
  }

  Future<void> _fetchContacts() async {
    try {
      // Check and request permission before fetching contacts
      PermissionStatus permissionStatus = await Permission.contacts.status;
      if (permissionStatus.isGranted) {
        // Fetch contacts only if they haven't been fetched before
        if (!_contactsFetched) {
          Iterable<Contact> contacts =
              await ContactsService.getContacts(withThumbnails: true);
          _contacts = contacts.toList();
          _contactsFetched = true;

          // Create a map of normalized phone numbers to contacts
          _contactsMap = {
            for (var contact in _contacts)
              for (var phone in contact.phones!)
                _normalizePhoneNumber(phone.value!): contact
          };

          _contactsStreamController.sink.add(_contacts);
        } else {
          // Emit cached contacts
          _contactsStreamController.sink.add(_contacts);
        }
      } else {
        // Request permission if not granted
        await _requestPermission();
      }
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  String _normalizePhoneNumber(String phoneNumber) {
    // Remove non-numeric characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // Remove leading country code if present
    if (normalized.length > 10 &&
        (normalized.startsWith('91') || normalized.startsWith('+91'))) {
      normalized = normalized.substring(normalized.length - 10);
    }
    return normalized;
  }

  void _updateContacts() async {
    try {
      // Fetch updated contacts
      Iterable<Contact> updatedContacts =
          await ContactsService.getContacts(withThumbnails: true);
      List<Contact> updatedContactsList = updatedContacts.toList();

      // Update the _contactsMap with the new contacts
      _contactsMap = {
        for (var contact in updatedContactsList)
          for (var phone in contact.phones!)
            _normalizePhoneNumber(phone.value!): contact
      };

      // Update the _contacts list
      _contacts = updatedContactsList;

      // Notify listeners about the updated contacts
      _contactsStreamController.sink.add(_contacts);
    } catch (e) {
      print('Error updating contacts: $e');
    }
  }

  void _clearFilter() {
    setState(() {
      isFilterApplied = false;
      searchQuery = ''; // Clear search query
    });
    _contactsStreamController.sink
        .add(_contacts); // Reset the stream to show all contacts
  }

  void _applyFilter(String query) {
    setState(() {
      searchQuery = query;
      isFilterApplied = true;
    });

    // Filter contacts based on the search query
    List<Contact> filteredContacts = _contacts.where((contact) {
      return contact.displayName?.toLowerCase().contains(query.toLowerCase()) ??
          false;
    }).toList();

    _contactsStreamController.sink.add(filteredContacts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContactSearchDelegate(
                  onSearch: _applyFilter,
                  onClear: _clearFilter,
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.grey,
        child: StreamBuilder<List<Contact>>(
          stream: _contactsStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Contact> contacts = snapshot.data!;
              return ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  Contact contact = contacts[index];
                  return Card(
                    elevation: 4.0,
                    margin:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10.0),
                      leading: CircleAvatar(
                        backgroundColor: Colors.black,
                        backgroundImage: contact.avatar != null &&
                                contact.avatar!.isNotEmpty
                            ? MemoryImage(
                                Uint8List.fromList(contact.avatar!.toList()))
                            : null,
                        child:
                            (contact.avatar == null || contact.avatar!.isEmpty)
                                ? Text(
                                    contact.displayName?.isNotEmpty ?? false
                                        ? contact.initials()
                                        : 'NA',
                                    style: TextStyle(color: Colors.white),
                                  )
                                : null,
                      ),
                      title: Text(contact.displayName ?? ''),
                      subtitle: Text(
                        contact.phones?.isNotEmpty ?? false
                            ? contact.phones!.first.value ?? ''
                            : '',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ContactDetailScreen(contact: contact),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class ContactSearchDelegate extends SearchDelegate {
  final Function(String) onSearch;
  final Function() onClear;

  ContactSearchDelegate({required this.onSearch, required this.onClear});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          onClear(); // Clear the filter
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // Not used in this implementation
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView.builder(
      itemCount: query.isEmpty ? 0 : 1, // Show suggestions based on the query
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(query),
          onTap: () {
            onSearch(query); // Apply the filter
            close(context, null);
          },
        );
      },
    );
  }
}
