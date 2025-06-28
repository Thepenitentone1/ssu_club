import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../shared/widgets/loading_widget.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  const OTPVerificationPage({super.key, required this.email, required this.onVerified});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _codeController = TextEditingController();
  int _attemptsLeft = 3;
  int _timer = 0;
  Timer? _countdown;
  String? _errorMessage;
  bool _isVerifying = false;
  bool _codeSent = true;
  final String _mockCode = '123456'; // Simulated code

  @override
  void dispose() {
    _codeController.dispose();
    _countdown?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timer = 30;
    });
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timer--;
        if (_timer <= 0) {
          _countdown?.cancel();
        }
      });
    });
  }

  void _verifyCode() {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isVerifying = false;
        if (_codeController.text == _mockCode) {
          widget.onVerified();
        } else {
          _attemptsLeft--;
          if (_attemptsLeft <= 0) {
            _startTimer();
            _attemptsLeft = 3;
            _errorMessage = 'Too many attempts. Please wait before retrying.';
          } else {
            _errorMessage = 'Incorrect code. Attempts left: $_attemptsLeft';
          }
        }
      });
    });
  }

  void _resendCode() {
    setState(() {
      _codeSent = false;
      _errorMessage = null;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _codeSent = true;
        _startTimer();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1A237E);
    final accent = const Color(0xFF4CAF50);
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/student_illustration.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                '2-Step Verification',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to',
                style: TextStyle(color: primary.withOpacity(0.7)),
              ),
              Text(
                widget.email,
                style: TextStyle(color: accent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                enabled: _timer == 0 && !_isVerifying,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, letterSpacing: 8, color: primary),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_timer == 0 && !_isVerifying) ? _verifyCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isVerifying
                      ? const SmallLoadingWidget(color: Colors.white)
                      : const Text('Verify OTP'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Didn\'t receive the code?', style: TextStyle(color: primary.withOpacity(0.7))),
                  TextButton(
                    onPressed: (_timer == 0 && _codeSent) ? _resendCode : null,
                    child: _timer > 0
                        ? Text('Resend in [1m$_timer[0m s', style: TextStyle(color: accent))
                        : const Text('Resend Code'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 