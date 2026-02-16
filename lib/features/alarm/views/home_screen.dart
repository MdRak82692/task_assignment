// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../controllers/alarm_controller.dart';
import '../../location/controllers/location_controller.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/alarm_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure LocationController is available
    final locationController = Get.find<LocationController>();
    final alarmController = Get.put(AlarmController());

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Text('Selected Location',
                  style: AppTextStyles.heading.copyWith(fontSize: 22)),
              const SizedBox(height: 20),

              // Location Display
              InkWell(
                onTap: locationController.requestLocation,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Row(
                    children: [
                      Obx(() => locationController.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white70),
                            )
                          : const Icon(Icons.location_on_outlined,
                              color: Colors.white70, size: 24)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Obx(() => Text(
                              locationController.address.value,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white54,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
              Text('Alarms',
                  style: AppTextStyles.heading.copyWith(fontSize: 22)),
              const SizedBox(height: 20),

              // Alarms List
              Expanded(
                child: Obx(() => alarmController.alarms.isEmpty
                    ? Center(
                        child: Text('No alarms set',
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: Colors.white54,
                              fontSize: 18,
                            )))
                    : ListView.builder(
                        itemCount: alarmController.alarms.length,
                        itemBuilder: (context, index) {
                          final alarm = alarmController.alarms[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Slidable(
                              key: ValueKey(alarm.id),
                              endActionPane: ActionPane(
                                extentRatio: 0.5,
                                motion: const StretchMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (_) {
                                      alarmController.pickDateTime(
                                        Get.context!,
                                        existingAlarm: alarm,
                                      );
                                    },
                                    backgroundColor: const Color(0xFF2D5CFF),
                                    foregroundColor: Colors.white,
                                    icon: Icons.edit_rounded,
                                    label: 'Edit',
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(30),
                                      bottomLeft: Radius.circular(30),
                                    ),
                                  ),
                                  SlidableAction(
                                    onPressed: (context) =>
                                        alarmController.deleteAlarm(alarm),
                                    backgroundColor: const Color(0xFFFF4B4B),
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_outline_rounded,
                                    label: 'Delete',
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(30),
                                      bottomRight: Radius.circular(30),
                                    ),
                                  ),
                                ],
                              ),
                              child: _buildAlarmCard(alarm, alarmController),
                            ),
                          );
                        },
                      )),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () => alarmController.pickDateTime(context),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildAlarmCard(AlarmModel alarm, AlarmController controller) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE d MMM yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Text(
            timeFormat.format(alarm.dateTime).toLowerCase(),
            style: AppTextStyles.bodyLarge.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            dateFormat.format(alarm.dateTime),
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 15),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: alarm.isEnabled,
              onChanged: (value) => controller.toggleAlarm(alarm),
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.black,
              inactiveTrackColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
