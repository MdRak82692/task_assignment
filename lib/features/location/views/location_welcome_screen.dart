import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../common_widgets/custom_button.dart';
import '../controllers/location_controller.dart';

class LocationWelcomeScreen extends StatelessWidget {
  const LocationWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LocationController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Text(
              'Welcome! Your Smart\nTravel Alarm',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 15),
            Text(
              'Stay on schedule and enjoy every\nmoment of your journey.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge,
            ),
            const Spacer(),
            // Image Placeholder
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/images/location.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const Spacer(),

            // Use Current Location Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: controller.requestLocation,
                icon:
                    const Icon(Icons.location_on_outlined, color: Colors.white),
                label:
                    Text('Use Current Location', style: AppTextStyles.button),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Home Button
            CustomButton(
              text: 'Home',
              onPressed: controller.goToHome,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
