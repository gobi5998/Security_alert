import 'package:flutter/material.dart';

class SpamDropdown extends StatefulWidget {
  @override
  _SpamDropdownState createState() => _SpamDropdownState();
}

class _SpamDropdownState extends State<SpamDropdown> {
  String? selectedSpamType;

  final List<String> spamTypes = [
    'Virus',
    'Worm',
    'Trojan',
    'Spyware',
    'Ransomware',
    'Adware',
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedSpamType,
      onChanged: (String? newValue) {
        setState(() {
          selectedSpamType = newValue;
        });
      },
      decoration: InputDecoration(
        labelText: 'Select a malware Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: spamTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
    );
  }
}