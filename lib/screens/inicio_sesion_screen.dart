import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/login_form.dart';
import '../routes/app_routes.dart';
import '../services/client_access.dart';
import '../services/supabase_client_access.dart';
import '../themes/app_colors.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/telefono_formatter.dart';
import '../widgets/action_button.dart';
import '../widgets/help_sheet.dart';
import '../widgets/icon_row.dart';
import '../widgets/inset_group.dart';
import '../widgets/labeled_field_row.dart';
import '../widgets/page_heading.dart';
import '../widgets/press_scale.dart';
import '../widgets/section_header.dart';
import '../widgets/top_app_bar_widget.dart';

/// Entrada: the client signs in with phone and NIP, or starts booking a first appointment.
class InicioSesionScreen extends StatefulWidget {
  const InicioSesionScreen({super.key, this.access});

  /// Who checks the phone and the NIP. Tests pass their own; the app talks to Supabase.
  final ClientAccess? access;

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _phoneController = TextEditingController();
  final _nipController = TextEditingController();
  final _nipFocus = FocusNode();
  late final ClientAccess _access =
      widget.access ?? SupabaseClientAccess(Supabase.instance.client);
  String? _message;
  LoginField? _invalidField;
  bool _isSigningIn = false;
  bool _hadCompletePhone = false;

  // Counts edits, so an answer for a pair the client has since changed is recognized as stale.
  int _formVersion = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _nipController.dispose();
    _nipFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.groupedBackground,
      appBar: TopAppBarWidget(onHelpPressed: _openHelp),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeading(
                      AppConstants.loginTitle,
                      subtitle: AppConstants.loginSubtitle,
                    ),
                    _credentialsGroup(_invalidField),
                    if (_message != null) _ProblemMessage(_message!),
                    const SizedBox(height: 20),
                    ActionButton.primary(
                      label: _isSigningIn ? AppConstants.btnEntrando : AppConstants.btnVerPedidos,
                      onPressed: _isSigningIn ? null : _signIn,
                    ),
                    const SizedBox(height: 4),
                    _ForgotNipButton(onPressed: _openHelp),
                    const Spacer(),
                    const SizedBox(height: 24),
                    _FirstVisitCard(onTap: _openServices),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openHelp() => showHelpSheet(context);

  Widget _credentialsGroup(LoginField? invalidField) {
    return InsetGroup(
      children: [
        LabeledFieldRow(
          label: AppConstants.labelPhone,
          hint: AppConstants.hintPhone,
          controller: _phoneController,
          isInvalid: invalidField == LoginField.phone,
          minHeight: 54,
          keyboardType: TextInputType.phone,
          inputFormatters: [TelefonoFormatter()],
          textInputAction: TextInputAction.next,
          onChanged: _onPhoneChanged,
        ),
        LabeledFieldRow(
          label: AppConstants.labelNip,
          hint: AppConstants.hintNip,
          controller: _nipController,
          isInvalid: invalidField == LoginField.nip,
          minHeight: 54,
          focusNode: _nipFocus,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(LoginForm.nipLength),
          ],
          obscureText: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => _hideMessage(),
          onSubmitted: (_) => _signIn(),
        ),
      ],
    );
  }

  // Only the moment the phone becomes complete moves on, so editing a complete phone stays put.
  void _onPhoneChanged(String phone) {
    final hasCompletePhone = LoginForm(phone: phone, nip: '').hasCompletePhone;
    final justCompleted = hasCompletePhone && !_hadCompletePhone;
    _hadCompletePhone = hasCompletePhone;
    _hideMessage();
    if (justCompleted) _nipFocus.requestFocus();
  }

  void _hideMessage() {
    _formVersion++;
    if (_message == null) return;
    setState(() {
      _message = null;
      _invalidField = null;
    });
  }

  /// The form's own rules first; only a complete pair is worth a trip to the backend.
  Future<void> _signIn() async {
    if (_isSigningIn) return;
    final form = LoginForm(phone: _phoneController.text, nip: _nipController.text);
    if (form.incompleteProblem case final problem?) {
      _show(problem.message, field: problem.field);
      return;
    }

    final submittedVersion = _formVersion;
    setState(() => _isSigningIn = true);
    final outcome = await _access.signIn(phoneDigits: form.phoneDigits, nip: form.nip);
    if (!mounted) return;
    setState(() => _isSigningIn = false);
    // A refusal speaks of the pair she sent; once she has edited it, it would blame what she
    // typed since. A granted sign-in still counts: her session is already installed.
    final isStale = submittedVersion != _formVersion && outcome is! SignInGranted;
    if (!isStale) _answer(outcome);
  }

  void _answer(SignInOutcome outcome) {
    switch (outcome) {
      case SignInGranted():
        Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
      case SignInRejected():
        // The wording of a wrong pair belongs to the form, so it reads the same as ever.
        _show(LoginForm.mismatch.message, field: LoginForm.mismatch.field);
      case SignInThrottled():
        _show(AppConstants.signInThrottled);
      case SignInUnavailable():
        _show(AppConstants.signInUnavailable);
    }
  }

  void _show(String message, {LoginField? field}) {
    setState(() {
      _message = message;
      _invalidField = field;
    });
  }

  void _openServices() => Navigator.of(context).pushNamed(AppRoutes.services);
}

class _ProblemMessage extends StatelessWidget {
  const _ProblemMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Text(message, style: AppText.footnoteError),
      ),
    );
  }
}

class _ForgotNipButton extends StatelessWidget {
  const _ForgotNipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: AppText.subhead,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: const Text(AppConstants.btnOlvideNip),
      ),
    );
  }
}

class _FirstVisitCard extends StatelessWidget {
  const _FirstVisitCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(AppConstants.labelPrimeraVez, topSpacing: 0),
        PressScale(
          pressedScale: 0.98,
          child: InsetGroup(
            children: [
              IconRow(
                icon: Icons.calendar_today_outlined,
                title: AppConstants.titleAgendaCita,
                subtitle: AppConstants.subtitleAgendaCita,
                minHeight: 64,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
