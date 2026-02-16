import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../controllers/alarm_controller.dart';
import '../../location/controllers/location_controller.dart';
import '../models/alarm_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure LocationController is available
    final locationController = Get.find<LocationController>();
    final alarmController = Get.put(AlarmController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Selected Location', style: AppTextStyles.subHeading),
              const SizedBox(height: 15),

              // Location Display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Obx(() => Text(
                            locationController.address.value,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          )),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Text('Alarms', style: AppTextStyles.subHeading),
              const SizedBox(height: 15),

              // Alarms List
              Expanded(
                child: Obx(() => alarmController.alarms.isEmpty
                    ? Center(
                        child: Text('No alarms set',
                            style: AppTextStyles.bodySmall))
                    : ListView.builder(
                        itemCount: alarmController.alarms.length,
                        itemBuilder: (context, index) {
                          final alarm = alarmController.alarms[index];
                          return _buildAlarmCard(alarm, alarmController);
                        },
                      )),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => alarmController.pickDateTime(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildAlarmCard(AlarmModel alarm, AlarmController controller) {
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('EEE d MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timeFormat.format(alarm.dateTime),
                style: AppTextStyles.subHeading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 5),
              Text(
                dateFormat.format(alarm.dateTime),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          Switch(
            value: alarm.isEnabled,
            onChanged: (value) => controller.toggleAlarm(alarm),
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.primary.withOpacity(0.5),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
