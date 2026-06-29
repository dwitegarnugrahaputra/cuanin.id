import 'package:get/get.dart';

/// Menyimpan data staf (kasir / admin stok) yang sedang login,
/// di memori, selama aplikasi berjalan.
///
/// Dibutuhkan karena login di app ini TIDAK memakai Supabase Auth
/// (auth.signInWithPassword) — melainkan validasi manual ke tabel
/// `staff` (email + password plain text). Akibatnya `supabase.auth.currentUser`
/// selalu null, jadi data staf yang login harus disimpan sendiri di sini
/// dan dibaca oleh halaman lain (misalnya drawer profil di HomeView).
///
/// Didaftarkan permanent (Get.put(..., permanent: true)) sekali saat
/// login sukses, supaya tidak ke-dispose saat navigasi antar halaman
/// (Get.offAllNamed menghapus semua controller non-permanent).
class SessionController extends GetxController {
  var staffId = ''.obs;
  var ownerUserId = ''.obs;
  var staffName = 'Kasir'.obs;
  var staffEmail = '-'.obs;
  var staffImageUrl = ''.obs;
  var staffStatus = ''.obs;
  var staffRole = ''.obs; // 'kasir' atau 'admin_stok'

  bool get isLoggedIn => staffId.value.isNotEmpty;

  /// Dipanggil oleh LoginController begitu validasi staff berhasil,
  /// sebelum Get.offAllNamed ke halaman dashboard.
  void setSession({
    required String staffId,
    required String ownerUserId,
    required String name,
    required String email,
    String imageUrl = '',
    String status = '',
    required String role,
  }) {
    this.staffId.value = staffId;
    this.ownerUserId.value = ownerUserId;
    staffName.value = name;
    staffEmail.value = email;
    staffImageUrl.value = imageUrl;
    staffStatus.value = status;
    staffRole.value = role;
  }

  /// Dipanggil saat staf menekan Logout di drawer.
  void clearSession() {
    staffId.value = '';
    ownerUserId.value = '';
    staffName.value = 'Kasir';
    staffEmail.value = '-';
    staffImageUrl.value = '';
    staffStatus.value = '';
    staffRole.value = '';
  }
}