import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:litly/core/app_colors.dart';
import 'package:litly/core/validators.dart';
import 'package:litly/models/user_model.dart';
import 'package:litly/providers/auth_provider.dart';
import 'package:litly/widgets/auth/auth_text_field.dart';
import 'package:litly/widgets/user_avatar.dart';

// // DIUBAH: Halaman edit profil dengan dukungan upload foto dari kamera/galeri
class EditProfileScreen extends StatefulWidget {
  EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  // State untuk melacak perubahan avatar
  String _initialName = '';
  String? _initialAvatar;

  // Avatar sementara yang dipilih
  String? _pickedTempPath; // Dari galeri/kamera (pratinjau)
  String? _selectedAssetAvatar; // Dari grid 6 avatar
  bool _isPhotoRemoved = false; // Jika pengguna memilih Remove Photo

  final ImagePicker _picker = ImagePicker();

  final List<String> _avatarList = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
  ];

  @override
  void initState() {
    super.initState();
    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    UserModel? user = authProvider.user;

    _initialName = user != null ? user.name : '';
    _initialAvatar = user?.avatar;

    _nameController.text = _initialName;
    if (_initialAvatar != null && _initialAvatar!.startsWith('assets/')) {
      _selectedAssetAvatar = _initialAvatar;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Menentukan avatar apa yang sedang tampil di layar pratinjau
  String? get _displayAvatar {
    if (_isPhotoRemoved) {
      return null;
    }
    if (_pickedTempPath != null) {
      return _pickedTempPath;
    }
    if (_selectedAssetAvatar != null) {
      return _selectedAssetAvatar;
    }
    return _initialAvatar;
  }

  void _onNameChanged(String val) {
    setState(() {
      _nameError = Validators.name(val);
    });
  }

  // Memeriksa validasi form dan apakah ada data yang berubah
  bool get _isFormValid {
    bool nameValid =
        _nameError == null && _nameController.text.trim().isNotEmpty;
    bool nameChanged = _nameController.text.trim() != _initialName;

    // Cek apakah avatar berubah
    String? currentEffectiveAvatar = _displayAvatar;
    bool avatarChanged = false;
    if (_initialAvatar == null || _initialAvatar!.isEmpty) {
      if (currentEffectiveAvatar != null &&
          currentEffectiveAvatar.isNotEmpty) {
        avatarChanged = true;
      }
    } else {
      if (currentEffectiveAvatar != _initialAvatar) {
        avatarChanged = true;
      }
    }

    return nameValid && (nameChanged || avatarChanged);
  }

  // Ambil foto dari kamera atau galeri
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _pickedTempPath = image.path;
          _selectedAssetAvatar = null; // Batalkan pilihan avatar bawaan
          _isPhotoRemoved = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = source == ImageSource.camera
          ? 'Could not open camera'
          : 'Could not open gallery';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  // Modal bottom sheet untuk opsi pemilihan foto profil
  void _showPhotoOptions() {
    bool hasActivePhoto =
        _displayAvatar != null && _displayAvatar!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.kNavyDark),
                  title: Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.photo_library, color: AppColors.kNavyDark),
                  title: Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (hasActivePhoto)
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.errorRed),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(color: AppColors.errorRed),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _isPhotoRemoved = true;
                        _pickedTempPath = null;
                        _selectedAssetAvatar = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hapus file foto lama milik pengguna dari penyimpanan aplikasi
  Future<void> _deleteOldCustomPhoto(String? oldPath) async {
    if (oldPath == null || oldPath.isEmpty) return;
    if (oldPath.startsWith('assets/')) return;

    try {
      File oldFile = File(oldPath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    } catch (e) {
      // Abaikan jika gagal menghapus file lama
    }
  }

  // Simpan perubahan profil ke database dan penyimpanan
  void _saveProfile() async {
    if (!_isFormValid) return;

    AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    UserModel? user = authProvider.user;

    if (user == null || user.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data pengguna tidak ditemukan.')),
      );
      return;
    }

    String newName = _nameController.text.trim();
    String? finalAvatarPath;

    try {
      if (_isPhotoRemoved) {
        // Hapus foto profil, ganti jadi null/kosong
        finalAvatarPath = null;
        await _deleteOldCustomPhoto(_initialAvatar);
      } else if (_pickedTempPath != null) {
        // Pengguna memilih foto baru dari kamera/galeri, salin ke app document
        final Directory appDir = await getApplicationDocumentsDirectory();
        final Directory profileDir = Directory('${appDir.path}/profile');
        if (!await profileDir.exists()) {
          await profileDir.create(recursive: true);
        }

        String fileName =
            'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String targetPath = '${profileDir.path}/$fileName';

        File tempFile = File(_pickedTempPath!);
        await tempFile.copy(targetPath);

        finalAvatarPath = targetPath;

        // Hapus foto custom lama milik user jika ada
        await _deleteOldCustomPhoto(_initialAvatar);
      } else if (_selectedAssetAvatar != null) {
        // Pengguna memilih avatar bawaan dari assets
        finalAvatarPath = _selectedAssetAvatar;
        await _deleteOldCustomPhoto(_initialAvatar);
      } else {
        finalAvatarPath = _initialAvatar;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save profile photo'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    String? error = await authProvider.updateProfile(
      user.id!,
      newName,
      finalAvatarPath,
    );

    if (!mounted) return;

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $error'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    String displayName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : (_initialName.isNotEmpty ? _initialName : 'Litly Reader');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // // DIUBAH: Foto profil besar (UserAvatar ~110) dengan badge kamera
              Center(
                child: Stack(
                  children: [
                    InkWell(
                      onTap: _showPhotoOptions,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.kLavender,
                            width: 2,
                          ),
                        ),
                        child: UserAvatar(
                          avatar: _displayAvatar,
                          name: displayName,
                          size: 110,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: InkWell(
                        onTap: _showPhotoOptions,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.kRedMaroon,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2.5,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Field Nama Lengkap
              AuthTextField(
                controller: _nameController,
                label: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                errorText: _nameError,
                onChanged: _onNameChanged,
              ),
              SizedBox(height: 24),

              // Pilihan Avatar Bawaan
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Or Choose Preset Avatar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 12),

              // Grid 6 Pilihan Avatar
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _avatarList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  String avatarPath = _avatarList[index];
                  bool isSelected =
                      _displayAvatar == avatarPath && _pickedTempPath == null;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAssetAvatar = avatarPath;
                        _pickedTempPath =
                            null; // Batalkan pratinjau foto kamera/galeri
                        _isPhotoRemoved = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.kRedMaroon
                              : Colors.transparent,
                          width: 3.0,
                        ),
                      ),
                      padding: EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          avatarPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.kLavender,
                              alignment: Alignment.center,
                              child: Text(
                                'A${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kRedMaroon,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 36),

              // Tombol Simpan Perubahan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kNavyDark,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isFormValid && !authProvider.isLoading
                      ? _saveProfile
                      : null,
                  child: authProvider.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
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
