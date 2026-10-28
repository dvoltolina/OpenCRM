import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_scheduler/modules/auth/presentation/widgets/staff_join_forms.dart';

void main() {
  testWidgets('shows admin-specific MFA notice when admin', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaffAccountForm(
              formKey: GlobalKey<FormState>(),
              displayNameController: TextEditingController(),
              emailController: TextEditingController(),
              passwordController: TextEditingController(),
              confirmPasswordController: TextEditingController(),
              businessName: 'Clinic',
              showHipaaNotice: true,
              isAdmin: true,
              isLoading: false,
              errorMessage: null,
              onSubmit: _noop,
              onCancel: _noop,
              onChangeCode: _noop,
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Admin accounts must enroll in two-factor authentication.'),
      findsOneWidget,
    );
  });

  testWidgets('shows admin-only wording for staff view', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StaffAccountForm(
              formKey: GlobalKey<FormState>(),
              displayNameController: TextEditingController(),
              emailController: TextEditingController(),
              passwordController: TextEditingController(),
              confirmPasswordController: TextEditingController(),
              businessName: 'Clinic',
              showHipaaNotice: true,
              isAdmin: false,
              isLoading: false,
              errorMessage: null,
              onSubmit: _noop,
              onCancel: _noop,
              onChangeCode: _noop,
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('Admin accounts on this business must enroll'),
      findsOneWidget,
    );
  });
}

void _noop() {}
