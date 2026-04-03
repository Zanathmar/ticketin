class ApiConstants {
  // ─── PICK THE RIGHT URL FOR YOUR SETUP ───────────────────────────────────
  //
  // ✅ Chrome / Flutter Web (same machine as Laravel):
  //    static const baseUrl = 'http://127.0.0.1:8000/api';
  //
  // ✅ Android Emulator (AVD/Genymotion):
  //    static const baseUrl = 'http://10.0.2.2:8000/api';
  //
  // ✅ Physical Android device (same WiFi, run: ipconfig getifaddr en0):
  //    static const baseUrl = 'http://192.168.1.x:8000/api';
  //
  // ✅ iOS Simulator:
  //    static const baseUrl = 'http://127.0.0.1:8000/api';
  //
  // ─────────────────────────────────────────────────────────────────────────
  // 👇 Change this to match your current target:
  static const baseUrl = 'http://127.0.0.1:8000/api';

  // Auth
  static const register = '/register';
  static const login = '/login';
  static const logout = '/logout';
  static const me = '/me';

  // Events
  static const events = '/events';
  static String eventById(int id) => '/events/$id';
  static String eventAttendees(int id) => '/events/$id/attendees';
  static String eventRegister(int id) => '/events/$id/register';
  static String eventQrCode(int id) => '/events/$id/qr-code';

  // My registrations
  static const myRegistrations = '/my-registrations';

  // Check-in / Check-out
  static const checkIn = '/check-in';
  static const checkOut = '/check-out';
}

class AppStrings {
  static const appName = 'Ticketin';
  static const tagline = 'Your events, simplified.';
}
