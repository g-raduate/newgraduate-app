import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/simple_theme_provider.dart';

class ColorPickerDialog extends StatelessWidget {
  const ColorPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: themeProvider.backgroundGradient,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'اختر لون التطبيق',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.all(15),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1,
                    ),
                    itemCount: SimpleThemeProvider.availableColors.length,
                    itemBuilder: (context, index) {
                      final colorEntry = SimpleThemeProvider
                          .availableColors.entries
                          .elementAt(index);
                      final colorName = colorEntry.key;
                      final color = colorEntry.value;
                      final isSelected =
                          themeProvider.primaryColor.value == color.value;

                      return GestureDetector(
                        onTap: () {
                          themeProvider.setPrimaryColor(color);
                          Navigator.of(context).pop();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            border: isSelected
                                ? Border.all(
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: isSelected ? 15 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (isSelected)
                                const Center(
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 30,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    colorName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'NotoKufiArabic',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // زر تبديل الوضع الليلي/النهاري
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: themeProvider.primaryGradient,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      themeProvider.toggleDarkMode();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Colors.white,
                    ),
                    label: Text(
                      themeProvider.isDarkMode
                          ? 'الوضع النهاري'
                          : 'الوضع الليلي',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'NotoKufiArabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'اضغط على اللون لتطبيقه على التطبيق',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: themeProvider.isDarkMode
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ويدجت زر اختيار الألوان
class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const ColorPickerDialog(),
            );
          },
          backgroundColor: themeProvider.primaryColor,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: themeProvider.primaryGradient,
            ),
            child: const Icon(
              Icons.palette,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

// ويدجت مؤشر اللون الحالي
class CurrentColorIndicator extends StatelessWidget {
  const CurrentColorIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: themeProvider.primaryGradient,
            shape: BoxShape.circle,
            border: Border.all(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: themeProvider.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        );
      },
    );
  }
}
