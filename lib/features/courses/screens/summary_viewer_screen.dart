import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:newgraduate/providers/simple_theme_provider.dart';
import 'package:newgraduate/services/user_info_service.dart';

class SummaryViewerScreen extends StatefulWidget {
  final Map<String, dynamic> summary;
  final String courseTitle;

  const SummaryViewerScreen({
    super.key,
    required this.summary,
    required this.courseTitle,
  });

  @override
  State<SummaryViewerScreen> createState() => _SummaryViewerScreenState();
}

class _SummaryViewerScreenState extends State<SummaryViewerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final link = widget.summary['link']?.toString();

    if (link == null || link.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'لا يوجد رابط متاح للملخص';
        _isLoading = false;
      });
      return;
    }

    final finalLink = _convertGoogleDriveLink(link);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // تفعيل التقريب والتكبير
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // يمكن إضافة مؤشر تقدم هنا
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // حقن JavaScript لمنع التحميل وإخفاء أزرار التحميل
            _webViewController.runJavaScript('''
              // إخفاء أزرار التحميل من Google Drive
              var downloadButtons = document.querySelectorAll('[aria-label*="download"], [title*="download"], [data-tooltip*="download"], .ndfHFb-c4YZDc-Wrql6b');
              downloadButtons.forEach(function(button) {
                button.style.display = 'none';
              });
              
              // منع النقر الأيمن
              document.addEventListener('contextmenu', function(e) {
                e.preventDefault();
                return false;
              });
              
              // منع اختصارات لوحة المفاتيح للتحميل
              document.addEventListener('keydown', function(e) {
                // منع Ctrl+S, Ctrl+Shift+S, Ctrl+P
                if (e.ctrlKey && (e.key === 's' || e.key === 'p')) {
                  e.preventDefault();
                  return false;
                }
              });
              
              // تحسين التقريب للجوال
              var meta = document.createElement('meta');
              meta.name = 'viewport';
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes';
              document.getElementsByTagName('head')[0].appendChild(meta);
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'فشل في تحميل الملخص: ${error.description}';
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // منع روابط التحميل المباشر
            if (request.url.contains('download') ||
                request.url.contains('/uc?') ||
                request.url.contains('export=download')) {
              print('🚫 تم منع محاولة التحميل: ${request.url}');
              _showDownloadBlocked();
              return NavigationDecision.prevent;
            }

            // حماية من التنقل - السماح فقط بالروابط المسموحة
            if (_isAllowedUrl(request.url)) {
              return NavigationDecision.navigate;
            } else {
              print('🚫 تم منع التنقل إلى: ${request.url}');
              _showNavigationBlocked(request.url);
              return NavigationDecision.prevent;
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(finalLink));
  }

  /// فحص ما إذا كان الرابط مسموحاً
  bool _isAllowedUrl(String url) {
    // قائمة المواقع المسموحة
    final allowedDomains = [
      'drive.google.com',
      'docs.google.com',
      'storage.googleapis.com',
      // يمكن إضافة مواقع أخرى حسب الحاجة
    ];

    try {
      final uri = Uri.parse(url);
      final domain = uri.host.toLowerCase();

      // السماح للنطاقات المعتمدة
      for (final allowedDomain in allowedDomains) {
        if (domain.contains(allowedDomain)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ خطأ في فحص الرابط: $e');
      return false;
    }
  }

  /// عرض تنبيه عند منع التنقل
  void _showNavigationBlocked(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.security, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('تم منع التنقل لحمايتك من المواقع غير الآمنة'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// عرض تنبيه عند منع التحميل
  void _showDownloadBlocked() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.block, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('تم منع التحميل - يمكنك فقط مشاهدة المحتوى'),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// تحويل رابط Google Drive للعرض المباشر
  String _convertGoogleDriveLink(String originalLink) {
    if (originalLink.contains('drive.google.com') &&
        originalLink.contains('/file/d/')) {
      RegExp regExp = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
      Match? match = regExp.firstMatch(originalLink);

      if (match != null) {
        String fileId = match.group(1)!;
        return 'https://drive.google.com/file/d/$fileId/preview';
      }
    }

    return originalLink;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.summary['title'] ?? 'الملخص',
              style: const TextStyle(
                fontFamily: 'NotoKufiArabic',
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.primaryGradient,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _buildBody(themeProvider),
        );
      },
    );
  }

  Widget _buildBody(SimpleThemeProvider themeProvider) {
    if (_hasError) {
      return _buildErrorView(themeProvider);
    }

    // الحصول على أبعاد الشاشة
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    // حساب الارتفاع بناءً على حجم الشاشة (10% من ارتفاع الشاشة)
    final blackBarHeight = screenHeight * 0.15;

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),

        // طبقة سوداء تتكيف مع أبعاد الشاشة
        Positioned(
          top: 0, // يبدأ من أعلى الشاشة
          left: 0,
          right: 0,
          height: blackBarHeight, // ارتفاع يتكيف مع حجم الشاشة
          child: Container(
            color: Colors.transparent,
          ),
        ),

        // Watermark رقم الطالب في الوسط
        Positioned.fill(
          child: FutureBuilder<String>(
            future: UserInfoService.getProtectionId(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Center(
                  child: Transform.rotate(
                    angle: -0.3, // زاوية الدوران قليلاً
                    child: Text(
                      snapshot.data!,
                      style: TextStyle(
                        fontSize:
                            screenHeight * 0.08, // حجم كبير متكيف مع الشاشة
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.withOpacity(0.3), // شفافية
                        fontFamily: 'NotoKufiArabic',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        if (_isLoading)
          Container(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.8)
                : Colors.white.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الملخص...',
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView(SimpleThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: themeProvider.backgroundGradient,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: themeProvider.isDarkMode ? Colors.red[300] : Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                'فشل في تحميل الملخص',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty ? _errorMessage : 'حدث خطأ غير متوقع',
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.isDarkMode
                      ? Colors.white70
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  _initializeWebView();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'العودة',
                  style: TextStyle(
                    color: themeProvider.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
