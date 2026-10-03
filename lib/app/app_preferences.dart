import 'package:flutter/material.dart';
import 'package:nthaka_eco/database/database_helper.dart';

abstract final class AppPreferences {
  static final themeMode = ValueNotifier(ThemeMode.system);
  static final currency = ValueNotifier('MWK');
  static final defaultPaymentMethod = ValueNotifier('Cash');
  static final receiptFooter = ValueNotifier('Thank you for your business.');
  static final saleFeedback = ValueNotifier(false);
  static final taxRate = ValueNotifier(17.5);

  static Future<void> load() async {
    themeMode.value = _themeFromValue(
      await DatabaseHelper.instance
          .getSetting('theme_mode', fallback: 'system'),
    );
    currency.value =
        await DatabaseHelper.instance.getSetting('currency', fallback: 'MWK');
    defaultPaymentMethod.value = await DatabaseHelper.instance
        .getSetting('default_payment_method', fallback: 'Cash');
    receiptFooter.value = await DatabaseHelper.instance
        .getSetting('receipt_footer', fallback: 'Thank you for your business.');
    saleFeedback.value = await DatabaseHelper.instance
            .getSetting('sale_feedback', fallback: 'false') ==
        'true';
    taxRate.value = double.tryParse(
          await DatabaseHelper.instance
              .getSetting('tax_rate', fallback: '17.5'),
        ) ??
        17.5;
  }

  static Future<void> setThemeMode(ThemeMode value) async {
    themeMode.value = value;
    await DatabaseHelper.instance.updateSetting('theme_mode', value.name);
  }

  static Future<void> setCurrency(String value) async {
    currency.value = value;
    await DatabaseHelper.instance.updateSetting('currency', value);
  }

  static Future<void> saveSalesSettings(
      {required String paymentMethod,
      required String footer,
      required bool feedback,
      required double tax}) async {
    defaultPaymentMethod.value = paymentMethod;
    receiptFooter.value = footer;
    saleFeedback.value = feedback;
    taxRate.value = tax;
    await Future.wait([
      DatabaseHelper.instance
          .updateSetting('default_payment_method', paymentMethod),
      DatabaseHelper.instance.updateSetting('receipt_footer', footer),
      DatabaseHelper.instance
          .updateSetting('sale_feedback', feedback.toString()),
      DatabaseHelper.instance.updateSetting('tax_rate', tax.toString()),
    ]);
  }

  static ThemeMode _themeFromValue(String value) => ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );
}
