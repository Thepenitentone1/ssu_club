import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/models/user.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/services/cloudinary_storage_service.dart';
import '../../../../shared/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _yearLevelController = TextEditingController();
  
  File? _profileImage;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _currentPhotoUrl;
  UserModel? _currentUser;
  
  Department _selectedDepartment = Department.cas;
  String _selectedCourse = '';
  String? _errorMessage;

  // Course options for each department
  final Map<Department, List<String>> _departmentCourses = {
    Department.cas: [
      'Bachelor of Arts in English',
      'Bachelor of Arts in History',
      'Bachelor of Science in Biology',
      'Bachelor of Science in Chemistry',
      'Bachelor of Science in Mathematics',
      'Bachelor of Science in Physics',
      'Bachelor of Science in Psychology',
      'Bachelor of Science in Environmental Science',
    ],
    Department.cbe: [
      'Bachelor of Science in Accountancy',
      'Bachelor of Science in Business Administration',
      'Bachelor of Science in Entrepreneurship',
      'Bachelor of Science in Hospitality Management',
      'Bachelor of Science in Tourism Management',
      'Bachelor of Science in Office Administration',
    ],
    Department.coe: [
      'Bachelor of Elementary Education',
      'Bachelor of Secondary Education',
      'Bachelor of Special Education',
      'Bachelor of Early Childhood Education',
      'Bachelor of Physical Education',
    ],
    Department.coeng: [
      'Bachelor of Science in Civil Engineering',
      'Bachelor of Science in Electrical Engineering',
      'Bachelor of Science in Mechanical Engineering',
      'Bachelor of Science in Computer Engineering',
      'Bachelor of Science in Electronics Engineering',
      'Bachelor of Science in Agricultural Engineering',
    ],
    Department.cot: [
      'Bachelor of Science in Information Technology',
      'Bachelor of Science in Computer Science',
      'Bachelor of Science in Industrial Technology',
      'Bachelor of Science in Food Technology',
      'Bachelor of Science in Automotive Technology',
      'Bachelor of Science in Electronics Technology',
    ],
    Department.coa: [
      'Bachelor of Science in Agriculture',
      'Bachelor of Science in Agricultural Technology',
      'Bachelor of Science in Animal Science',
      'Bachelor of Science in Agricultural Economics',
      'Bachelor of Science in Crop Science',
    ],
    Department.cof: [
      'Bachelor of Science in Fisheries',
      'Bachelor of Science in Aquaculture',
      'Bachelor of Science in Marine Biology',
    ],
    Department.cofes: [
      'Bachelor of Science in Forestry',
      'Bachelor of Science in Environmental Science',
      'Bachelor of Science in Natural Resources Management',
    ],
    Department.com: [
      'Doctor of Medicine',
    ],
    Department.con: [
      'Bachelor of Science in Nursing',
    ],
    Department.coph: [
      'Bachelor of Science in Pharmacy',
    ],
    Department.gs: [
      'Master of Arts in Education',
      'Master of Science in Biology',
      'Master of Science in Chemistry',
      'Master of Science in Mathematics',
      'Master of Science in Physics',
      'Master of Science in Psychology',
      'Master of Science in Agriculture',
      'Master of Science in Forestry',
      'Master of Science in Environmental Science',
      'Master of Science in Fisheries',
      'Master of Science in Engineering',
      'Master of Business Administration',
      'Doctor of Philosophy in Education',
      'Doctor of Philosophy in Biology',
      'Doctor of Philosophy in Chemistry',
      'Doctor of Philosophy in Mathematics',
      'Doctor of Philosophy in Physics',
      'Doctor of Philosophy in Psychology',
      'Doctor of Philosophy in Agriculture',
      'Doctor of Philosophy in Forestry',
      'Doctor of Philosophy in Environmental Science',
      'Doctor of Philosophy in Fisheries',
      'Doctor of Philosophy in Engineering',
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await UserService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _firstNameController.text = user.firstName;
          _lastNameController.text = user.lastName;
          _middleNameController.text = user.middleName ?? '';
          _studentIdController.text = user.studentId ?? '';
          _yearLevelController.text = user.yearLevel ?? '';
          _currentPhotoUrl = user.profileImageUrl;
          _selectedDepartment = user.department ?? Department.cas;
          _selectedCourse = user.course ?? _departmentCourses[_selectedDepartment]!.first;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading user data: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
    });

    try {
      final photoUrl = await CloudinaryStorageService.uploadImageFromGallery(
        'profile_images',
        onProgress: (progress) {
          // Progress callback for future UI updates
        },
      );

      if (photoUrl != null) {
        setState(() {
          _currentPhotoUrl = photoUrl;
          _profileImage = null; // Clear local file since we're using URL
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
    });

    try {
      final photoUrl = await CloudinaryStorageService.uploadImageFromCamera(
        'profile_images',
        onProgress: (progress) {
          // Progress callback for future UI updates
        },
      );

      if (photoUrl != null) {
        setState(() {
          _currentPhotoUrl = photoUrl;
          _profileImage = null; // Clear local file since we're using URL
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error taking photo: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Photo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF3B82F6)),
              title: Text(
                'Choose from Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF3B82F6)),
              title: Text(
                'Take a Photo',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadImage() async {
    // If we have a new photo URL from Cloudinary, use it
    if (_currentPhotoUrl != null && _profileImage == null) {
      return _currentPhotoUrl;
    }
    
    // If we have a local file, upload it to Cloudinary
    if (_profileImage != null) {
      try {
        final photoUrl = await CloudinaryStorageService.uploadFile(
          _profileImage!,
          'profile_images',
          'image',
          onProgress: (progress) {
            // Progress callback for future UI updates
          },
        );

        if (photoUrl != null) {
          setState(() {
            _currentPhotoUrl = photoUrl;
            _profileImage = null; // Clear local file
          });
          return photoUrl;
        } else {
          setState(() {
            _errorMessage = 'Failed to upload image. Please try again.';
          });
          return null;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error uploading image: ${e.toString()}';
        });
        return null;
      }
    }

    return _currentPhotoUrl;
  }

  void _onDepartmentChanged(Department? department) {
    if (department != null) {
      setState(() {
        _selectedDepartment = department;
        _selectedCourse = _departmentCourses[department]!.first;
      });
    }
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final photoUrl = await _uploadImage();
      
      // Create updated user model
      final updatedUser = _currentUser!.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        yearLevel: _yearLevelController.text.trim(),
        department: _selectedDepartment,
        course: _selectedCourse,
        profileImageUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      await UserService.updateCompleteUserProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating profile: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getDepartmentName(Department department) {
    switch (department) {
      case Department.cas:
        return 'College of Arts and Sciences';
      case Department.cbe:
        return 'College of Business and Entrepreneurship';
      case Department.coe:
        return 'College of Education';
      case Department.coeng:
        return 'College of Engineering';
      case Department.cot:
        return 'College of Technology';
      case Department.coa:
        return 'College of Agriculture';
      case Department.cof:
        return 'College of Fisheries';
      case Department.cofes:
        return 'College of Forestry and Environmental Science';
      case Department.com:
        return 'College of Medicine';
      case Department.con:
        return 'College of Nursing';
      case Department.coph:
        return 'College of Pharmacy';
      case Department.gs:
        return 'Graduate School';
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required dynamic value,
    required List<DropdownMenuItem> items,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);

    if (_isLoading && _currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(child: LoadingWidget()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: primary,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.edit,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Image
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: secondary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: secondary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _isUploadingImage
                                    ? Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      )
                                    : _profileImage != null
                                        ? Image.file(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                          )
                                        : _currentPhotoUrl != null
                                            ? CachedNetworkImage(
                                                imageUrl: _currentPhotoUrl!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => const Center(
                                                  child: CircularProgressIndicator(),
                                                ),
                                                errorWidget: (context, url, error) => Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey[400],
                                                ),
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isUploadingImage ? Colors.grey : secondary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isUploadingImage ? Colors.grey : secondary).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                                  icon: _isUploadingImage 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.camera_alt, size: 20),
                                  color: Colors.white,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(duration: 600.ms),

                      const SizedBox(height: 32),

                      // Personal Information Section
                      _buildSectionHeader('Personal Information', Icons.person),
                      const SizedBox(height: 16),

                      // First Name
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 16),

                      // Last Name
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 16),

                      // Middle Name
                      _buildTextField(
                        controller: _middleNameController,
                        label: 'Middle Name (Optional)',
                        icon: Icons.person_outline,
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 16),

                      // Student ID
                      _buildTextField(
                        controller: _studentIdController,
                        label: 'Student ID',
                        icon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Student ID is required';
                          }
                          if (value.trim().length < 8) {
                            return 'Student ID must be at least 8 characters';
                          }
                          return null;
                        },
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 16),

                      // Year Level
                      _buildTextField(
                        controller: _yearLevelController,
                        label: 'Year Level',
                        icon: Icons.grade_outlined,
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 32),

                      // Academic Information Section
                      _buildSectionHeader('Academic Information', Icons.school),
                      const SizedBox(height: 16),

                      // Department
                      _buildDropdownField(
                        label: 'Department',
                        icon: Icons.business_outlined,
                        value: _selectedDepartment,
                        items: Department.values.map((dept) {
                          return DropdownMenuItem(
                            value: dept,
                            child: Text(_getDepartmentName(dept)),
                          );
                        }).toList(),
                        onChanged: (value) => _onDepartmentChanged(value as Department?),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 16),

                      // Course
                      _buildDropdownField(
                        label: 'Course',
                        icon: Icons.book_outlined,
                        value: _selectedCourse,
                        items: _departmentCourses[_selectedDepartment]!.map((course) {
                          return DropdownMenuItem(
                            value: course,
                            child: Text(course),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCourse = value;
                            });
                          }
                        },
                      ).animate().fadeIn(delay: 800.ms),

                      const SizedBox(height: 32),

                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 900.ms),

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: secondary.withValues(alpha: 0.4),
                          ),
                          child: _isLoading
                              ? const SmallLoadingWidget(color: Colors.white)
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 1000.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _studentIdController.dispose();
    _yearLevelController.dispose();
    super.dispose();
  }
} 