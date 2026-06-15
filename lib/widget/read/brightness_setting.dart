import 'package:flutter/material.dart';
import 'package:read_app/pojo/settings.dart';
import 'package:read_app/utils/color_utils.dart';

class BrightnessSetting extends StatefulWidget {
  final Settings settings;
  
  const BrightnessSetting({super.key, required this.settings});

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
          decoration: BoxDecoration(
            color: ColorUtils.returnDefaultColor(widget.settings.backgroundColor),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          ),
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('亮度'),
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
