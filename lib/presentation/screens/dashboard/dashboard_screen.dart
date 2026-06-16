import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsStreamProvider);
    final todaySessions = ref.watch(todaysSessionsProvider);
    final todayAttendance = ref.watch(todaysAttendanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('السلام عليكم 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 4),
          Text('إليك نشاط يومك',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              StatCard(
                  icon: Icons.people_alt_rounded,
                  label: 'الطلاب',
                  value: students.maybeWhen(
                      data: (s) => s.length.toString(), orElse: () => '–')),
              StatCard(
                  icon: Icons.menu_book_rounded,
                  label: 'جلسات اليوم',
                  value: todaySessions.maybeWhen(
                      data: (s) => s.length.toString(), orElse: () => '–')),
              StatCard(
                  icon: Icons.check_circle_outline,
                  label: 'الحاضرون',
                  value: todayAttendance.maybeWhen(
                      data: (s) => s
                          .where((a) => a.status.name == 'present')
                          .length
                          .toString(),
                      orElse: () => '–')),
              StatCard(
                  icon: Icons.event_busy_outlined,
                  label: 'الغائبون',
                  value: todayAttendance.maybeWhen(
                      data: (s) => s
                          .where((a) => a.status.name == 'absent')
                          .length
                          .toString(),
                      orElse: () => '–')),
            ],
          ),
          const SizedBox(height: 24),
          _ActionTile(
            icon: Icons.people_outline,
            title: 'طلابي',
            subtitle: 'عرض وإدارة الطلاب',
            onTap: () => context.push('/students'),
          ),
          _ActionTile(
            icon: Icons.checklist_rtl,
            title: 'حضور اليوم',
            subtitle: 'تسجيل الحاضرين والغائبين',
            onTap: () => context.push('/attendance'),
          ),
          _ActionTile(
            icon: Icons.insights_outlined,
            title: 'التقارير',
            subtitle: 'إحصائيات شاملة',
            onTap: () => context.push('/reports'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(.1),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left),
          onTap: onTap,
        ),
      ),
    );
  }
}
