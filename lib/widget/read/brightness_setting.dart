import 'package:flutter/material.dart';

class BrightnessSetting extends StatefulWidget {
  const BrightnessSetting({super.key});

  @override
  State<BrightnessSetting> createState() => _BrightnessSettingState();
}

class _BrightnessSettingState extends State<BrightnessSetting> {

  double brightness = 0.5;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: 70,
        left: 0,
        right: 0,
        child: Container(
          color: Colors.white,
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('亮度'),
              Slider(value: brightness, onChanged: (value) async {

                setState(() {
                  brightness = value;
                });
              })
            ],
          ),
        )
    );
  }
}
