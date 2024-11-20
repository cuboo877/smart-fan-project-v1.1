import 'package:fanishion_project_v1/constant/appColor.dart';
import 'package:fanishion_project_v1/constant/font.dart';
import 'package:fanishion_project_v1/pages/mapPage.dart';
import 'package:fanishion_project_v1/service/ble_controller.dart';
import 'package:fanishion_project_v1/widget/controlPageAppBar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  double _fixedValue = 1;
  double _circulateValue = 1;
  final double _autoValue = 1;
  Mode _mode = Mode.fixed;

  @override
  void initState() {
    super.initState();
    final controller = context.read<BleController>();
    controller.sendCommand(CommandType.speed, _fixedValue.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColor.accent,
          appBar: const ControlPageAppBar(),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    switch (_mode) {
                      Mode.fixed => basicModeWidget(context, controller),
                      Mode.circulate =>
                        circulateModeWidget(context, controller),
                      Mode.auto => autoModeWidget(context, controller),
                    },
                    modeSwitcher(context, controller),
                    findMyDeiceButton(context, controller),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget basicModeWidget(BuildContext context, BleController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
            color: AppColor.sub3, borderRadius: BorderRadius.circular(20)),
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "風速調節: ${_fixedValue.toInt()}",
              style: Font.h1,
            ),
            const SizedBox(height: 20),
            fixedSpeedSlider(context, controller),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("1"),
                Text("10"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget circulateModeWidget(BuildContext context, BleController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
            color: AppColor.sub3, borderRadius: BorderRadius.circular(20)),
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "循環風: ${circulateSpeed[_circulateValue.toInt() - 1]}",
              style: Font.h1,
            ),
            const SizedBox(height: 20),
            circulateSpeedSlider(context, controller),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("緩慢"),
                Text("頻繁"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget autoModeWidget(BuildContext context, BleController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
            color: AppColor.sub3, borderRadius: BorderRadius.circular(20)),
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "自動",
              style: Font.h1,
            ),
            Text(
              "目前溫度: ${controller.currentTemp}°C"
              "\n"
              "目前濕度: ${controller.currentHumidity}%",
              style: Font.subtitle,
            )
          ],
        ),
      ),
    );
  }

  Widget modeSwitcher(BuildContext context, BleController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.sub3,
          borderRadius: BorderRadius.circular(20),
        ),
        width: double.infinity,
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "模式",
              style: Font.h1,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth =
                    (constraints.maxWidth - 20) / 3; // 20是兩個間隔的總寬度
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildModeButton(
                      width: buttonWidth,
                      mode: Mode.fixed,
                      currentMode: _mode,
                      text: "固定",
                      controller: controller,
                    ),
                    _buildModeButton(
                      width: buttonWidth,
                      mode: Mode.circulate,
                      currentMode: _mode,
                      text: "循環",
                      controller: controller,
                    ),
                    _buildModeButton(
                      width: buttonWidth,
                      mode: Mode.auto,
                      currentMode: _mode,
                      text: "自動",
                      controller: controller,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isPressed = false;
  Widget findMyDeiceButton(BuildContext context, BleController controller) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.13,
      padding: const EdgeInsets.all(16.0),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          elevation: _isPressed ? 4 : 8,
          color: AppColor.base,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              _showRssiBottomSheet(context, controller);
            },
            child: Center(
              child: Text("我的裝置在哪裡?",
                  style: Font.h2.copyWith(color: AppColor.accent)),
            ),
          ),
        ),
      ),
    );
  }

  void _showRssiBottomSheet(BuildContext context, BleController controller) {
    Timer? timer;
    bool isSheetOpen = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColor.accent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            timer?.cancel();
            timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
              if (isSheetOpen) {
                controller.readRssi();
                setState(() {});
              }
            });

            return WillPopScope(
              onWillPop: () async {
                isSheetOpen = false;
                timer?.cancel();
                return true;
              },
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColor.base,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      "與裝置的距離",
                      style: Font.h2,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      controller.currentRssi != null
                          ? "${controller.currentRssi!.toInt().abs() - 70}"
                          : "...",
                      style: Font.h2.copyWith(color: AppColor.sub1),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColor.sub3,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "距離參考:",
                            style: Font.h2,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "0~50: 非常接近\n"
                            "50~120: 一段距離\n"
                            "123以上: 遙遠",
                            style: Font.subtitle.copyWith(color: AppColor.sub1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isSheetOpen = false;
      timer?.cancel();
    });
  }

  Widget _buildModeButton({
    required double width,
    required Mode mode,
    required Mode currentMode,
    required String text,
    required BleController controller,
  }) {
    return SizedBox(
      width: width,
      height: width,
      child: InkWell(
        onTap: () {
          switch (mode) {
            case Mode.fixed:
              controller.sendCommand(CommandType.speed, _fixedValue.toInt());
            case Mode.circulate:
              controller.sendCommand(
                  CommandType.circulate, _circulateValue.toInt());
            case Mode.auto:
              controller.sendCommand(CommandType.auto, _autoValue.toInt());
          }

          setState(() {
            _mode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _mode == mode ? AppColor.base : AppColor.accent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              text,
              style: Font.h2.copyWith(
                color: _mode == mode ? AppColor.accent : AppColor.sub1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget fixedSpeedSlider(BuildContext context, BleController controller) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        inactiveTrackColor: AppColor.accent, // 統一背景條顏色
        activeTrackColor: AppColor.accent, // 統一背景條顏色
        trackHeight: 7,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15.0),
        activeTickMarkColor: AppColor.sub1, // 統一刻度標記顏色
        inactiveTickMarkColor: AppColor.sub1, // 統一刻度標記顏色
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4.0),
        // 添加刻度標記
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(
        thumbColor: AppColor.base,
        value: _fixedValue,
        min: 1,
        max: 10,
        // 設置分割數量（點的數量-1）
        divisions: 9,
        // 顯示當前值
        label: _fixedValue.toInt().toString(),
        onChangeEnd: (value) {
          controller.sendCommand(CommandType.speed, value.toInt());
        },
        onChanged: (double value) {
          setState(() {
            _fixedValue = value;
          });
        },
      ),
    );
  }

  Widget circulateSpeedSlider(BuildContext context, BleController controller) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        inactiveTrackColor: AppColor.accent, // 統一背景條顏色
        activeTrackColor: AppColor.accent, // 統一背景條顏色
        trackHeight: 7,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15.0),
        activeTickMarkColor: AppColor.sub1, // 統一刻度標記顏色
        inactiveTickMarkColor: AppColor.sub1, // 統一刻度標記顏色
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 4.0),
        // 添加刻度標記
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(
        thumbColor: AppColor.base,
        value: _circulateValue,
        min: 1,
        max: 4,
        // 設置分割數量（點的數量-1）
        divisions: 3,
        // 顯示當前值
        label: _circulateValue.toInt().toString(),
        onChangeEnd: (value) {
          controller.sendCommand(CommandType.circulate, value.toInt());
        },
        onChanged: (double value) {
          setState(() {
            _circulateValue = value;
          });
        },
      ),
    );
  }
  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('風扇控制'),
  //       // 不需要監聽變化的操作直接使用 _bleController
  //       leading: IconButton(
  //         icon: const Icon(Icons.bluetooth_disabled),
  //         onPressed: () => _bleController.disconnect(),
  //       ),
  //     ),
  //     // 使用 Selector 只監聽需要的狀態
  //     body: Column(
  //       children: [
  //         // 監聽設備名稱
  //         Selector<BleController, String>(
  //           selector: (_, controller) =>
  //               controller.connectedDevice?.name ?? 'Unknown Device',
  //           builder: (context, deviceName, child) {
  //             return Text(deviceName);
  //           },
  //         ),
  //         // 監聽接收到的消息
  //         Selector<BleController, String>(
  //           selector: (_, controller) => controller.lastReceivedMessage,
  //           builder: (context, message, child) {
  //             return Text(message.isEmpty ? '等待訊息...' : message);
  //           },
  //         ),
  //         // 控制按鈕不需要監聽狀態變化
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //           children: [
  //             ElevatedButton(
  //               onPressed: () => _bleController.sendCommand('SpeedDown'),
  //               child: const Text('風速降低'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () => _bleController.sendCommand('SpeedUp'),
  //               child: const Text('風速增加'),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

enum Mode {
  fixed,
  circulate,
  auto,
}

List<String> circulateSpeed = ["緩慢", "中等", "快速", "頻繁"];
