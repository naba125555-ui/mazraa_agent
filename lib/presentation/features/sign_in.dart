import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/login_scenery.dart';

import '../shared/scope.dart';
import '../shared/widgets.dart';

/// H02: a responsive, bilingual sign-in screen with real painted waves.
/// The authentication contract remains owned by AgentApp / RemoteRepository.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  static const Color _forest = Color(0xFF004936);
  static const Color _emerald = Color(0xFF007A53);
  static const Color _mint = Color(0xFFB8FFDB);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;
  bool _remember = true;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.app.login(
        _email.text.trim(),
        _password.text,
        remember: _remember,
      );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _help({required bool recovery}) {
    final title = recovery
        ? context.tr('استعادة الوصول', 'Recover access')
        : context.tr('الدعم', 'Support');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(context.tr(
          'حساب الطبيب والوكيل يُدار بواسطة الإدارة. تواصل مع مسؤول الفرع لاستعادة الوصول أو طلب الدعم. لا تشارك كلمة المرور.',
          'Doctor and agent accounts are managed by your organization. Contact your branch administrator for access recovery or support. Never share your password.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.tr('فهمت', 'Got it')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final pageColor = dark ? const Color(0xFF002B24) : const Color(0xFFF0FFF7);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: pageColor,
        systemNavigationBarIconBrightness:
            dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: pageColor,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // The full-screen background is composed of live clipped Flutter layers.
            // The replaceable WebP image is restricted to the header.
            Positioned.fill(
              child: IgnorePointer(
                child: LoginScenery(dark: dark),
              ),
            ),
            SafeArea(
              top: false,
              bottom: false,
              child: LayoutBuilder(
                builder: (context, viewport) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom + 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 500,
                        minHeight: viewport.maxHeight -
                            MediaQuery.paddingOf(context).bottom - 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _hero(context, dark, rtl),
                          _card(context, dark),
                          const SizedBox(height: 15),
                          _securityNotice(context, dark),
                          const SizedBox(height: 13),
                          _contractBadge(context, dark),
                          const SizedBox(height: 34),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, bool dark, bool rtl) {
    final top = MediaQuery.paddingOf(context).top;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: top + 224,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: LoginHeaderWave(
              dark: dark,
              photoOnLeft: rtl,
            ),
          ),
          PositionedDirectional(
            top: top + 8,
            start: 15,
            child: Row(
              textDirection: TextDirection.ltr,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x3300CF8A),
                    border: Border.all(
                      color: const Color(0xAAFFE8A8),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    size: 25,
                    color: Color(0xFFFFE7A9),
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mazraa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Agent',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: top + 10,
            end: 14,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _headerControl(
                  tooltip: context.tr('تغيير اللغة', 'Change language'),
                  text: context.app.ar ? 'EN' : 'ع',
                  onPressed: () {
                    context.app.preferences(
                      language: context.app.ar ? 'en' : 'ar',
                    );
                  },
                ),
                const SizedBox(width: 5),
                _headerControl(
                  tooltip: context.tr('تغيير المظهر', 'Toggle appearance'),
                  icon: dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  onPressed: () {
                    context.app.preferences(theme: dark ? 'light' : 'dark');
                  },
                ),
              ],
            ),
          ),
          PositionedDirectional(
            top: top + 78,
            start: 17,
            width: screenWidth > 550 ? 267 : 191,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('مرحباً بك', 'Welcome'),
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.16,
                    shadows: [
                      Shadow(color: Color(0x9900251E), blurRadius: 9),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'سجّل الدخول للوصول إلى عمليات الطبيب والوكيل',
                    'Sign in to access doctor and agent operations',
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    shadows: [
                      Shadow(color: Color(0x6600251E), blurRadius: 5),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 4,
                  width: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD58A), Color(0xFFFFEABB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerControl({
    required String tooltip,
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
  }) =>
      SizedBox(
        width: 31,
        height: 31,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 31, minHeight: 31),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x50002117),
            foregroundColor: Colors.white,
          ),
          icon: icon != null
              ? Icon(icon, size: 17)
              : Text(
                  text ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      );

  Widget _card(BuildContext context, bool dark) {
    final fg = dark ? Colors.white : const Color(0xFF003C2C);
    final cardColor =
        dark ? const Color(0xE8003E33) : const Color(0xF9FFFFFF);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 21),
            padding: const EdgeInsets.fromLTRB(15, 50, 15, 19),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border.all(
                color: dark
                    ? const Color(0x6856C7A5)
                    : const Color(0xFFE6F5EC),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .23 : .10),
                  blurRadius: 22,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF67DFA5), size: 19),
                      const SizedBox(width: 11),
                      Text(
                        context.tr('تسجيل الدخول', 'Sign in'),
                        style: TextStyle(
                          color: fg,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Icon(Icons.eco, color: Color(0xFF67DFA5), size: 19),
                    ],
                  ),
                  const SizedBox(height: 19),
                  _input(
                    context,
                    dark,
                    icon: Icons.mail_outline,
                    child: TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      style: TextStyle(color: fg),
                      decoration: _inputDecoration(
                        context.tr('البريد الإلكتروني', 'Email address'),
                        dark,
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(email)
                            ? null
                            : context.tr(
                                'أدخل بريدًا إلكترونيًا صالحًا',
                                'Enter a valid email address',
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _input(
                    context,
                    dark,
                    icon: Icons.lock_outline_rounded,
                    trailing: IconButton(
                      tooltip: context.tr(
                        _obscured ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                        _obscured ? 'Show password' : 'Hide password',
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                      icon: Icon(
                        _obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: dark ? Colors.white : _forest,
                      ),
                    ),
                    child: TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      obscureText: _obscured,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _signIn(),
                      style: TextStyle(color: fg),
                      decoration: _inputDecoration(
                        context.tr('كلمة المرور', 'Password'),
                        dark,
                      ),
                      validator: (value) => (value ?? '').isEmpty
                          ? context.tr(
                              'أدخل كلمة المرور',
                              'Enter your password',
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: _busy
                              ? null
                              : () => setState(() => _remember = !_remember),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _remember,
                                onChanged: _busy
                                    ? null
                                    : (value) => setState(
                                          () => _remember = value ?? false,
                                        ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                activeColor: const Color(0xFF008650),
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: dark ? _mint : _emerald,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  context.tr(
                                    'تذكرني على هذا الجهاز',
                                    'Remember this device',
                                  ),
                                  maxLines: 2,
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 11.6,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      TextButton(
                        onPressed: _busy ? null : () => _help(recovery: true),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          foregroundColor: dark ? _mint : _emerald,
                        ),
                        child: Text(
                          context.tr('نسيت كلمة المرور؟', 'Forgot password?'),
                          style: const TextStyle(
                            fontSize: 11.6,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Notice(failureText(context, _error!), error: true),
                  ],
                  const SizedBox(height: 13),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _busy ? null : _signIn,
                      borderRadius: BorderRadius.circular(15),
                      child: Ink(
                        height: 49,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF006E51),
                              Color(0xFF008B66),
                              Color(0xFF00543E),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF003D2B)
                                  .withValues(alpha: dark ? .35 : .18),
                              blurRadius: 11,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _busy
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.login_rounded,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                    const SizedBox(width: 11),
                                    Text(
                                      context.tr('تسجيل الدخول', 'Sign in'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          context,
                          dark,
                          context.tr('استعادة الوصول', 'Recover access'),
                          Icons.key_rounded,
                          () => _help(recovery: true),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _quickAction(
                          context,
                          dark,
                          context.tr('الدعم', 'Support'),
                          Icons.support_agent_outlined,
                          () => _help(recovery: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              height: 56,
              width: 57,
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF004E39)
                    : const Color(0xFFDFFFF0),
                border: Border.all(
                  color: dark ? const Color(0xFFA3F9C8) : Colors.white,
                  width: 2.5,
                ),
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: _forest.withValues(alpha: .2),
                    blurRadius: 13,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: dark ? _mint : _forest,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool dark) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: dark ? const Color(0xFFB7CECA) : const Color(0xFF82858D),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
      );

  Widget _input(
    BuildContext context,
    bool dark, {
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 49),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0x8500312A)
            : const Color(0xFFF7F8FA),
        border: Border.all(
          color: dark
              ? const Color(0xAA95C9BE)
              : const Color(0xFFDAE1E6),
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const SizedBox(width: 5),
          Container(
            width: 36,
            height: 37,
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF494A31)
                  : const Color(0xFFFFF0E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: dark ? const Color(0xFFF1CE87) : const Color(0xFF805004),
              size: 22,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(child: child),
          if (trailing != null) trailing,
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context,
    bool dark,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) =>
      Material(
        color: dark ? const Color(0xFF12644E) : const Color(0xFFDDF9EB),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: SizedBox(
            height: 47,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: dark ? Colors.white : const Color(0xFF00543D),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark ? Colors.white : const Color(0xFF003B2D),
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _securityNotice(BuildContext context, bool dark) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 21),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xB5176954)
                : const Color(0xD7D7F8EA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: dark ? _mint : _emerald,
                size: 28,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  context.tr(
                    'يتم حفظ الجلسة بأمان ولا يتم تخزين كلمة المرور',
                    'Your session is stored securely and your password is not saved',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark ? Colors.white : _forest,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _contractBadge(BuildContext context, bool dark) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xBF0B4C3C)
                : const Color(0xDFF0FFF6),
            border: Border.all(
              color: dark
                  ? const Color(0x9079D9AF)
                  : const Color(0xFFB9F1D4),
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dns_outlined,
                size: 19,
                color: dark ? _mint : _forest,
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('إصدار العقد v2', 'Contract version v2'),
                style: TextStyle(
                  color: dark ? Colors.white : _forest,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.circle,
                size: 9,
                color: Color(0xFF00B65F),
              ),
            ],
          ),
        ),
      );
}
