import 'package:fanishion_project_v1/constant/appColor.dart';
import 'package:fanishion_project_v1/constant/font.dart';
import 'package:fanishion_project_v1/pages/controlPage.dart';
import 'package:fanishion_project_v1/widget/scanPageAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../service/ble_controller.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isPressed = false;
  bool _isOnCooldown = false;
  late NavigatorState _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        return Scaffold(
          backgroundColor: AppColor.base,
          appBar: const ScanPageAppBar(),
          body: SafeArea(
            child: controller.status == ClientStatus.FoundDevices ||
                    controller.status == ClientStatus.Scanning ||
                    controller.status == ClientStatus.Connecting ||
                    controller.status == ClientStatus.ConnectionError
                ? Scrollbar(
                    radius: const Radius.circular(20),
                    interactive: true,
                    thumbVisibility: true,
                    thickness: 4,
                    scrollbarOrientation: ScrollbarOrientation.left,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: controller.scanResults.length,
                      itemBuilder: (context, index) {
                        final result = controller.scanResults[index];
                        return deviceWidget(context, controller, result);
                      },
                    ),
                  )
                : Center(
                    child: hintWidget(context, controller),
                  ),
          ),
          bottomNavigationBar: scanButton(context, controller),
        );
      },
    );
  }

  Widget hintWidget(BuildContext context, BleController controller) {
    if (controller.status == ClientStatus.BluetoothOff) {
      return Text(
        "您的手機尚未開啟藍牙\n請開啟藍牙已搜尋設備\n...",
        style: Font.subtitle.copyWith(color: AppColor.accent),
        textAlign: TextAlign.center,
      );
    }
    if (controller.status == ClientStatus.StandBy) {
      return Text(
        "確保開啟藍牙\n並且Fanshion設備開啟\n...",
        style: Font.subtitle.copyWith(color: AppColor.accent),
        textAlign: TextAlign.center,
      );
    }
    if (controller.status == ClientStatus.FoundNoDevices) {
      return Text(
        "找不到任何設備\n請確認設備是否開啟\n...",
        style: Font.subtitle.copyWith(color: AppColor.accent),
        textAlign: TextAlign.center,
      );
    }
    if (controller.status == ClientStatus.CancelConnection) {
      return Text(
        "已斷開連結\n請重新掃描設備\n...",
        style: Font.subtitle.copyWith(color: AppColor.accent),
        textAlign: TextAlign.center,
      );
    }
    return const SizedBox();
  }

  Widget deviceWidget(
      BuildContext context, BleController controller, ScanResult result) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: AppColor.accent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (controller.status == ClientStatus.Connecting &&
                controller.connectingDevice?.id == result.device.id) {
              controller.cancelConnecting();
              setState(() {
                controller.updateStatus(ClientStatus.FoundDevices);
              });
            } else if (controller.connectedDevice == result.device) {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ControlPage()));
            } else {
              await controller.connectToDevice(result.device);
              if (controller.connectedDevice != null) {
                _navigator.push(
                  MaterialPageRoute(builder: (context) => const ControlPage()),
                );
              }
            }
          },
          child: Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              titleAlignment: ListTileTitleAlignment.center,
              title: Text(
                result.device.name.isEmpty ? '未知裝置' : result.device.name,
                style: Font.title,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.device.id.toString(),
                      style: Font.subtitle.copyWith(color: AppColor.sub1)),
                  controller.connectedDevice == result.device
                      ? Text(
                          "連接中",
                          style: Font.body.copyWith(color: AppColor.green),
                        )
                      : controller.status == ClientStatus.Connecting &&
                              controller.connectingDevice == result.device
                          ? Text(
                              "嘗試連接...",
                              style: Font.body.copyWith(color: AppColor.sub2),
                            )
                          : const SizedBox(),
                ],
              ),
              trailing: controller.connectingDevice == result.device &&
                          controller.status == ClientStatus.Connecting ||
                      controller.status == ClientStatus.Connected ||
                      controller.connectedDevice == result.device
                  ? const Icon(
                      Icons.pause_circle_filled_outlined,
                      color: AppColor.base,
                    )
                  : const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColor.base,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget scanButton(BuildContext context, BleController controller) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.17,
      padding: const EdgeInsets.all(16.0),
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Material(
          elevation: _isPressed ? 4 : 8,
          color: _isOnCooldown
              ? AppColor.accent.withOpacity(0.75)
              : AppColor.accent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: () {
              if (controller.status == ClientStatus.Scanning) {
                // while scanning, cancel scanning is allowed
                controller.stopScan();
                setState(() {
                  _isOnCooldown = true; // set cooldown after stop scanning
                });
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _isOnCooldown =
                          false; // reset cooldown after 1 second, means the button is ready to be pressed
                    });
                  }
                });
              } else if (controller.status == ClientStatus.Connecting) {
                controller.cancelConnecting();
                setState(() {
                  controller.updateStatus(ClientStatus.FoundDevices);
                });
              } else if (_isOnCooldown) {
                // when it is on cooldown, we can't start scanning (But can be pressed)
                return;
              } else {
                controller
                    .startScan(); // when it is not on cooldown, and not scanning, we can start scanning
              }
            },
            child: Center(
              child: controller.status == ClientStatus.Scanning
                  ? Text(
                      "取消掃描",
                      style: Font.h1.copyWith(color: AppColor.red),
                    )
                  : controller.status == ClientStatus.Connecting
                      ? Text(
                          "中斷連接",
                          style: Font.h1.copyWith(color: AppColor.red),
                        )
                      : Text(
                          "掃描裝置",
                          style: Font.h1,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
