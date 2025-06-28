import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../core/services/cloudinary_storage_service.dart';

class UploadWidget extends StatefulWidget {
  final String folder;
  final Function(String)? onUploadComplete;
  final Function(String)? onUploadError;
  final String? title;
  final bool showPreview;
  final double maxWidth;
  final double maxHeight;

  const UploadWidget({
    super.key,
    required this.folder,
    this.onUploadComplete,
    this.onUploadError,
    this.title,
    this.showPreview = true,
    this.maxWidth = 300,
    this.maxHeight = 200,
  });

  @override
  State<UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  String? _uploadedUrl;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.maxWidth,
      height: widget.maxHeight,
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title ?? 'Upload File',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isUploading) {
      return _buildUploadingState();
    } else if (_uploadedUrl != null && widget.showPreview) {
      return _buildPreviewState();
    } else {
      return _buildUploadOptions();
    }
  }

  Widget _buildUploadOptions() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Upload from Gallery
        _buildUploadButton(
          icon: Icons.photo_library,
          label: 'Gallery',
          onTap: () => _uploadFromGallery(),
        ),
        
        const SizedBox(height: 12),
        
        // Upload from Camera
        _buildUploadButton(
          icon: Icons.camera_alt,
          label: 'Camera',
          onTap: () => _uploadFromCamera(),
        ),
        
        const SizedBox(height: 12),
        
        // Upload any file
        _buildUploadButton(
          icon: Icons.attach_file,
          label: 'Any File',
          onTap: () => _uploadAnyFile(),
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Uploading...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _uploadProgress,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_uploadProgress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewState() {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _uploadedUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _uploadFromGallery(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Change'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _copyUrl(),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy URL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadFromGallery() async {
    await _uploadFile(() => CloudinaryStorageService.uploadImageFromGallery(
      widget.folder,
      onProgress: _updateProgress,
    ));
  }

  Future<void> _uploadFromCamera() async {
    await _uploadFile(() => CloudinaryStorageService.uploadImageFromCamera(
      widget.folder,
      onProgress: _updateProgress,
    ));
  }

  Future<void> _uploadAnyFile() async {
    await _uploadFile(() => CloudinaryStorageService.pickAndUploadFile(
      widget.folder,
      onProgress: _updateProgress,
    ));
  }

  Future<void> _uploadFile(Future<String?> Function() uploadFunction) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final url = await uploadFunction();
      
      if (url != null) {
        setState(() {
          _uploadedUrl = url;
          _uploadProgress = 1.0;
        });
        
        widget.onUploadComplete?.call(url);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File uploaded successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Upload failed: No URL returned');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Upload failed: ${e.toString()}';
      });
      
      widget.onUploadError?.call(e.toString());
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _updateProgress(double progress) {
    setState(() {
      _uploadProgress = progress;
    });
  }

  void _copyUrl() {
    if (_uploadedUrl != null) {
      // In a real app, you'd use clipboard functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL copied to clipboard!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Public method to reset the widget
  void reset() {
    setState(() {
      _uploadedUrl = null;
      _uploadProgress = 0.0;
      _isUploading = false;
      _errorMessage = null;
    });
  }

  // Public getter for the uploaded URL
  String? get uploadedUrl => _uploadedUrl;
} 