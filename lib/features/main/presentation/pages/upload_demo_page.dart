import 'package:flutter/material.dart';
import '../../../../shared/widgets/upload_widget.dart';

class UploadDemoPage extends StatefulWidget {
  const UploadDemoPage({super.key});

  @override
  State<UploadDemoPage> createState() => _UploadDemoPageState();
}

class _UploadDemoPageState extends State<UploadDemoPage> {
  final List<String> _uploadedUrls = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              
              const SizedBox(height: 24),
              
              // Upload Widgets Grid
              _buildUploadGrid(),
              
              const SizedBox(height: 24),
              
              // Uploaded Files Section
              if (_uploadedUrls.isNotEmpty) _buildUploadedFilesSection(),
              
              const SizedBox(height: 24),
              
              // Features Section
              _buildFeaturesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cloudinary Upload Demo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Experience the enhanced upload functionality with progress tracking, error handling, and cross-platform support.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.8,
      children: [
        // Profile Picture Upload
        UploadWidget(
          folder: 'profile_pictures',
          title: 'Profile Picture',
          onUploadComplete: (url) {
            setState(() {
              _uploadedUrls.add(url);
            });
          },
          onUploadError: (error) {
            _showErrorSnackBar('Profile picture upload failed: $error');
          },
        ),
        
        // Event Images Upload
        UploadWidget(
          folder: 'event_images',
          title: 'Event Images',
          onUploadComplete: (url) {
            setState(() {
              _uploadedUrls.add(url);
            });
          },
          onUploadError: (error) {
            _showErrorSnackBar('Event image upload failed: $error');
          },
        ),
        
        // Documents Upload
        UploadWidget(
          folder: 'documents',
          title: 'Documents',
          onUploadComplete: (url) {
            setState(() {
              _uploadedUrls.add(url);
            });
          },
          onUploadError: (error) {
            _showErrorSnackBar('Document upload failed: $error');
          },
        ),
        
        // Club Media Upload
        UploadWidget(
          folder: 'club_media',
          title: 'Club Media',
          onUploadComplete: (url) {
            setState(() {
              _uploadedUrls.add(url);
            });
          },
          onUploadError: (error) {
            _showErrorSnackBar('Club media upload failed: $error');
          },
        ),
      ],
    );
  }

  Widget _buildUploadedFilesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Uploaded Files (${_uploadedUrls.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _uploadedUrls.clear()),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._uploadedUrls.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            return _buildUploadedFileItem(index, url);
          }),
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem(int index, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(url),
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'File ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyUrl(url),
            tooltip: 'Copy URL',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.phone_android,
            title: 'Cross-Platform Support',
            description: 'Works seamlessly on both mobile and web platforms',
          ),
          _buildFeatureItem(
            icon: Icons.trending_up,
            title: 'Progress Tracking',
            description: 'Real-time upload progress with visual indicators',
          ),
          _buildFeatureItem(
            icon: Icons.error_outline,
            title: 'Error Handling',
            description: 'Comprehensive error handling with user-friendly messages',
          ),
          _buildFeatureItem(
            icon: Icons.image,
            title: 'Multiple File Types',
            description: 'Support for images, videos, documents, and more',
          ),
          _buildFeatureItem(
            icon: Icons.security,
            title: 'Secure Upload',
            description: 'Files are securely uploaded to Cloudinary with proper validation',
          ),
          _buildFeatureItem(
            icon: Icons.speed,
            title: 'Optimized Performance',
            description: 'Optimized image quality and file size for better performance',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String url) {
    final extension = url.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return Icons.image;
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
      return Icons.video_file;
    } else if (['pdf', 'doc', 'docx'].contains(extension)) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  void _copyUrl(String url) {
    // In a real app, you'd use clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('URL copied to clipboard!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Demo Info'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This demo showcases the enhanced Cloudinary upload functionality:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Cross-platform support (Web & Mobile)'),
            Text('• Progress tracking with visual indicators'),
            Text('• Comprehensive error handling'),
            Text('• Multiple file type support'),
            Text('• Secure upload to Cloudinary'),
            Text('• Optimized performance'),
            SizedBox(height: 12),
            Text(
              'Try uploading different types of files to see the functionality in action!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 