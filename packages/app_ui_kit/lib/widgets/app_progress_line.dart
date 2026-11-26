import "package:flutter/material.dart";

class AppProgressLine extends StatelessWidget {
  const AppProgressLine({super.key, this.value});
  final double? value;
  @override
  Widget build(BuildContext context) =>
      LinearProgressIndicator(value: value, minHeight: 3);
}
