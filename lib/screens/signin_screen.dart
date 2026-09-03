import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'home_screen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  // The list of languages people can pick from, and which one is
  // currently selected. Starts on English (US), same as before, but now
  // tapping the dropdown actually lets someone switch to a different one.
  final List<String> _languages = const [
    'English (US)',
    'Español (US)',
    'Français (Canada)',
    'Português (Brasil)',
    '中文 (简体)',
    'Tiếng Việt',
  ];
  String _selectedLanguage = 'English (US)';

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _userService.login(_usernameController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid username or password.';
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
    // Figure out how wide the current screen actually is. Different
    // devices and emulators (like the "Medium Phone API 35" one) don't
    // all have the same screen size, so basing our spacing on a fixed
    // number tuned for one screen is what made things look "off" when
    // switching devices.
    final screenWidth = MediaQuery.of(context).size.width;
    // 411 is a very common reference width for an average phone (it's
    // also what the Medium Phone emulator uses). We compare the real
    // screen to that number to get a small multiplier — clamped so it
    // can never shrink or blow up the spacing too much on unusually
    // small or large screens.
    final scale = (screenWidth / 411.0).clamp(0.9, 1.15);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final fieldFillColor = isDark ? Colors.grey[850] : Colors.grey[100];

    // Some phones and emulators ship with a different default "text size"
    // accessibility setting than others. That alone can make the exact
    // same design look bigger or smaller from device to device. Locking
    // textScaler to 1.0 here means our chosen font sizes always render
    // the same, no matter what device or emulator this runs on.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        // Center + a max width keeps the form from stretching edge-to-edge
        // on wide screens (tablets, foldables, etc). On a normal phone
        // screen this has no visible effect since the phone is narrower
        // than 440, but it stops things looking "too wide" on bigger ones.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              // mainAxisSize.min tells the column to only take up as much
              // height as its children actually need, instead of forcing
              // itself to fill the whole screen. This is what removes the
              // big empty gap you saw between "Forgot password?" and the
              // "Create new account" button.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language selector at the very top. PopupMenuButton
                  // shows a small menu right under this when tapped —
                  // picking one of the languages updates _selectedLanguage,
                  // which is what's shown here.
                  Center(
                    child: PopupMenuButton<String>(
                      initialValue: _selectedLanguage,
                      onSelected: (language) {
                        setState(() {
                          _selectedLanguage = language;
                        });
                      },
                      itemBuilder: (context) => _languages
                          .map((language) => PopupMenuItem<String>(
                                value: language,
                                child: Text(language),
                              ))
                          .toList(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedLanguage, style: TextStyle(color: theme.hintColor, fontSize: 15)),
                          Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color, size: 22),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40 * scale),

                  // App logo circle. Wrapped in a Hero with the same tag
                  // used on the splash screen — when this screen opens,
                  // Flutter automatically animates the logo flying from
                  // where it was on the splash screen to right here,
                  // instead of it just popping into place.
                  Center(
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
                  SizedBox(height: 40 * scale),

                  // Legal / privacy text shown above the login fields.
                  // Wording matches the Facebook reference exactly, just
                  // swapping "Facebook" for "Moppibook" — same sentence
                  // structure, same line breaks, same bold parts.
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                      children: [
                        const TextSpan(text: 'By proceeding, you allow Moppibook to request and receive your mobile number from your mobile network. Review your mobile network\'s '),
                        TextSpan(text: 'terms and privacy policy', style: TextStyle(color: Colors.brown.shade400, fontWeight: FontWeight.bold)),
                        const TextSpan(text: '.\n'),
                        TextSpan(text: 'Change Settings', style: TextStyle(color: Colors.brown.shade400, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  // Username / email field. The text people type into this
                  // box is read later through _usernameController.
                  TextField(
                    controller: _usernameController,
                    // fontSize 16 makes what the user types (and the grey
                    // hint text below) match the larger text used in the
                    // reference fields, instead of the small default size.
                    style: TextStyle(fontSize: 16, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Mobile number or email',
                      hintStyle: TextStyle(fontSize: 16, color: theme.hintColor),
                      filled: true,
                      fillColor: fieldFillColor,
                      // Taller vertical padding makes the box itself bigger,
                      // which is what makes the whole field feel "roomier"
                      // instead of cramped.
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),

                  // Password field. obscureText hides the letters as dots,
                  // and the eye icon lets the user toggle that on and off.
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(fontSize: 16, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: TextStyle(fontSize: 16, color: theme.hintColor),
                      filled: true,
                      fillColor: fieldFillColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: theme.iconTheme.color,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16 * scale),

                  // Error text only appears after a failed login attempt.
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ),

                  // Login button. While _isLoading is true, it swaps out
                  // for a spinner so the user knows something is happening
                  // and can't tap the button twice.
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 0,
                          ),
                          child: const Text('Log in', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                  SizedBox(height: 16 * scale),

                  Center(
                    child: TextButton(
                      onPressed: () {},
                      child: Text('Forgot password?', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),

                  // Fixed gap instead of a Spacer(). A Spacer() stretches
                  // to fill every bit of leftover screen space, which is
                  // what caused the huge empty area before. Multiplying by
                  // "scale" lets this breathing room grow or shrink a bit
                  // to match the device, instead of always being exactly
                  // 60 pixels whether that's a small phone or a bigger
                  // emulator screen.
                  SizedBox(height: 60 * scale),

                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.brown.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: Text('Create new account', style: TextStyle(color: Colors.brown.shade400, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SizedBox(height: 12 * scale),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.all_inclusive, size: 18, color: theme.iconTheme.color),
                      const SizedBox(width: 4),
                      Text('Moppibook', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w500, fontSize: 15)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}