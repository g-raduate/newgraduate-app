import Flutter
import UIKit

/// iOS Privacy Guard Plugin - حماية متقدمة للخصوصية على iOS
/// يوفر:
/// 1. حماية App Switcher (إخفاء المحتوى عند الخلفية)
/// 2. كشف Screen Recording و Screen Mirroring
/// 3. حماية من Screenshots
/// 4. Blur/Black Overlay عند الالتقاط
public class IOSPrivacyGuardPlugin: NSObject, FlutterPlugin {
    private var mainWindow: UIWindow?
    private var blurView: UIVisualEffectView?
    private var isProtectionEnabled = true
    private var captureNotificationObserver: NSObjectProtocol?
    private var screenshotObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var foregroundObserver: NSObjectProtocol?
    private var flutterMethodChannel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "ios_privacy_guard",
            binaryMessenger: registrar.messenger()
        )
        let instance = IOSPrivacyGuardPlugin()
        instance.flutterMethodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableProtection":
            enableProtection()
            result(nil)
        case "disableProtection":
            disableProtection()
            result(nil)
        case "isScreenBeingCaptured":
            result(checkIfScreenCaptured())
        case "setProtectionEnabled":
            if let args = call.arguments as? [String: Any],
               let enabled = args["enabled"] as? Bool {
                isProtectionEnabled = enabled
                if enabled {
                    enableProtection()
                } else {
                    disableProtection()
                }
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing enabled parameter", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// تفعيل جميع طرق الحماية
    private func enableProtection() {
        guard isProtectionEnabled else { return }
        
        // 1. مراقبة Screen Recording/Mirroring
        setupScreenCaptureMonitoring()
        
        // 2. مراقبة Screenshots
        setupScreenshotMonitoring()
        
        // 3. حماية App Switcher
        setupAppSwitcherProtection()
        
        // 4. فحص الحالة الحالية
        if checkIfScreenCaptured() {
            showProtectionOverlay()
        }
        
        print("✅ iOS Privacy Guard: تم تفعيل جميع الحمايات")
    }
    
    /// تعطيل الحماية
    private func disableProtection() {
        removeScreenCaptureMonitoring()
        removeScreenshotMonitoring()
        removeAppSwitcherProtection()
        hideProtectionOverlay()
        print("⚠️ iOS Privacy Guard: تم تعطيل الحماية")
    }
    
    // MARK: - Screen Recording/Mirroring Detection
    
    /// إعداد مراقبة التقاط الشاشة (تسجيل أو مرآة)
    private func setupScreenCaptureMonitoring() {
        guard #available(iOS 11.0, *) else { return }
        
        // إزالة المراقب القديم إن وجد
        if let observer = captureNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // مراقبة تغييرات حالة الالتقاط
        captureNotificationObserver = NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenCaptureChange()
        }
    }
    
    /// معالج تغيير حالة الالتقاط
    private func handleScreenCaptureChange() {
        guard #available(iOS 11.0, *) else { return }
        
        let isCaptured = UIScreen.main.isCaptured
        print("📱 iOS Privacy Guard: Screen capture state changed: \(isCaptured)")
        
        if isCaptured {
            showProtectionOverlay()
            // إرسال حدث لـ Flutter
            flutterMethodChannel?.invokeMethod("onScreenCaptureStarted", arguments: nil)
        } else {
            hideProtectionOverlay()
            // إرسال حدث لـ Flutter
            flutterMethodChannel?.invokeMethod("onScreenCaptureStopped", arguments: nil)
        }
    }
    
    /// فحص إذا كانت الشاشة قيد الالتقاط حالياً
    private func checkIfScreenCaptured() -> Bool {
        if #available(iOS 11.0, *) {
            return UIScreen.main.isCaptured
        }
        return false
    }
    
    private func removeScreenCaptureMonitoring() {
        if let observer = captureNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
            captureNotificationObserver = nil
        }
    }
    
    // MARK: - Screenshot Detection
    
    /// إعداد مراقبة لقطات الشاشة
    private func setupScreenshotMonitoring() {
        // إزالة المراقب القديم إن وجد
        if let observer = screenshotObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenshot()
        }
    }
    
    /// معالج عند أخذ لقطة شاشة
    private func handleScreenshot() {
        print("📸 iOS Privacy Guard: Screenshot detected!")
        
        // إظهار الحماية لفترة قصيرة (250ms)
        showProtectionOverlay()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            // إخفاء الحماية إذا لم يكن هناك تسجيل نشط
            if !self!.checkIfScreenCaptured() {
                self?.hideProtectionOverlay()
            }
        }
        
        // إرسال حدث لـ Flutter
        flutterMethodChannel?.invokeMethod("onScreenshotTaken", arguments: nil)
    }
    
    private func removeScreenshotMonitoring() {
        if let observer = screenshotObserver {
            NotificationCenter.default.removeObserver(observer)
            screenshotObserver = nil
        }
    }
    
    // MARK: - App Switcher Protection
    
    /// إعداد حماية معاينة App Switcher
    private func setupAppSwitcherProtection() {
        // إزالة المراقبين القدامى إن وجدوا
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // مراقبة الذهاب للخلفية
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppGoingToBackground()
        }
        
        // مراقبة العودة للواجهة
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppComingToForeground()
        }
    }
    
    /// معالج عند الذهاب للخلفية - إظهار الحماية
    private func handleAppGoingToBackground() {
        guard isProtectionEnabled else { return }
        print("⬇️ iOS Privacy Guard: App going to background - showing protection")
        showProtectionOverlay()
    }
    
    /// معالج عند العودة للواجهة - إخفاء الحماية إذا لم يكن هناك تسجيل
    private func handleAppComingToForeground() {
        print("⬆️ iOS Privacy Guard: App coming to foreground")
        
        // إخفاء الحماية فقط إذا لم يكن هناك تسجيل نشط
        if !checkIfScreenCaptured() {
            hideProtectionOverlay()
        }
    }
    
    private func removeAppSwitcherProtection() {
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
            backgroundObserver = nil
        }
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
            foregroundObserver = nil
        }
    }
    
    // MARK: - Protection Overlay Management
    
    /// إظهار طبقة الحماية (Blur أو Black)
    private func showProtectionOverlay() {
        guard isProtectionEnabled else { return }
        
        // الحصول على النافذة الرئيسية
        if mainWindow == nil {
            if #available(iOS 13.0, *) {
                mainWindow = UIApplication.shared.windows.first { $0.isKeyWindow }
            } else {
                mainWindow = UIApplication.shared.keyWindow
            }
        }
        
        guard let window = mainWindow else {
            print("⚠️ iOS Privacy Guard: Could not get main window")
            return
        }
        
        // إذا كانت طبقة الحماية موجودة مسبقاً، لا نفعل شيء
        if blurView != nil && blurView?.superview != nil {
            return
        }
        
        // إنشاء طبقة Blur
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 999999 // tag للتعرف عليها لاحقاً
        
        // إضافة طبقة سوداء فوق الـ Blur للحماية الإضافية
        let blackView = UIView(frame: blurEffectView.bounds)
        blackView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        blackView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.contentView.addSubview(blackView)
        
        // إضافة الطبقة للنافذة
        window.addSubview(blurEffectView)
        blurView = blurEffectView
        
        print("🛡️ iOS Privacy Guard: Protection overlay shown")
    }
    
    /// إخفاء طبقة الحماية
    private func hideProtectionOverlay() {
        blurView?.removeFromSuperview()
        blurView = nil
        
        // إزالة أي views بنفس الـ tag (احتياطي)
        if let window = mainWindow {
            window.subviews.filter { $0.tag == 999999 }.forEach { $0.removeFromSuperview() }
        }
        
        print("🔓 iOS Privacy Guard: Protection overlay hidden")
    }
    
    deinit {
        // تنظيف جميع المراقبين
        removeScreenCaptureMonitoring()
        removeScreenshotMonitoring()
        removeAppSwitcherProtection()
        hideProtectionOverlay()
    }
}
