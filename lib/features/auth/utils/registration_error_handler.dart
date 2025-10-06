/// مساعد لمعالجة أخطاء التسجيل وتحويلها لرسائل واضحة للمستخدم
class RegistrationErrorHandler {
  /// تحليل الخطأ وإرجاع رسالة واضحة للمستخدم
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString();

    // خطأ 422 - بيانات غير صحيحة أو مكررة
    if (errorString.contains('HttpException(422)')) {
      // دعم رسائل Laravel المترجمة كـ validation.unique
      if (errorString.contains('validation.unique')) {
        if (errorString.contains('email')) {
          return 'البريد الإلكتروني مستخدم من قبل. يرجى استخدام بريد آخر.';
        }
        if (errorString.contains('phone')) {
          return 'رقم الهاتف مستخدم من قبل. يرجى استخدام رقم آخر.';
        }
      }
      if (errorString.contains('email') && errorString.contains('phone')) {
        return 'البريد الإلكتروني ورقم الهاتف مستخدمان من قبل. يرجى استخدام بيانات أخرى.';
      } else if (errorString.contains('email has already been taken') ||
          errorString.contains('البريد الإلكتروني مستخدم من قبل')) {
        return 'البريد الإلكتروني مستخدم من قبل. يرجى استخدام بريد إلكتروني آخر.';
      } else if (errorString.contains('phone has already been taken') ||
          errorString.contains('رقم الهاتف مستخدم من قبل')) {
        return 'رقم الهاتف مستخدم من قبل. يرجى استخدام رقم هاتف آخر.';
      } else {
        return 'البيانات المدخلة غير صحيحة. يرجى التحقق من صحة البيانات.';
      }
    }

    // خطأ 409 - تضارب في البيانات
    else if (errorString.contains('HttpException(409)')) {
      return 'يوجد حساب مسجل بهذا البريد الإلكتروني من قبل.';
    }

    // خطأ 500 - مشكلة في الخادم (عادة مشكلة البريد الإلكتروني)
    else if (errorString.contains('HttpException(500)')) {
      return 'خطأ مؤقت في الخادم. قد يكون حسابك تم إنشاؤه بنجاح ولكن رسالة التحقق لم ترسل. يرجى المحاولة لاحقاً أو التواصل مع الدعم الفني.';
    }

    // خطأ 400 - طلب غير صحيح
    else if (errorString.contains('HttpException(400)')) {
      return 'البيانات المرسلة غير صحيحة. يرجى التحقق من جميع الحقول.';
    }

    // خطأ في الاتصال
    else if (errorString.contains('SocketException') ||
        errorString.contains('NetworkException') ||
        errorString.contains('connection')) {
      return 'مشكلة في الاتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    }

    // خطأ في انتهاء المهلة الزمنية
    else if (errorString.contains('TimeoutException') ||
        errorString.contains('timeout')) {
      return 'انتهت المهلة الزمنية للطلب. يرجى المحاولة مرة أخرى.';
    }

    // خطأ عام
    else {
      return 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى أو التواصل مع الدعم الفني.';
    }
  }

  /// فحص ما إذا كان الخطأ قد يعني أن الحساب تم إنشاؤه رغم الخطأ
  static bool mightBeSuccessfulRegistration(dynamic error) {
    final errorString = error.toString();
    return errorString.contains('HttpException(500)') &&
        (errorString.contains('Sender Identity') ||
            errorString.contains('mail') ||
            errorString.contains('email'));
  }

  /// الحصول على نوع الخطأ للـ logging
  static String getErrorType(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('HttpException(422)')) {
      return 'VALIDATION_ERROR';
    } else if (errorString.contains('HttpException(409)')) {
      return 'CONFLICT_ERROR';
    } else if (errorString.contains('HttpException(500)')) {
      return 'SERVER_ERROR';
    } else if (errorString.contains('HttpException(400)')) {
      return 'BAD_REQUEST';
    } else if (errorString.contains('SocketException') ||
        errorString.contains('NetworkException')) {
      return 'NETWORK_ERROR';
    } else if (errorString.contains('TimeoutException')) {
      return 'TIMEOUT_ERROR';
    } else {
      return 'UNKNOWN_ERROR';
    }
  }
}
