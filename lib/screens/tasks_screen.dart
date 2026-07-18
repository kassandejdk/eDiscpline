// lib/screens/tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import 'budget_screen.dart' show confirmDelete;

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final tasks = provider.tasksForDate(_selectedDate);
    final doneCount = tasks.where((t) => t.isDone).length;
    final progress = tasks.isEmpty ? 0.0 : doneCount / tasks.length;
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: kScaffold,
      appBar: AppBar(
        title: const Text('Mes Tâches'),
        backgroundColor: kDark,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kHeaderGradient)),
        bottom: const BrandAccentLine(),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context, provider),
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date selector
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (_, i) {
                final day = now.subtract(Duration(days: 3 - i));
                final isSelected = day.year == _selectedDate.year &&
                    day.month == _selectedDate.month &&
                    day.day == _selectedDate.day;
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 54,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? kPrimary : isToday ? kPrimary.withOpacity(0.3) : const Color(0x18000000),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayNames[day.weekday - 1],
                            style: GoogleFonts.poppins(fontSize: 11,
                                color: isSelected ? Colors.white60 : Colors.black38)),
                        const SizedBox(height: 3),
                        Text('${day.day}',
                            style: GoogleFonts.poppins(fontSize: 19, fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 56, height: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFEEEEEE),
                          color: progress == 1.0 ? kSuccess : kPrimary,
                          strokeWidth: 6,
                        ),
                        Center(
                          child: Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: progress == 1.0 ? kSuccess : kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$doneCount / ${tasks.length} tâches',
                          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                      Text('complétées', style: GoogleFonts.poppins(color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                  if (progress == 1.0 && tasks.isNotEmpty) ...[
                    const Spacer(),
                    const Text('🎉', style: TextStyle(fontSize: 28)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, size: 52, color: Colors.black26),
                  const SizedBox(height: 12),
                  Text('Aucune tâche pour ce jour',
                      style: GoogleFonts.poppins(color: Colors.black45)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15)
                    ),
                    onPressed: () => _showTaskDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une tâche'),
                  ),
                ],
              ),
            )
          else
            ...tasks.map((task) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TaskItem(
                    task: task,
                    onToggle: () => provider.toggleTask(task.id),
                    onEdit: () => _showTaskDialog(context, provider, task: task),
                    onDelete: () async {
                      final ok = await confirmDelete(context, 'Supprimer la tâche "${task.title}" ?');
                      if (ok) provider.deleteTask(task.id);
                    },
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showTaskDialog(BuildContext context, AppProvider provider, {DailyTask? task}) {
    final isEdit = task != null;
    final titleCtrl = TextEditingController(text: task?.title ?? '');
    String? pickedTime = (task?.time?.trim().isNotEmpty ?? false) ? task!.time : null;

    showFormSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Modifier la tâche' : 'Nouvelle tâche',
                style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'ex: Lire 30 min finance',
                prefixIcon: Icon(Icons.task_alt_outlined),
              ),
            ),
            const SizedBox(height: 14),
            // Heure du rappel : ouvre un sélecteur d'heure (format valide garanti)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final parsed = NotificationService.parseTime(pickedTime);
                final initial = parsed != null
                    ? TimeOfDay(hour: parsed.$1, minute: parsed.$2)
                    : TimeOfDay.now();
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: initial,
                  builder: (c, w) => MediaQuery(
                    data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true),
                    child: w!,
                  ),
                );
                if (t != null) {
                  setS(() => pickedTime =
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x1A000000)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 20, color: pickedTime == null ? Colors.black38 : kPrimary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        pickedTime == null ? 'Heure du rappel (optionnel)' : 'Rappel à $pickedTime',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: pickedTime == null ? Colors.black45 : Colors.black87,
                          fontWeight: pickedTime == null ? FontWeight.w400 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (pickedTime != null)
                      GestureDetector(
                        onTap: () => setS(() => pickedTime = null),
                        child: const Icon(Icons.close, size: 18, color: Colors.black38),
                      ),
                  ],
                ),
              ),
            ),
            if (pickedTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, size: 15, color: kSuccess),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Tu seras alerté à $pickedTime si la tâche n'est pas encore faite.",
                      style: GoogleFonts.poppins(fontSize: 11, color: kSuccess),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      if (title.isNotEmpty) {
                        if (isEdit) {
                          provider.updateTask(task!.id, title, pickedTime);
                        } else {
                          provider.addTask(title, _selectedDate, pickedTime);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TaskItem({required this.task, required this.onToggle, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isDone ? kSuccess : Colors.transparent,
              border: Border.all(color: task.isDone ? kSuccess : Colors.black26, width: 2),
            ),
            child: task.isDone ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
          ),
        ),
        title: Text(task.title,
            style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w500,
              decoration: task.isDone ? TextDecoration.lineThrough : null,
              color: task.isDone ? Colors.black38 : Colors.black87,
            )),
        subtitle: task.time != null
            ? Text(task.time!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black45))
            : null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.black38),
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: kDanger))),
          ],
        ),
      ),
    );
  }
}
