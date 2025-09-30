import 'package:flutter/material.dart';
import 'package:newgraduate/widgets/video_banner.dart';
import 'project_details_screen.dart';
import '../data/project_type_data.dart';

class ProjectTypeCard extends StatefulWidget {
  final String arabicTitle;
  final String englishTitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const ProjectTypeCard({
    super.key,
    required this.arabicTitle,
    required this.englishTitle,
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<ProjectTypeCard> createState() => _ProjectTypeCardState();
}

class _ProjectTypeCardState extends State<ProjectTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? theme.colorScheme.primaryContainer
                : isDark
                    ? theme.cardColor
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(_isPressed ? 0.1 : 0.2),
                blurRadius: 8,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
            border: Border.all(
              color: widget.isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withOpacity(0.5),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.arabicTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.englishTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String? _selectedProjectType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('مشاريع التخرج'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // banner placeholder (clickable thumbnail opens YouTube)
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            // VideoBanner inserted below
            // ignore: prefer_const_constructors
            VideoBanner(videoId: '6GomxOCJTfU'),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.category,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'اختر نوع المشروع',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProjectTypeCard(
                    arabicTitle: 'مشاريع برمجية',
                    englishTitle: 'Software Projects',
                    icon: Icons.computer_rounded,
                    isSelected: _selectedProjectType == 'software',
                    onTap: () {
                      setState(() => _selectedProjectType = 'software');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsScreen(
                            type: 'software',
                            title: ProjectTypeData
                                .projectTypes['software']!['title'] as String,
                            description: ProjectTypeData
                                    .projectTypes['software']!['description']
                                as String,
                            examples: (ProjectTypeData
                                        .projectTypes['software']!['examples']
                                    as List)
                                .cast<String>(),
                            howToWrite: (ProjectTypeData
                                        .projectTypes['software']!['howToWrite']
                                    as List)
                                .cast<String>(),
                          ),
                        ),
                      );
                    },
                  ),
                  ProjectTypeCard(
                    arabicTitle: 'مشاريع عتاد',
                    englishTitle: 'Hardware Projects',
                    icon: Icons.memory_rounded,
                    isSelected: _selectedProjectType == 'hardware',
                    onTap: () {
                      setState(() => _selectedProjectType = 'hardware');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsScreen(
                            type: 'hardware',
                            title: ProjectTypeData
                                .projectTypes['hardware']!['title'] as String,
                            description: ProjectTypeData
                                    .projectTypes['hardware']!['description']
                                as String,
                            examples: (ProjectTypeData
                                        .projectTypes['hardware']!['examples']
                                    as List)
                                .cast<String>(),
                            howToWrite: (ProjectTypeData
                                        .projectTypes['hardware']!['howToWrite']
                                    as List)
                                .cast<String>(),
                          ),
                        ),
                      );
                    },
                  ),
                  ProjectTypeCard(
                    arabicTitle: 'مشاريع متكاملة',
                    englishTitle: 'Hardware + Software',
                    icon: Icons.hub_rounded,
                    isSelected: _selectedProjectType == 'integrated',
                    onTap: () {
                      setState(() => _selectedProjectType = 'integrated');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProjectDetailsScreen(
                            type: 'integrated',
                            title: ProjectTypeData
                                .projectTypes['integrated']!['title'] as String,
                            description: ProjectTypeData
                                    .projectTypes['integrated']!['description']
                                as String,
                            examples: (ProjectTypeData
                                        .projectTypes['integrated']!['examples']
                                    as List)
                                .cast<String>(),
                            howToWrite: (ProjectTypeData.projectTypes[
                                    'integrated']!['howToWrite'] as List)
                                .cast<String>(),
                          ),
                        ),
                      );
                    },
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
