import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

final _fmt = NumberFormat('#,###', 'fr_FR');
final _dateFmt = DateFormat('dd/MM HH:mm');

// ─── Confirmation helper ───────────────────────────────────────────────────
Future<bool> confirmDelete(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: kDanger, size: 22),
            const SizedBox(width: 8),
            Text('Confirmer', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          ]),
          content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer', style: TextStyle(color: kDanger)),
            ),
          ],
        ),
      ) ??
      false;
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final months = ['Janvier','Février','Mars','Avril','Mai','Juin','Juillet','Août','Septembre','Octobre','Novembre','Décembre'];
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userName = prefs.getString('user_name') ?? '');
  }

  Future<void> _saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    setState(() => _userName = name);
  }
  void _askName({bool first = false}) {
    final ctrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mon prénom', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(controller: ctrl, autofocus: true,
            decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) { _saveName(name); Navigator.pop(context); }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final budget = provider.currentBudget;

    return Scaffold(
      backgroundColor: kScaffold,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            backgroundColor: kDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: kHeaderGradient),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting()}, $_userName 👋',
                                style: GoogleFonts.poppins(
                                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '${months[provider.selectedMonth - 1]} ${provider.selectedYear}',
                                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _MonthPicker(
                              month: provider.selectedMonth,
                              year: provider.selectedYear,
                              months: months,
                              onChanged: (m, y) => provider.setSelectedPeriod(m, y),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _askName(first: false),
                              child: const Icon(Icons.person_outline, color: Colors.white54, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (budget != null) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${_fmt.format(budget.totalBudget)} FCFA',
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _editBudgetAmount(context, provider, budget.totalBudget),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                const Icon(Icons.edit, color: Colors.white54, size: 12),
                                const SizedBox(width: 4),
                                Text('Modifier', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                              ]),
                            ),
                          ),
                        ],
                      ),
                      Text('Budget mensuel alloué',
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    ] else
                      Text('Aucun budget défini',
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          if (budget == null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.savings_outlined, size: 64, color: kPrimary),
                      const SizedBox(height: 16),
                      Text('Commencer ce mois',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Définis ton budget mensuel pour tracker tes dépenses.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _showCreateBudgetDialog(context, provider),
                        child: const Text('Créer mon budget'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SummaryCards(budget: budget),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('Catégories', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showCategoryDialog(context, provider),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final cat = budget.categories[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CategoryCard(
                        category: cat,
                        onAddExpense: () => _showAddExpenseDialog(context, provider, cat),
                        onEdit: () => _showCategoryDialog(context, provider, cat: cat),
                        onDelete: () async {
                          final ok = await confirmDelete(context, 'Supprimer la catégorie "${cat.name}" et toutes ses dépenses ?');
                          if (ok) provider.deleteCategory(cat.id);
                        },
                        onDeleteExpense: (expId) async {
                          final ok = await confirmDelete(context, 'Supprimer cette dépense ?');
                          if (ok) provider.deleteExpense(cat.id, expId);
                        },
                      ),
                    );
                  },
                  childCount: budget.categories.length,
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: budget != null
          ? FloatingActionButton(
              onPressed: () => _showCategoryDialog(context, context.read<AppProvider>()),
              backgroundColor: kPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _editBudgetAmount(BuildContext context, AppProvider provider, double current) {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Modifier le budget', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nouveau montant (FCFA)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(' ', '').replaceAll(',', ''));
              if (val != null && val > 0) {
                provider.updateTotalBudget(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showCreateBudgetDialog(BuildContext context, AppProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Nouveau budget', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Montant total (FCFA)', hintText: 'ex: 250000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.replaceAll(' ', '').replaceAll(',', ''));
              if (val != null && val > 0) {
                provider.createBudget(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  final _icons = ['💰','⛽','🏠','👨‍👩‍👧','👨‍👩‍👦','👕','🍽️','📱','🚌','💊','📚','🎮','✈️','🏋️','💡','🛒','🎁','🏦','💼','🎓'];

  void _showCategoryDialog(BuildContext context, AppProvider provider, {BudgetCategory? cat}) {
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    final budgetCtrl = TextEditingController(text: cat != null ? cat.budgeted.toStringAsFixed(0) : '');
    String selectedIcon = cat?.icon ?? '💰';
    final isEdit = cat != null;

    showFormSheet(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Modifier la catégorie' : 'Nouvelle catégorie',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text('Icône', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _icons.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setS(() => selectedIcon = _icons[i]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: selectedIcon == _icons[i] ? kPrimaryLight : const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedIcon == _icons[i] ? kPrimary : Colors.transparent),
                        ),
                        child: Center(child: Text(_icons[i], style: const TextStyle(fontSize: 22))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(controller: nameCtrl, textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Nom de la catégorie')),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Montant prévu (FCFA)'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          final val = double.tryParse(budgetCtrl.text.replaceAll(' ', '').replaceAll(',', ''));
                          if (name.isNotEmpty && val != null && val >= 0) {
                            if (isEdit) {
                              provider.updateCategory(cat!.id, name, selectedIcon, val);
                            } else {
                              provider.addCategory(name, selectedIcon, val);
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

  void _showAddExpenseDialog(BuildContext context, AppProvider provider, BudgetCategory cat) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showFormSheet(
      context,
      builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(cat.icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text('Ajouter une dépense',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 6),
              Text('Reste disponible : ${_fmt.format(cat.difference)} FCFA',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: cat.isOverBudget ? kDanger : kSuccess,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Montant (FCFA)',
                  hintText: 'ex: 15000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                  hintText: 'ex: Plein d\'essence station Total',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final val = double.tryParse(amountCtrl.text.replaceAll(' ', '').replaceAll(',', ''));
                        if (val != null && val > 0) {
                          provider.addExpense(cat.id, val, noteCtrl.text.trim());
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

// ─── Summary cards ─────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final MonthlyBudget budget;
  const _SummaryCards({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Card('Budget', _fmt.format(budget.totalBudget), kPrimary, kPrimaryLight, Icons.account_balance_wallet),
        const SizedBox(width: 10),
        _Card('Dépensé', _fmt.format(budget.totalSpent), kDanger, kDangerLight, Icons.arrow_upward),
        const SizedBox(width: 10),
        _Card(
          budget.isPositive ? 'Bénéfice' : 'Déficit',
          '${budget.isPositive ? '+' : ''}${_fmt.format(budget.balance)}',
          budget.isPositive ? kSuccess : kDanger,
          budget.isPositive ? kSuccessLight : kDangerLight,
          budget.isPositive ? Icons.trending_up : Icons.trending_down,
        ),
      ],
    );
  }

  Widget _Card(String label, String value, Color fg, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.poppins(color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Category card ─────────────────────────────────────────────────────────

class _CategoryCard extends StatefulWidget {
  final BudgetCategory category;
  final VoidCallback onAddExpense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onDeleteExpense;

  const _CategoryCard({
    required this.category,
    required this.onAddExpense,
    required this.onEdit,
    required this.onDelete,
    required this.onDeleteExpense,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final pct = cat.percentage;
    final color = cat.isOverBudget ? kDanger : kSuccess;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(cat.icon, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Prévu : ${_fmt.format(cat.budgeted)} FCFA',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_fmt.format(cat.actual)} FCFA',
                        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
                    Text(cat.isOverBudget ? 'Dépassé !' : 'Reste ${_fmt.format(cat.difference)}',
                        style: GoogleFonts.poppins(fontSize: 10, color: color)),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.black38),
                  onSelected: (v) {
                    if (v == 'add') widget.onAddExpense();
                    if (v == 'edit') widget.onEdit();
                    if (v == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'add', child: Text('+ Ajouter une dépense')),
                    PopupMenuItem(value: 'edit', child: Text('Modifier la catégorie')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer', style: TextStyle(color: kDanger))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFEEEEEE),
                color: color,
                minHeight: 7,
              ),
            ),
            const SizedBox(height: 8),
            // Bouton ajouter dépense + toggle historique
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onAddExpense,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: kPrimaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.add, size: 16, color: kPrimary),
                        const SizedBox(width: 4),
                        Text('Ajouter dépense',
                            style: GoogleFonts.poppins(fontSize: 12, color: kPrimary, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ),
                ),
                if (cat.expenses.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Text('${cat.expenses.length} dépense${cat.expenses.length > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: Colors.black38),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
            // Historique des dépenses
            if (_expanded && cat.expenses.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              ...cat.expenses.reversed.map((exp) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exp.note.isEmpty ? 'Sans note' : exp.note,
                                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Text(_dateFmt.format(exp.date),
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.black38)),
                            ],
                          ),
                        ),
                        Text('${_fmt.format(exp.amount)} F',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: kDanger)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => widget.onDeleteExpense(exp.id),
                          child: const Icon(Icons.delete_outline, size: 18, color: Colors.black26),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Month picker ───────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final int month, year;
  final List<String> months;
  final Function(int, int) onChanged;

  const _MonthPicker({required this.month, required this.year, required this.months, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.calendar_month, color: Colors.white60, size: 14),
          const SizedBox(width: 4),
          Text('Changer', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
        ]),
      ),
    );
  }

  void _pick(BuildContext context) {
    int m = month, y = year;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Sélectionner le mois', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => setS(() => y--), icon: const Icon(Icons.chevron_left)),
                  Text('$y', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  IconButton(onPressed: () => setS(() => y++), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 2.2, mainAxisSpacing: 8, crossAxisSpacing: 8),
                itemCount: 12,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setS(() => m = i + 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: m == i + 1 ? kPrimary : kPrimaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(months[i].substring(0, 3),
                        style: GoogleFonts.poppins(
                          color: m == i + 1 ? Colors.white : kPrimary,
                          fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () { onChanged(m, y); Navigator.pop(ctx); },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }
}
