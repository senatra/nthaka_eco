// form_button.dart

import 'package:flutter/material.dart';
import 'package:nthaka_eco/components/colors.dart';

class FormButton extends StatelessWidget {
  final String text;
  final Function? onPressed;
  const FormButton({this.text = '', this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

   return ElevatedButton(
  onPressed: onPressed as void Function()?,
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: screenHeight * .02),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    backgroundColor: kPrimaryColor
  ),
  child: Text(
    text,
    style: const TextStyle(fontSize: 16),
  ),
);
 
  }
}
