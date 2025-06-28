import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class ThankYouPage extends StatefulWidget {
  const ThankYouPage({super.key});

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage> with TickerProviderStateMixin {
  late AnimationController _successController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Add haptic feedback
    HapticFeedback.mediumImpact();
    
    // Start success animation
    await _successController.forward();
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Show confetti after a delay
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _showConfetti = true;
    });
    _confettiController.forward();
  }

  @override
  void dispose() {
    _successController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1E3A8A);
    final secondary = const Color(0xFF3B82F6);
    final accent = const Color(0xFF10B981);
    final background = const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Animated background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withOpacity(0.05),
                  secondary.withOpacity(0.08),
                  accent.withOpacity(0.05),
                  background,
                ],
              ),
            ),
          ),

          // Confetti overlay
          if (_showConfetti)
            Positioned.fill(
              child: _buildConfettiAnimation(),
            ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Success animation container
                      Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Animated success icon
                            AnimatedBuilder(
                              animation: _successController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _successController.value,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [accent, accent.withOpacity(0.8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 32),

                            // Success message
                            Text(
                              'Welcome to SSU Club Hub!',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primary,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 300)).slideY(begin: 0.3, end: 0),

                            const SizedBox(height: 16),

                            Text(
                              'Your account has been successfully created. You\'re now ready to explore all the amazing features!',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 500)).slideY(begin: 0.3, end: 0),

                            const SizedBox(height: 32),

                            // Feature highlights
                            _buildFeatureCard(
                              icon: Icons.group,
                              title: 'Join Student Clubs',
                              description: 'Discover and connect with various student organizations',
                              color: secondary,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 700)).slideX(begin: -0.3, end: 0),

                            const SizedBox(height: 16),

                            _buildFeatureCard(
                              icon: Icons.event,
                              title: 'Attend Events',
                              description: 'Stay updated with campus events and activities',
                              color: accent,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 900)).slideX(begin: 0.3, end: 0),

                            const SizedBox(height: 16),

                            _buildFeatureCard(
                              icon: Icons.chat_bubble_outline,
                              title: 'Connect with Peers',
                              description: 'Chat and collaborate with fellow students',
                              color: primary,
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1100)).slideX(begin: -0.3, end: 0),

                            const SizedBox(height: 40),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pushReplacementNamed(context, '/main');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primary,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: primary.withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.rocket_launch, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Get Started',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.pushReplacementNamed(context, '/intro');
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primary,
                                      side: BorderSide(color: primary, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.explore, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Explore App',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1300)).slideY(begin: 0.3, end: 0),

                            const SizedBox(height: 24),

                            // Additional info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: accent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: accent,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You can now access all features including clubs, events, announcements, and chat with other students.',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: accent.withOpacity(0.8),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: const Duration(milliseconds: 1500)).slideY(begin: 0.3, end: 0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiAnimation() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return Stack(
          children: List.generate(20, (index) {
            final random = (index * 123) % 100 / 100.0;
            final x = random * MediaQuery.of(context).size.width;
            final y = _confettiController.value * MediaQuery.of(context).size.height;
            final color = [
              const Color(0xFF3B82F6),
              const Color(0xFF10B981),
              const Color(0xFFF59E0B),
              const Color(0xFFEF4444),
              const Color(0xFF8B5CF6),
            ][index % 5];

            return Positioned(
              left: x,
              top: y,
              child: Transform.rotate(
                angle: _confettiController.value * 4 * 3.14159,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 