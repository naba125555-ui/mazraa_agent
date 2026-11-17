import 'package:flutter/material.dart';

import '../../domain/screens.dart';
import '../design/screen_design.dart';
import '../shared/scope.dart';
import '../shared/widgets.dart';

const entryRoutes = {'H01', 'H02', 'H03'};

class EntryPage extends StatelessWidget {
  const EntryPage({super.key, this.route = 'H01'});
  final String route;

  void open(BuildContext context, String target) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: target),
      builder: (_) => EntryPage(route: target),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final design = screenDesigns[route]!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BrandLogo(size: 32),
            const SizedBox(width: 10),
            Text(context.tr('مزرعتي', 'Mazraa')),
          ],
        ),
        actions: [
          if (route != 'H03')
            TextButton.icon(
              icon: const Icon(Icons.language, size: 18),
              label: Text(context.app.ar ? 'English' : 'العربية'),
              onPressed: () => context.app.preferences(
                language: context.app.ar ? 'en' : 'ar',
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 510),
            child: PageBody(
              children: [
                if (route == 'H01') ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/agent_workspace.webp',
                      height: 252,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr(
                        'مزرعتي للطبيب والوكيل',
                        'Mazraa for doctors and agents',
                      ),
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    context.tr(design.ar, design.en),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: () => open(context, 'H02'),
                    icon: const Icon(Icons.login),
                    label: Text(context.tr('تسجيل الدخول', 'Sign in')),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => open(context, 'H03'),
                    child: Text(
                      context.tr(
                        'احتاج إلى مساعدة في الدخول',
                        'I need help signing in',
                      ),
                    ),
                  ),
                ] else ...[
                  ScreenIntroduction(screen(route)),
                  const SizedBox(height: 12),
                  if (route == 'H02')
                    _SignInForm(onRecover: () => open(context, 'H03')),
                  if (route == 'H03') ...[
                    Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 42,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr(
                              'أرسل لمسؤول الفرع بريد حسابك واطلب إعادة تعيين كلمة المرور أو تجديد الاعتماد.',
                              'Give your branch administrator your account email and ask them to reset your password or renew your approval.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final navigator = Navigator.of(context);
                        if (navigator.canPop()) {
                          navigator.pop();
                        } else {
                          open(context, 'H02');
                        }
                      },
                      child: Text(context.tr('العودة', 'Go back')),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm({required this.onRecover});
  final VoidCallback onRecover;

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool hidden = true;
  bool busy = false;
  Object? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final navigator = Navigator.of(context);
    final app = context.app;
    try {
      await app.login(email.text, password.text);
      if (mounted) navigator.popUntil((route) => route.isFirst);
    } catch (failure) {
      if (mounted) setState(() => error = failure);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
    child: AutofillGroup(
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                labelText: context.tr('البريد الإلكتروني', 'Email'),
                prefixIcon: const Icon(Icons.alternate_email),
              ),
              validator: (value) => (value ?? '').contains('@')
                  ? null
                  : context.tr('أدخل بريدًا صالحًا', 'Enter a valid email'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: password,
              obscureText: hidden,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => submit(),
              decoration: InputDecoration(
                labelText: context.tr('كلمة المرور', 'Password'),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: hidden
                      ? context.tr('إظهار كلمة المرور', 'Show password')
                      : context.tr('إخفاء كلمة المرور', 'Hide password'),
                  onPressed: () => setState(() => hidden = !hidden),
                  icon: Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value ?? '').isEmpty
                  ? context.tr('أدخل كلمة المرور', 'Enter your password')
                  : null,
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Notice(failureText(context, error!), error: true),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: busy ? null : submit,
              child: busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('دخول', 'Sign in')),
            ),
            TextButton(
              onPressed: busy ? null : widget.onRecover,
              child: Text(context.tr('نسيت كلمة المرور؟', 'Forgot password?')),
            ),
          ],
        ),
      ),
    ),
  );
}
