import 'package:alnisa_store/blocs/auth/auth_cubit.dart';
import 'package:alnisa_store/blocs/auth/auth_state.dart';
import 'package:alnisa_store/blocs/main_navigation/main_tab_cubit.dart';
import 'package:alnisa_store/constants/app_colors.dart';
import 'package:alnisa_store/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
      ),
      body: switch (authState.status) {
        AuthStatus.unknown => const Center(child: CircularProgressIndicator()),
        AuthStatus.unauthenticated => const _UnauthenticatedAccountView(),
        AuthStatus.authenticated => _AuthenticatedAccountView(
          email: authState.email,
        ),
      },
    );
  }
}

class _UnauthenticatedAccountView extends StatelessWidget {
  const _UnauthenticatedAccountView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileHeaderCard(
            title: 'Sign In',
            subtitle: 'Personalize details, view your profile, and track your orders.',
            icon: Icons.person_outline,
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(RoutesName.signIn);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'INFORMATION'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                title: 'About',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.about),
              ),
              _SettingsRow(
                title: 'Contact Us',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.contactUs),
              ),
              _SettingsRow(
                title: 'Terms',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.terms),
              ),
              _SettingsRow(
                title: 'Privacy',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.privacy),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthenticatedAccountView extends StatelessWidget {
  const _AuthenticatedAccountView({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProfileHeaderCard(
            title: email ?? 'Unknown user',
            subtitle: 'Apple-style account summary',
            icon: Icons.person,
          ),
          const SizedBox(height: 22),
          const _SectionHeader(title: 'ACCOUNT'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                title: 'My Orders',
                onTap: () => _openTodoScreen(context, title: 'My Orders'),
              ),
              _SettingsRow(
                title: 'Wishlist',
                onTap: () => context.read<MainTabCubit>().changeTab(2),
              ),
              _SettingsRow(
                title: 'Addresses',
                onTap: () => _openTodoScreen(context, title: 'Addresses'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'INFORMATION'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                title: 'About',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.about),
              ),
              _SettingsRow(
                title: 'Contact Us',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.contactUs),
              ),
              _SettingsRow(
                title: 'Terms',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.terms),
              ),
              _SettingsRow(
                title: 'Privacy',
                onTap: () => Navigator.of(context).pushNamed(RoutesName.privacy),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            children: [
              _SettingsRow(
                title: 'Sign Out',
                titleColor: Colors.red,
                showChevron: false,
                onTap: () => context.read<AuthCubit>().signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTodoScreen(BuildContext context, {required String title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Text('$title feature coming soon.'),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 10),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.onTap,
    this.showChevron = true,
    this.titleColor,
  });

  final String title;
  final VoidCallback onTap;
  final bool showChevron;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE7E7ED), width: 0.7),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: titleColor ?? Colors.black87,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
