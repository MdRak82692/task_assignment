import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../common_widgets/custom_button.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: Stack(
          children: [
            PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: [
                _buildPage(
                  image: 'assets/images/onboarding1.png',
                  title: 'Discover the world, one journey at a time.',
                  description:
                      'From hidden gems to iconic destinations, we make travel simple, inspiring, and unforgettable. Start your next adventure today.',
                ),
                _buildPage(
                  image: 'assets/images/onboarding2.png',
                  title: 'Explore new horizons, one step at a time.',
                  description:
                      'Every trip holds a story waiting to be lived. Let us guide you to experiences that inspire, connect, and last a lifetime.',
                ),
                _buildPage(
                  image: 'assets/images/onboarding3.png',
                  title: 'See the beauty, one journey at a time.',
                  description:
                      'Travel made simple and exciting—discover places you\'ll love and moments you\'ll never forget.',
                ),
              ],
            ),

            // Skip Button
            Positioned(
              top: 50,
              right: 20,
              child: TextButton(
                onPressed: controller.skip,
                child: Text(
                  'Skip',
                  style: AppTextStyles.button.copyWith(color: Colors.white70),
                ),
              ),
            ),

            // Bottom Content
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Page Indicator
                  Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            3,
                            (index) => _buildIndicator(
                                index == controller.currentPage.value)),
                      )),
                  const SizedBox(height: 30),

                  // Next Button
                  CustomButton(
                    text: 'Next',
                    onPressed: controller.nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: 10,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.unselectedIndicator,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPage(
      {required String image,
      required String title,
      required String description}) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.displayMedium),
                const SizedBox(height: 20),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
