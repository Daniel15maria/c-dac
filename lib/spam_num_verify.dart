import 'dart:core';
import 'dart:developer';

String normalizePhoneNumber(String phoneNumber) {
  // Remove any non-digit characters (e.g., '+', '-', ' ')
  phoneNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
  // Remove country code if it starts with '91' or any other specific country code
  if (phoneNumber.startsWith('91')) {
    phoneNumber = phoneNumber.substring(2);
  }
  // Add more conditions for other country codes if needed
  return phoneNumber;
}

List<String> scamNumbers = [
  "+919360468002",
  "+442034567890",
  "+919345673812",
]; // Replace with your actual list

Future<void> reportSpamNumber(String phoneNumber) async {
  String normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
  bool isScam = scamNumbers.any((number) => normalizePhoneNumber(number) == normalizedPhoneNumber);

  if (isScam) {
    log('This number ($phoneNumber) is reported as a scam!');
  } else {
    log('This number ($phoneNumber) is not currently on the blacklist.');
  }
}

// Example usage
void main() {
  String incomingNumber = '+919360468002';
  reportSpamNumber(incomingNumber);
}
