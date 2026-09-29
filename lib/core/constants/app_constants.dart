import 'package:latlong2/latlong.dart';

/// App-wide constants (branding, contact info, map configuration, mock backend).
abstract final class AppConstants {
  static const String appName = 'Fakarni';
  static const String brandName = 'FAKARNI';
  static const String tagline = 'فكرني';
  static const String logoMarkAsset = 'assets/images/logo_mark.png'; // white brain-bubble mark
  static const String logoAsset = 'assets/images/logo.png';

  /// While the auth API is not wired, the sign-in button opens Home without
  /// validating the form. Set to `false` once authentication is implemented.
  static const bool skipAuth = true;

  // Footer / contact (footer.component.html)
  static const String contactAddress = '123 Care Street, City, Country';
  static const String contactPhone = '+1 234 567 8900';
  static const String contactEmail = 'info@grankare.com';
  static const String footerDescription =
      'Professional elderly care services provided with love and compassion. Your family is our family.';

  // Maps: same Esri tiles as the web app (no API key required).
  static const String mapTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  static const String mapAttribution = 'Tiles © Esri — Esri, HERE, Garmin, FAO, NOAA, USGS';
  static const String mapUserAgent = 'tn.esprit.fakarniapp';
  static const LatLng defaultMapCenter = LatLng(36.8065, 10.1815); // Tunis
  static const double defaultMapZoom = 13;

  // Limits copied from the web forms
  static const int postMaxLength = 2000;
  static const int postMinLength = 10;
  static const int commentMaxLength = 1000;
  static const int zoneRadiusMin = 50;
  static const int zoneRadiusMax = 5000;
}
