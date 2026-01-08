import 'package:flutter/material.dart';
import 'package:country_codes/country_codes.dart';

class CountryService {
  /// Fetches country details using the device locale.
  /// Returns a map with 'dial_code' and 'name', or defaults if detection fails.
  static Future<Map<String, String>> getCountryDetails() async {
    try {
      // CountryCodes.init() is called in main.dart, so we can just query now.
      // detailsForLocale() without arguments uses the device's detected locale.
      final details = CountryCodes.detailsForLocale();

      if (details != null) {
        return {
          'dial_code': details.dialCode ?? "+1",
          'name': details.name ?? "Unknown",
          'code': details.alpha2Code ?? "US",
        };
      }
    } catch (e) {
      debugPrint("Error detecting country: $e");
    }
    
    // Default fallback
    return {
      'dial_code': "+1", 
      'name': "United States",
      'code': "US"
    };
  }
}
