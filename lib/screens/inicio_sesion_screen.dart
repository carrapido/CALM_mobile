import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/demo_client_access.dart';
import '../models/login_form.dart';
import '../routes/app_routes.dart';
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
  const InicioSesionScreen({super.key});

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  final _phoneController = TextEditingController();
  final _nipController = TextEditingController();
  final _nipFocus = FocusNode();
  bool _showsProblem = false;
  bool _hadCompletePhone = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nipController.dispose();
    _nipFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final problem = _showsProblem ? _currentProblem() : null;
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
                    _credentialsGroup(problem?.field),
                    if (problem != null) _ProblemMessage(problem.message),
                    const SizedBox(height: 20),
                    ActionButton.primary(label: AppConstants.btnVerPedidos, onPressed: _signIn),
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

  LoginProblem? _currentProblem() {
    final form = LoginForm(phone: _phoneController.text, nip: _nipController.text);
    final credentialsMatch = DemoClientAccess.owns(phoneDigits: form.phoneDigits, nip: form.nip);
    return form.firstProblem(credentialsMatch: credentialsMatch);
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
          onChanged: (_) => _hideProblem(),
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
    _hideProblem();
    if (justCompleted) _nipFocus.requestFocus();
  }

  void _hideProblem() {
    if (_showsProblem) setState(() => _showsProblem = false);
  }

  void _signIn() {
    if (_currentProblem() != null) {
      setState(() => _showsProblem = true);
      return;
    }
    Navigator.of(context).pushReplacementNamed(AppRoutes.orders);
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
