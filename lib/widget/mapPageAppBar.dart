import 'package:fanishion_project_v1/constant/appColor.dart';
import 'package:fanishion_project_v1/constant/font.dart';
import 'package:fanishion_project_v1/service/ble_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MapPageAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer<BleController>(
      builder: (context, controller, child) {
        return AppBar(
          backgroundColor: AppColor.base,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("正在尋找GPS的裝置:",
                  style: Font.title.copyWith(color: AppColor.accent)),
              Text(controller.connectedDevice?.name ?? "未知設備",
                  style: Font.body.copyWith(color: AppColor.accent)),
            ],
          ),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColor.accent),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          iconTheme: const IconThemeData(color: AppColor.accent),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
