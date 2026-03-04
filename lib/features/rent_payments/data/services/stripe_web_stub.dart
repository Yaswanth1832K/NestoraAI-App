// ── Web stub for flutter_stripe ──────────────────────────────────
// Selected by: if (dart.library.html) 'stripe_web_stub.dart'
// Provides empty no-op stubs so the app compiles on web.
// ThemeMode is NOT redefined here — Flutter's material library owns it.

// ignore_for_file: avoid_classes_with_only_static_members
import 'package:flutter/material.dart' show ThemeMode;

class Stripe {
  static String publishableKey     = '';
  static String merchantIdentifier = '';
  static final Stripe instance     = Stripe._();
  Stripe._();

  Future<void> initPaymentSheet(
      {required SetupPaymentSheetParameters paymentSheetParameters}) async {}
  Future<void> presentPaymentSheet() async {}
}

class SetupPaymentSheetParameters {
  final String? paymentIntentClientSecret;
  final String? merchantDisplayName;
  final ThemeMode? style;
  final PaymentSheetAppearance? appearance;
  const SetupPaymentSheetParameters({
    this.paymentIntentClientSecret,
    this.merchantDisplayName,
    this.style,
    this.appearance,
  });
}

class PaymentSheetAppearance {
  final PaymentSheetAppearanceColors? colors;
  const PaymentSheetAppearance({this.colors});
}

class PaymentSheetAppearanceColors {
  final dynamic primary, background, componentBackground, componentText, placeholderText;
  const PaymentSheetAppearanceColors({
    this.primary, this.background,
    this.componentBackground, this.componentText, this.placeholderText,
  });
}

class StripeException implements Exception {
  final StripeError error;
  const StripeException(this.error);
}

class StripeError {
  final FailureCode code;
  const StripeError(this.code);
}

enum FailureCode { Canceled, Failed, Timeout }
