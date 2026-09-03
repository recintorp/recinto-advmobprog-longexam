import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'signin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// "TickerProviderStateMixin" is needed whenever a screen runs more than one
// animation at the same time — it's what lets each AnimationController
// below sync itself to the screen's own refresh timing.
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Controls the logo's entrance: it pops in with a little bounce and a
  // small wiggle, instead of just appearing instantly.
  late final AnimationController _entryController;
  // Once the entrance finishes, this one takes over and gently pulses the
  // logo (grow a little, shrink a little, on repeat) so the screen feels
  // alive while the app checks whether the user is logged in.
  late final AnimationController _pulseController;

  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _wiggleAnimation;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Curves.elasticOut is what creates the "pop" — the logo overshoots
    // its final size slightly and springs back, like a little bounce,
    // instead of smoothly sliding to size.
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

    // Fades in quickly at the very start of the entrance, well before the
    // bounce settles, so the logo is never invisible while it's bouncing.
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    // A small side-to-side tilt (in radians, so 0.15 is a subtle few
    // degrees) that settles back to straight — this is the "wiggle" that
    // makes the entrance feel playful rather than just a plain zoom-in.
    _wiggleAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Once the pop-in finishes, start the gentle continuous pulse.
    // "reverse: true" makes it grow then shrink then grow again on loop,
    // instead of just growing forever.
    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.repeat(reverse: true);
      }
    });

    _entryController.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    // Animation controllers need to be shut down manually when the screen
    // goes away, or they'll keep running in the background and waste
    // battery/memory.
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Checks whether the person is already logged in (by looking for a saved
  // login token on the device) and sends them to the right screen. The
  // Future.delayed just makes sure the splash screen stays visible for at
  // least 2 seconds, so it doesn't flash by too quickly to see.
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    await Future.delayed(const Duration(seconds: 2)); // Brief delay for visual loading

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SigninScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // White background to match the sign-in screen, so there's no color
      // flash when this screen hands off to it.
      backgroundColor: Colors.white,
      body: Center(
        // AnimatedBuilder re-runs this every time any of the animations
        // tick, which is what actually moves the logo on screen. Both the
        // entrance animation and the pulse animation feed into the same
        // scale, so whichever one is currently running is the one that
        // shows.
        child: AnimatedBuilder(
          animation: Listenable.merge([_entryController, _pulseController]),
          builder: (context, child) {
            // While the entrance is still playing, use its bounce scale.
            // Once it's done, switch over to the slow pulse scale instead.
            final currentScale = _entryController.isAnimating ? _scaleAnimation.value : _pulseAnimation.value;

            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.rotate(
                angle: _wiggleAnimation.value,
                child: Transform.scale(
                  scale: currentScale,
                  child: child,
                ),
              ),
            );
          },
          // The Hero tag here must exactly match the one used on the
          // sign-in screen's logo. That's the only thing that tells
          // Flutter "these two are the same object" and makes it animate
          // one flying into the other instead of an abrupt screen swap.
          child: Hero(
            tag: 'app_logo',
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.brown,
              child: const Text(
                'm',
                style: TextStyle(
                  fontFamily: 'Klavika',
                  fontSize: 52,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}