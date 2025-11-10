import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:iiuc_bazaar/Auth/SignUpUIOne.dart';

class SignUpBodyScreen extends StatelessWidget {
  const SignUpBodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.green,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(0, 400, 0, 0),
          shrinkWrap: true,
          reverse: true,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 535,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: HexColor("#ffffff"),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                      ),
                      // Directly call SignUpOne widget here
                      child: SignUpOne(),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -253),
                      child: Image.asset(
                        'assets/images/plants2.png',
                        scale: 1.5,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
