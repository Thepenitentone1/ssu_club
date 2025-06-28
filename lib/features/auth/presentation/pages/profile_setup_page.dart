import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/models/user.dart';
import '../../../../core/services/user_service.dart';
import '../../../../shared/widgets/loading_widget.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  
  Department _selectedDepartment = Department.cas;
  String _selectedCourse = '';
  bool _isLoading = false;
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
    _selectedCourse = _departmentCourses[_selectedDepartment]!.first;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _middleNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Update user profile with the new information
      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        department: _selectedDepartment,
        course: _selectedCourse,
        isProfileComplete: true,
      );

      await UserService.updateCompleteUserProfile(updatedUser);

      if (mounted) {
        // Navigate to main page
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save profile: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_add,
                          size: 64,
                          color: Colors.white,
                        ).animate().scale(duration: 600.ms),
                        const SizedBox(height: 16),
                        Text(
                          'Complete Your Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Help us personalize your experience and show relevant clubs',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms),
                      ],
                    ),
                  ).animate().slideY(begin: -0.3, duration: 600.ms),

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
                  ).animate().fadeIn(delay: 600.ms),

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
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 16),

                  // Middle Name
                  _buildTextField(
                    controller: _middleNameController,
                    label: 'Middle Name (Optional)',
                    icon: Icons.person_outline,
                  ).animate().fadeIn(delay: 800.ms),

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
                  ).animate().fadeIn(delay: 900.ms),

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
                    onChanged: _onDepartmentChanged,
                  ).animate().fadeIn(delay: 1000.ms),

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
                  ).animate().fadeIn(delay: 1100.ms),

                  const SizedBox(height: 32),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
                    ).animate().fadeIn(delay: 1200.ms),

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
                        shadowColor: secondary.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const LoadingWidget()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                const SizedBox(width: 8),
                                Text(
                                  'Complete Setup',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(delay: 1300.ms).slideY(begin: 0.3),

                  const SizedBox(height: 16),

                  // Skip for now button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _isLoading ? null : () {
                        Navigator.of(context).pushReplacementNamed('/main');
                      },
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1E3A8A),
            size: 20,
          ),
        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
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
      default:
        return 'Not specified';
    }
  }
} 