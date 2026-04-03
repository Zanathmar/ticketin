import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/snack_helper.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // go_router redirect handles navigation automatically when state becomes
    // AuthUnauthenticated. BlocListener is a safety net.
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: const Text('Profile'),
          automaticallyImplyLeading: false,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // Logout no longer emits AuthLoading — goes straight to
            // AuthUnauthenticated, so no spinner needed here.
            if (state is! AuthAuthenticated) return const SizedBox();
            final user = state.user;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAvatar(user),
                  const SizedBox(height: 24),
                  _buildInfoCard(user),
                  const SizedBox(height: 16),
                  _buildActionsCard(context, user),
                  const SizedBox(height: 16),
                  _buildLogoutButton(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'Syne',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(user.name, style: AppTextStyles.headline3),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.role.toUpperCase(),
            style: AppTextStyles.label.copyWith(
                color: AppColors.primary, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _InfoTile(icon: Icons.person_outline, label: 'Name', value: user.name),
          const Divider(height: 1, color: AppColors.cardBorder),
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
          const Divider(height: 1, color: AppColors.cardBorder),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: user.role[0].toUpperCase() + user.role.substring(1),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: () => _showEditSheet(context, user),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _ActionTile(
            icon: Icons.confirmation_number_outlined,
            label: 'My Tickets',
            onTap: () => context.go('/tickets'),
          ),
          if (user.isOrganizer || user.isAdmin) ...[
            const Divider(height: 1, color: AppColors.cardBorder),
            _ActionTile(
              icon: Icons.qr_code_scanner,
              label: 'Scan QR (Check-in)',
              onTap: () => context.push('/scan'),
            ),
            const Divider(height: 1, color: AppColors.cardBorder),
            _ActionTile(
              icon: Icons.qr_code_scanner,
              label: 'Scan QR (Check-out)',
              iconColor: AppColors.warning,
              onTap: () => context.push('/scan-out'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.error),
          foregroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Sign Out',
            style: TextStyle(
                fontFamily: 'Syne', fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?', style: AppTextStyles.headline3),
        content: Text(
          'You will be returned to the login screen.',
          style:
              AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Close dialog first, then dispatch logout.
              // The bloc emits AuthUnauthenticated immediately (no loading state),
              // which triggers go_router redirect → '/login'.
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile', style: AppTextStyles.headline3),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameCtrl,
              style: AppTextStyles.body,
              decoration: InputDecoration(
                labelText: 'Display Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: user.email,
              enabled: false,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textMuted),
              decoration: InputDecoration(
                labelText: 'Email (read-only)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                SnackHelper.info(ctx,
                    'Profile update requires a PATCH /me endpoint — not in current API.');
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textMuted)),
          const Spacer(),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.body),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
