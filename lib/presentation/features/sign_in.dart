import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/scope.dart';
import '../shared/widgets.dart';

/// H02: presentation-only sign-in redesign. Authentication stays in AgentApp.
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  static const _green = Color(0xFF00543E);
  static const _deep = Color(0xFF004735);
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _hidden = true;
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
    if (_busy || !_form.currentState!.validate()) return;
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
    } catch (e) {
      if (mounted) setState(() => _error = e);
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
        content: Text(
          context.tr(
            'حساب الطبيب والوكيل يُدار بواسطة الإدارة. تواصل مع مسؤول الفرع لاستعادة كلمة المرور أو طلب الدعم. لا ترسل كلمة المرور إلى أي شخص.',
            'Doctor and agent accounts are managed by your organization. Contact your branch administrator to recover access or ask for support. Never share your password.',
          ),
        ),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF5FBF9),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FBF9),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F8F2), Color(0xFFF9FCFB), Color(0xFFF6FBF9)],
            ),
          ),
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _hero(context),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(15, 9, 15, 0),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 21),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .96),
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _green.withValues(alpha: .13),
                                      blurRadius: 28,
                                      offset: const Offset(0, 9),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(15, 43, 15, 18),
                                child: Form(
                                  key: _form,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const _Leaf(),
                                          const SizedBox(width: 13),
                                          Text(
                                            context.tr('تسجيل الدخول', 'Sign in'),
                                            style: const TextStyle(
                                              color: _deep,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          const SizedBox(width: 13),
                                          const _Leaf(mirrored: true),
                                        ],
                                      ),
                                      const SizedBox(height: 17),
                                      _field(
                                        icon: Icons.mail_outline_rounded,
                                        child: TextFormField(
                                          controller: _email,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.right,
                                          autofillHints: const [AutofillHints.username],
                                          decoration: _decoration(context.tr('البريد الإلكتروني', 'Email address')),
                                          validator: (value) {
                                            final text = value?.trim() ?? '';
                                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                                                ? null
                                                : context.tr('أدخل بريدًا إلكترونيًا صالحًا', 'Enter a valid email address');
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _field(
                                        icon: Icons.lock_outline_rounded,
                                        trailing: IconButton(
                                          onPressed: () => setState(() => _hidden = !_hidden),
                                          tooltip: context.tr(
                                            _hidden ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                                            _hidden ? 'Show password' : 'Hide password',
                                          ),
                                          icon: Icon(
                                            _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: _green,
                                            size: 21,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _password,
                                          obscureText: _hidden,
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.right,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [AutofillHints.password],
                                          onFieldSubmitted: (_) => _signIn(),
                                          decoration: _decoration(context.tr('كلمة المرور', 'Password')),
                                          validator: (value) => (value ?? '').isEmpty
                                              ? context.tr('أدخل كلمة المرور', 'Enter your password')
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: InkWell(
                                              onTap: () => setState(() => _remember = !_remember),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Checkbox(
                                                    value: _remember,
                                                    onChanged: (value) => setState(() => _remember = value ?? false),
                                                    activeColor: const Color(0xFF007845),
                                                    side: const BorderSide(color: _green, width: 1.5),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    visualDensity: VisualDensity.compact,
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      context.tr('تذكرني على هذا الجهاز', 'Remember this device'),
                                                      maxLines: 2,
                                                      style: const TextStyle(
                                                        color: Color(0xFF193832),
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          TextButton(
                                            onPressed: () => _help(recovery: true),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 3),
                                              minimumSize: const Size(0, 40),
                                              foregroundColor: const Color(0xFF007340),
                                            ),
                                            child: Text(
                                              context.tr('نسيت كلمة المرور؟', 'Forgot password?'),
                                              style: const TextStyle(
                                                fontSize: 12.3,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 7),
                                        Notice(failureText(context, _error!), error: true),
                                      ],
                                      const SizedBox(height: 15),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _busy ? null : _signIn,
                                          borderRadius: BorderRadius.circular(15),
                                          child: Ink(
                                            height: 47,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF00664B), Color(0xFF00835E), Color(0xFF00573F)],
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _green.withValues(alpha: .16),
                                                  offset: const Offset(0, 5),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: _busy
                                                  ? const SizedBox(
                                                      height: 23,
                                                      width: 23,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.4,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.login_rounded, color: Colors.white, size: 24),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          context.tr('تسجيل الدخول', 'Sign in'),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 19,
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
                                              context.tr('استعادة الوصول', 'Recover access'),
                                              Icons.key_rounded,
                                              () => _help(recovery: true),
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: _quickAction(
                                              context.tr('الدعم', 'Support'),
                                              Icons.support_agent_rounded,
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
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF1FFF8), Color(0xFFDBF8EC)],
                                    ),
                                    border: Border.all(color: Colors.white, width: 3),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                        color: _green.withValues(alpha: .08),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.lock_outline_rounded, size: 32, color: _deep),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F7ED),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCEF3E1),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(Icons.verified_user_outlined, color: _green, size: 25),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr(
                                      'يتم حفظ الجلسة بشكل آمن ولا يتم حفظ كلمة المرور',
                                      'Your session is protected; your password is never saved',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF2C5550),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F8EF),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dns_outlined, size: 19, color: _green),
                                const SizedBox(width: 9),
                                Text(
                                  context.tr('إصدار العقد v2', 'Contract version v2'),
                                  style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 9),
                                const Icon(Icons.circle, size: 9, color: Color(0xFF00AF57)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF7F858D),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        isDense: true,
      );

  Widget _field({required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 49),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE3E6), width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              height: 39,
              width: 35,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF85540C), size: 23),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(child: child),
          if (trailing != null) trailing,
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFE7FAF2),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _green, size: 23),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF053D2C), fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 195 + top,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF004A43), Color(0xFF006343), Color(0xFF00835C)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            left: -8,
            width: 225,
            height: 133,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, .65, 1],
                colors: [Colors.white, Colors.white, Colors.transparent],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/login_animals.webp',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/agent_field.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _HeroWaves())),
          ),
          Positioned(
            top: top + 13,
            left: 16,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/branding/mazraa.png',
                      height: 42,
                      width: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mazraa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Agent',
                        style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 47,
            right: 17,
            left: 133,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.tr('مرحباً بك', 'Welcome'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'سجّل الدخول للوصول إلى عمليات الطبيب والوكيل',
                    'Sign in to access doctor and agent operations',
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.8,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD997),
                    borderRadius: BorderRadius.circular(12),
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

class _Leaf extends StatelessWidget {
  const _Leaf({this.mirrored = false});
  final bool mirrored;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: mirrored ? -0.7 : 0.7,
        child: const Icon(Icons.eco_rounded, color: Color(0xFF83E1B4), size: 17),
      );
}

class _HeroWaves extends CustomPainter {
  const _HeroWaves();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gold = Path()
      ..moveTo(0, h - 28)
      ..quadraticBezierTo(w * .23, h + 3, w * .49, h - 21)
      ..quadraticBezierTo(w * .76, h - 47, w, h - 62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      gold,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEBC57B), Color(0xFF4CA56A), Color(0xFFF4CF8A)],
        ).createShader(Offset.zero & size),
    );
    final wave = Path()
      ..moveTo(0, h - 19)
      ..quadraticBezierTo(w * .22, h + 8, w * .49, h - 17)
      ..quadraticBezierTo(w * .73, h - 42, w, h - 51)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFFF5FBF9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
).hasMatch(text)
                                                ? null
                                                : context.tr('أدخل بريدًا إلكترونيًا صالحًا', 'Enter a valid email address');
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _field(
                                        icon: Icons.lock_outline_rounded,
                                        trailing: IconButton(
                                          onPressed: () => setState(() => _hidden = !_hidden),
                                          tooltip: context.tr(
                                            _hidden ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
                                            _hidden ? 'Show password' : 'Hide password',
                                          ),
                                          icon: Icon(
                                            _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: _green,
                                            size: 21,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _password,
                                          obscureText: _hidden,
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.right,
                                          textInputAction: TextInputAction.done,
                                          autofillHints: const [AutofillHints.password],
                                          onFieldSubmitted: (_) => _signIn(),
                                          decoration: _decoration(context.tr('كلمة المرور', 'Password')),
                                          validator: (value) => (value ?? '').isEmpty
                                              ? context.tr('أدخل كلمة المرور', 'Enter your password')
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: InkWell(
                                              onTap: () => setState(() => _remember = !_remember),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Checkbox(
                                                    value: _remember,
                                                    onChanged: (value) => setState(() => _remember = value ?? false),
                                                    activeColor: const Color(0xFF007845),
                                                    side: const BorderSide(color: _green, width: 1.5),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                    visualDensity: VisualDensity.compact,
                                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      context.tr('تذكرني على هذا الجهاز', 'Remember this device'),
                                                      maxLines: 2,
                                                      style: const TextStyle(
                                                        color: Color(0xFF193832),
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          TextButton(
                                            onPressed: () => _help(recovery: true),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 3),
                                              minimumSize: const Size(0, 40),
                                              foregroundColor: const Color(0xFF007340),
                                            ),
                                            child: Text(
                                              context.tr('نسيت كلمة المرور؟', 'Forgot password?'),
                                              style: const TextStyle(
                                                fontSize: 12.3,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_error != null) ...[
                                        const SizedBox(height: 7),
                                        Notice(failureText(context, _error!), error: true),
                                      ],
                                      const SizedBox(height: 15),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _busy ? null : _signIn,
                                          borderRadius: BorderRadius.circular(15),
                                          child: Ink(
                                            height: 47,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF00664B), Color(0xFF00835E), Color(0xFF00573F)],
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _green.withValues(alpha: .16),
                                                  offset: const Offset(0, 5),
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: _busy
                                                  ? const SizedBox(
                                                      height: 23,
                                                      width: 23,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2.4,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.login_rounded, color: Colors.white, size: 24),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          context.tr('تسجيل الدخول', 'Sign in'),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w800,
                                                            fontSize: 19,
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
                                              context.tr('استعادة الوصول', 'Recover access'),
                                              Icons.key_rounded,
                                              () => _help(recovery: true),
                                            ),
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: _quickAction(
                                              context.tr('الدعم', 'Support'),
                                              Icons.support_agent_rounded,
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
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF1FFF8), Color(0xFFDBF8EC)],
                                    ),
                                    border: Border.all(color: Colors.white, width: 3),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 12,
                                        offset: const Offset(0, 5),
                                        color: _green.withValues(alpha: .08),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.lock_outline_rounded, size: 32, color: _deep),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F7ED),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCEF3E1),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Icon(Icons.verified_user_outlined, color: _green, size: 25),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.tr(
                                      'يتم حفظ الجلسة بشكل آمن ولا يتم حفظ كلمة المرور',
                                      'Your session is protected; your password is never saved',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF2C5550),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F8EF),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.dns_outlined, size: 19, color: _green),
                                const SizedBox(width: 9),
                                Text(
                                  context.tr('إصدار العقد v2', 'Contract version v2'),
                                  style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 9),
                                const Icon(Icons.circle, size: 9, color: Color(0xFF00AF57)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF7F858D),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        filled: false,
        isDense: true,
      );

  Widget _field({required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 49),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE3E6), width: 1),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              height: 39,
              width: 35,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF85540C), size: 23),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(child: child),
          if (trailing != null) trailing,
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFE7FAF2),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _green, size: 23),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF053D2C), fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 195 + top,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF004A43), Color(0xFF006343), Color(0xFF00835C)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            left: -8,
            width: 225,
            height: 133,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0, .65, 1],
                colors: [Colors.white, Colors.white, Colors.transparent],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                'assets/images/login_animals.webp',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/images/agent_field.webp',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _HeroWaves())),
          ),
          Positioned(
            top: top + 13,
            left: 16,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/branding/mazraa.png',
                      height: 42,
                      width: 42,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mazraa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Agent',
                        style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 47,
            right: 17,
            left: 133,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  context.tr('مرحباً بك', 'Welcome'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'سجّل الدخول للوصول إلى عمليات الطبيب والوكيل',
                    'Sign in to access doctor and agent operations',
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.8,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD997),
                    borderRadius: BorderRadius.circular(12),
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

class _Leaf extends StatelessWidget {
  const _Leaf({this.mirrored = false});
  final bool mirrored;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: mirrored ? -0.7 : 0.7,
        child: const Icon(Icons.eco_rounded, color: Color(0xFF83E1B4), size: 17),
      );
}

class _HeroWaves extends CustomPainter {
  const _HeroWaves();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gold = Path()
      ..moveTo(0, h - 28)
      ..quadraticBezierTo(w * .23, h + 3, w * .49, h - 21)
      ..quadraticBezierTo(w * .76, h - 47, w, h - 62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      gold,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFEBC57B), Color(0xFF4CA56A), Color(0xFFF4CF8A)],
        ).createShader(Offset.zero & size),
    );
    final wave = Path()
      ..moveTo(0, h - 19)
      ..quadraticBezierTo(w * .22, h + 8, w * .49, h - 17)
      ..quadraticBezierTo(w * .73, h - 42, w, h - 51)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFFF5FBF9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
