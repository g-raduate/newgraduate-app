import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomCard extends StatelessWidget {
  final String? imageUrl;
  final String? imagePath;
  final String title;
  final String? subtitle;
  final String? price;
  final bool showPrice;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;
  final double? width;
  final double? height;
  final Color? color;

  const CustomCard({
    super.key,
    this.imageUrl,
    this.imagePath,
    required this.title,
    this.subtitle,
    this.price,
    this.showPrice = false,
    this.onTap,
    this.decoration,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: decoration ??
            BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة البطاقة
            Expanded(
              flex: 2, // تقليل مساحة الصورة
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: _buildImage(),
                ),
              ),
            ),
            // محتوى البطاقة
            Expanded(
              flex: 3, // زيادة مساحة النص
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16, // زيادة حجم الخط
                        fontWeight: FontWeight.bold,
                        fontFamily: 'NotoKufiArabic',
                        height: 1.2, // تحسين المسافة بين الأسطر
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6), // زيادة المسافة
                      Expanded(
                        child: Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13, // زيادة حجم الخط قليلاً
                            color: Colors.grey[600],
                            fontFamily: 'NotoKufiArabic',
                            height: 1.3,
                          ),
                          maxLines: 2, // السماح بسطرين بدلاً من سطر واحد
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (showPrice && price != null) ...[
                      Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            price!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'NotoKufiArabic',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imagePath != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
              color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: imagePath!.toLowerCase().endsWith('.svg')
              ? SvgPicture.asset(
                  imagePath!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (context) => _buildPlaceholder(),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  ),
                ),
        ),
      );
    } else if (imageUrl != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
              color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: imageUrl!.toLowerCase().endsWith('.svg')
              ? SvgPicture.network(
                  imageUrl!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  placeholderBuilder: (context) => _buildPlaceholder(),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildPlaceholder();
                    },
                  ),
                ),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
              color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
            ],
          ),
        ),
        child: _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
            color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.school,
          size: 50,
          color: Colors.white,
        ),
      ),
    );
  }
}
