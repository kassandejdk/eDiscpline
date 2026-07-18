// lib/screens/learning_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'budget_screen.dart' show confirmDelete;

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});
  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final _contentCtrl = TextEditingController();
  String _selectedTag = 'Finance';
  String _filterTag = 'Tous';
  final _dateFormat = DateFormat('d MMMM yyyy', 'fr_FR');

  final tags = ['Finance', 'Business', 'Perso', 'Tech', 'Santé', 'Spirituel', 'Autre'];
  final tagColors = <String, (Color, Color)>{
    'Finance': (kPrimaryLight, kPrimary),
    'Business': (Color(0xFFE1F5EE), kSuccess),
    'Perso': (Color(0xFFFBEAF0), Color(0xFF993556)),
    'Tech': (Color(0xFFE6F1FB), Color(0xFF185FA5)),
    'Santé': (Color(0xFFEAF3DE), Color(0xFF3B6D11)),
    'Spirituel': (Color(0xFFFAEEDA), kWarning),
    'Autre': (Color(0xFFF1EFE8), Color(0xFF5F5E5A)),
  };

  (Color, Color) getTagColors(String tag) => tagColors[tag] ?? (kPrimaryLight, kPrimary);

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final all = provider.recentLearnings;
    final filtered = _filterTag == 'Tous' ? all : all.where((l) => l.tag == _filterTag).toList();

    return Scaffold(
      backgroundColor: kScaffold,
      appBar: AppBar(
        title: const Text("J'ai appris"),
        backgroundColor: kDark,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: kHeaderGradient)),
        bottom: const BrandAccentLine(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Input card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.lightbulb_outline, color: kWarning, size: 20),
                    const SizedBox(width: 8),
                    Text("Aujourd'hui, ${_dateFormat.format(DateTime.now())}",
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Qu'as-tu appris aujourd'hui ?\n\nÉcris librement — une idée, une leçon...",
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.black38),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Catégorie', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: tags.map((tag) {
                      final (bg, fg) = getTagColors(tag);
                      final isSelected = _selectedTag == tag;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTag = tag),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? fg : bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tag,
                              style: GoogleFonts.poppins(
                                  color: isSelected ? Colors.white : fg,
                                  fontSize: 12, fontWeight: FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final content = _contentCtrl.text.trim();
                        if (content.isNotEmpty) {
                          provider.addLearning(content, _selectedTag);
                          _contentCtrl.clear();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Apprentissage enregistré !', style: GoogleFonts.poppins()),
                            backgroundColor: kSuccess,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ));
                        }
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          _StatsRow(learnings: all),
          const SizedBox(height: 16),

          // Filter + historique
          Row(
            children: [
              Text('Historique', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              DropdownButton<String>(
                value: _filterTag,
                underline: const SizedBox(),
                style: GoogleFonts.poppins(color: kPrimary, fontSize: 13),
                items: ['Tous', ...tags].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _filterTag = v!),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Aucun apprentissage pour cette catégorie',
                    style: GoogleFonts.poppins(color: Colors.black45)),
              ),
            )
          else
            ...filtered.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LearningCard(
                    entry: entry,
                    tagColors: tagColors,
                    dateFormat: _dateFormat,
                    onDelete: () async {
                      final ok = await confirmDelete(context, 'Supprimer cet apprentissage ?');
                      if (ok) provider.deleteLearning(entry.id);
                    },
                    onEdit: () => _showEditDialog(context, provider, entry),
                  ),
                )),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, AppProvider provider, LearningEntry entry) {
    final ctrl = TextEditingController(text: entry.content);
    String selectedTag = entry.tag;

    showFormSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modifier l\'apprentissage',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  maxLines: 5,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: tags.map((tag) {
                    final (bg, fg) = getTagColors(tag);
                    final isSel = selectedTag == tag;
                    return GestureDetector(
                      onTap: () => setS(() => selectedTag = tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? fg : bg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tag,
                            style: GoogleFonts.poppins(
                                color: isSel ? Colors.white : fg,
                                fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final content = ctrl.text.trim();
                          if (content.isNotEmpty) {
                            provider.updateLearning(entry.id, content, selectedTag);
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Enregistrer'),
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

class _StatsRow extends StatelessWidget {
  final List<LearningEntry> learnings;
  const _StatsRow({required this.learnings});

  int _computeStreak() {
    if (learnings.isEmpty) return 0;
    final dates = learnings
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet().toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    final now = DateTime.now();
    var check = DateTime(now.year, now.month, now.day);
    for (final d in dates) {
      if (d == check) { streak++; check = check.subtract(const Duration(days: 1)); }
      else break;
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = learnings.where((l) => l.date.month == now.month && l.date.year == now.year).length;

    return Row(
      children: [
        _Card('Total', '${learnings.length}', Icons.menu_book, kPrimary, kPrimaryLight),
        const SizedBox(width: 10),
        _Card('Ce mois', '$thisMonth', Icons.calendar_month, kSuccess, const Color(0xFFE1F5EE)),
        const SizedBox(width: 10),
        _Card('Série', '${_computeStreak()}j', Icons.local_fire_department, kWarning, const Color(0xFFFAEEDA)),
      ],
    );
  }

  Widget _Card(String label, String value, IconData icon, Color fg, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: fg)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _LearningCard extends StatelessWidget {
  final LearningEntry entry;
  final Map<String, (Color, Color)> tagColors;
  final DateFormat dateFormat;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _LearningCard({
    required this.entry,
    required this.tagColors,
    required this.dateFormat,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = tagColors[entry.tag] ?? (kPrimaryLight, kPrimary);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(entry.tag, style: GoogleFonts.poppins(fontSize: 11, color: fg, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                Text(dateFormat.format(entry.date),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38)),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
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
              ],
            ),
            const SizedBox(height: 10),
            Text(entry.content, style: GoogleFonts.poppins(fontSize: 13, height: 1.6)),
          ],
        ),
      ),
    );
  }
}
