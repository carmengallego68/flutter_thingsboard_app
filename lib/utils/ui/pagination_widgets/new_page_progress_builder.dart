import 'package:flutter/material.dart';

class NewPageProgressBuilder extends StatelessWidget {
  const NewPageProgressBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF091D30),
      child: const Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16,
      ),
      child: Center(
        child: RefreshProgressIndicator(),
      ),
    ),
    );
  }
}
