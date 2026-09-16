import 'package:flutter/material.dart';

// 1. Pindahkan breakpoint ke satu konstanta bernama
const double kWideBreakpoint = 700.0;

void main() => runApp(const DashboardApp());

class DashboardApp extends StatefulWidget {
  const DashboardApp({super.key});

  @override
  State<DashboardApp> createState() => _DashboardAppState();
}

class _DashboardAppState extends State<DashboardApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academic Overview',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: AcademicOverviewPage(
        isDark: _isDark,
        onDarkChanged: (value) => setState(() => _isDark = value),
      ),
    );
  }
}

class AcademicOverviewPage extends StatelessWidget {
  const AcademicOverviewPage({
    required this.isDark,
    required this.onDarkChanged,
    super.key,
  });

  final bool isDark;
  final ValueChanged<bool> onDarkChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politeknik Negeri Malang'),
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode),
              const SizedBox(width: 8),
              Semantics(
                label: 'Toggle Dark Mode',
                hint: 'Mengubah tema antara terang dan gelap',
                toggled: isDark,
                child: Switch.adaptive(
                  value: isDark,
                  onChanged: onDarkChanged,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= kWideBreakpoint;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profil
                const ProfileHeader(),
                const SizedBox(height: 20),

                // Responsive Layout untuk Kartu Informasi
                if (isWide)
                  const Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: InfoCard(
                              title: 'Assignments',
                              value: '8',
                              icon: Icons.assignment,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: InfoCard(
                              title: 'Attendance',
                              value: '92%',
                              icon: Icons.calendar_today,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InfoCard(
                              title: 'Portfolio',
                              value: 'Ready',
                              icon: Icons.folder,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: InfoCard(
                              title: 'Current Week',
                              value: '02',
                              icon: Icons.timeline,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  const Column(
                    children: [
                      InfoCard(
                        title: 'Assignments',
                        value: '8',
                        icon: Icons.assignment,
                      ),
                      SizedBox(height: 16),
                      InfoCard(
                        title: 'Attendance',
                        value: '92%',
                        icon: Icons.calendar_today,
                      ),
                      SizedBox(height: 16),
                      InfoCard(
                        title: 'Portfolio',
                        value: 'Ready',
                        icon: Icons.folder,
                      ),
                      SizedBox(height: 16),
                      InfoCard(
                        title: 'Current Week',
                        value: '02',
                        icon: Icons.timeline,
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Reusable Header Profil Widget
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Informasi Profil Mahasiswa',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                'M',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mohamat Fauzi Rohman',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Jurusan Teknologi Informasi',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable InfoCard Widget
class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$title: $value',
      container: true,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}