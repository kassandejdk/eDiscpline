// lib/screens/budget_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'yearly_report_screen.dart';

final _fmt = NumberFormat('#,###', 'fr_FR');
final _dateFmt = DateFormat('dd/MM HH:mm');

/// Formate un montant en respectant le toggle "cacher les montants".
String fmtAmount(BuildContext context, num value,
    {bool suffix = true, bool signed = false}) {
  final hide = context.watch<AppProvider>().hideAmounts;
  if (hide) return suffix ? '•••••' : '•••••';
  final sign = signed && value > 0 ? '+' : '';
  return '$sign${_fmt.format(value)}${suffix ? ' FCFA' : ''}';
}

// ─── Confirmation helper ───────────────────────────────────────────────────
Future<bool> confirmDelete(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: kDanger, size: 22),
            const SizedBox(width: 8),
            Text('Confirmer',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
          ]),
          content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
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
  final months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];
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
        title: Text('Mon prénom',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) {
                _saveName(name);
                Navigator.pop(context);
              }
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
//           SliverAppBar(
//             expandedHeight: 210,
//             pinned: true,
//             backgroundColor: kDark,
//             flexibleSpace: FlexibleSpaceBar(
//               background: Container(
//                 decoration: const BoxDecoration(gradient: kHeaderGradient),
//                 padding: const EdgeInsets.fromLTRB(20, 56, 20, 18),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Row(
//                     //   children: [
//                     //     Flexible(
//                     //       child: Column(
//                     //         crossAxisAlignment: CrossAxisAlignment.start,
//                     //         children: [
//                     //           Text(
//                     //             '${_greeting()}, ${_userName.isEmpty ? "toi" : _userName} 👋',
//                     //             style: GoogleFonts.poppins(
//                     //                 color: Colors.white,
//                     //                 fontSize: 15,
//                     //                 fontWeight: FontWeight.w600),
//                     //             overflow: TextOverflow.ellipsis,
//                     //             maxLines: 1,
//                     //           ),
//                     //           Text(
//                     //             '${months[provider.selectedMonth - 1]} ${provider.selectedYear}',
//                     //             style: GoogleFonts.poppins(
//                     //                 color: Colors.white60, fontSize: 12),
//                     //           ),
//                     //         ],
//                     //       ),
//                     //     ),
//                     //     const SizedBox(width: 8),
//                     //     _MonthPicker(
//                     //       month: provider.selectedMonth,
//                     //       year: provider.selectedYear,
//                     //       months: months,
//                     //       onChanged: (m, y) => provider.setSelectedPeriod(m, y),
//                     //     ),
//                     //     const SizedBox(width: 6),
//                     //     _IconAction(
//                     //       icon: provider.hideAmounts
//                     //           ? Icons.visibility_off_outlined
//                     //           : Icons.visibility_outlined,
//                     //       onTap: () => provider.toggleHideAmounts(),
//                     //     ),
//                     //     const SizedBox(width: 6),
//                     //     _IconAction(
//                     //       icon: Icons.person_outline,
//                     //       onTap: () => _askName(first: false),
//                     //     ),
//                     //   ],
//                     // ),
//                     Row(
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     _MonthPicker(
//       month: provider.selectedMonth,
//       year: provider.selectedYear,
//       months: months,
//       onChanged: (m, y) => provider.setSelectedPeriod(m, y),
//     ),
//     const SizedBox(width: 6),
//     _IconAction(
//       icon: Icons.bar_chart,
//       onTap: () => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const YearlyReportScreen()),
//       ),
//     ),
//     const SizedBox(width: 6),
//     _IconAction(
//       icon: provider.hideAmounts
//           ? Icons.visibility_off_outlined
//           : Icons.visibility_outlined,
//       onTap: () => provider.toggleHideAmounts(),
//     ),
//     const SizedBox(width: 6),
//     _IconAction(
//       icon: Icons.person_outline,
//       onTap: () => _askName(first: false),
//     ),
//   ],
// ),
//                     const SizedBox(height: 14),
//                     if (budget != null) ...[
//                       Text('Budget du mois',
//                           style: GoogleFonts.poppins(
//                               color: Colors.white60,
//                               fontSize: 11,
//                               letterSpacing: 0.5)),
//                       const SizedBox(height: 2),
//                       Row(
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           Flexible(
//                             child: FittedBox(
//                               fit: BoxFit.scaleDown,
//                               alignment: Alignment.centerLeft,
//                               child: Text(
//                                 fmtAmount(context, budget.totalBudget),
//                                 style: GoogleFonts.poppins(
//                                     color: Colors.white,
//                                     fontSize: 30,
//                                     fontWeight: FontWeight.w700,
//                                     letterSpacing: -0.5),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           _EditChip(
//                             onTap: () => _editBudgetAmount(
//                                 context, provider, budget.totalBudget),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       _GlobalProgressBar(budget: budget),
//                     ] else
//                       Text('Aucun budget défini',
//                           style: GoogleFonts.poppins(
//                               color: Colors.white70, fontSize: 16)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
          SliverAppBar(
  expandedHeight: 210,
  pinned: true,
  backgroundColor: kDark,
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: const BoxDecoration(gradient: kHeaderGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ─── Prénom + greeting (inchangé) ───────────────
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, ${_userName.isEmpty ? "toi" : _userName} 👋',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '${months[provider.selectedMonth - 1]} ${provider.selectedYear}',
                      style: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // ─── Actions (avec le nouveau bouton rapport) ───
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MonthPicker(
                    month: provider.selectedMonth,
                    year: provider.selectedYear,
                    months: months,
                    onChanged: (m, y) =>
                        provider.setSelectedPeriod(m, y),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: Icons.bar_chart,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const YearlyReportScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: provider.hideAmounts
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onTap: () => provider.toggleHideAmounts(),
                  ),
                  const SizedBox(width: 6),
                  _IconAction(
                    icon: Icons.person_outline,
                    onTap: () => _askName(first: false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (budget != null) ...[
            Text('Budget du mois',
                style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      fmtAmount(context, budget.totalBudget),
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _EditChip(
                  onTap: () => _editBudgetAmount(
                      context, provider, budget.totalBudget),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GlobalProgressBar(budget: budget),
          ] else
            Text('Aucun budget défini',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 16)),
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kPrimaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.savings_outlined,
                            size: 52, color: kPrimary),
                      ),
                      const SizedBox(height: 20),
                      Text('Commencer ce mois',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                          'Définis ton budget mensuel pour tracker tes dépenses.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.black54, fontSize: 13)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _showCreateBudgetDialog(context, provider),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Créer mon budget'),
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
                        Text('Catégories',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${budget.categories.length}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: kPrimary,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () =>
                              _showCategoryDialog(context, provider),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (budget.categories.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text('Aucune catégorie',
                          style: GoogleFonts.poppins(
                              fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Text('Ajoute une catégorie pour commencer.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.black38)),
                    ],
                  ),
                ),
              )
            else
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
                          onAddExpense: () =>
                              _showAddExpenseDialog(context, provider, cat),
                          onEdit: () => _showCategoryDialog(context, provider,
                              cat: cat),
                          onDelete: () async {
                            final ok = await confirmDelete(context,
                                'Supprimer la catégorie "${cat.name}" et toutes ses dépenses ?');
                            if (ok) provider.deleteCategory(cat.id);
                          },
                          onDeleteExpense: (expId) async {
                            final ok = await confirmDelete(
                                context, 'Supprimer cette dépense ?');
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
              onPressed: () => _showCategoryDialog(
                  context, context.read<AppProvider>()),
              backgroundColor: kPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _editBudgetAmount(
      BuildContext context, AppProvider provider, double current) {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Modifier le budget',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'Nouveau montant (FCFA)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            onPressed: () {
              final val = double.tryParse(
                  ctrl.text.replaceAll(' ', '').replaceAll(',', ''));
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
    bool copyCategories = true;
    final hasPrevious = provider.budgets.isNotEmpty;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Nouveau budget',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Montant total (FCFA)',
                  hintText: 'ex: 250000',
                ),
              ),
              if (hasPrevious) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setS(() => copyCategories = !copyCategories),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: copyCategories,
                            onChanged: (v) =>
                                setS(() => copyCategories = v ?? true),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Reprendre les catégories du mois précédent',
                            style: GoogleFonts.poppins(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(
                    ctrl.text.replaceAll(' ', '').replaceAll(',', ''));
                if (val != null && val > 0) {
                  provider.createBudget(val,
                      copyCategories: hasPrevious && copyCategories);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  final _icons = [
    '💰', '⛽', '🏠', '👨‍👩‍👧', '👨‍👩‍👦', '👕', '🍽️', '📱', '🚌', '💊',
    '📚', '🎮', '✈️', '🏋️', '💡', '🛒', '🎁', '🏦', '💼', '🎓'
  ];

  void _showCategoryDialog(BuildContext context, AppProvider provider,
      {BudgetCategory? cat}) {
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    final budgetCtrl = TextEditingController(
        text: cat != null ? cat.budgeted.toStringAsFixed(0) : '');
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
                style: GoogleFonts.poppins(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Text('Icône',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setS(() => selectedIcon = _icons[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selectedIcon == _icons[i]
                          ? kPrimaryLight
                          : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: selectedIcon == _icons[i]
                              ? kPrimary
                              : Colors.transparent),
                    ),
                    child: Center(
                        child: Text(_icons[i],
                            style: const TextStyle(fontSize: 22))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: 'Nom de la catégorie'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Montant prévu (FCFA)'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Annuler')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final val = double.tryParse(budgetCtrl.text
                          .replaceAll(' ', '')
                          .replaceAll(',', ''));
                      if (name.isNotEmpty && val != null && val >= 0) {
                        if (isEdit) {
                          provider.updateCategory(
                              cat!.id, name, selectedIcon, val);
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

  void _showAddExpenseDialog(
      BuildContext context, AppProvider provider, BudgetCategory cat) {
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
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text(
              'Reste disponible : ${fmtAmount(context, cat.difference)}',
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
              Expanded(
                child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final val = double.tryParse(amountCtrl.text
                        .replaceAll(' ', '')
                        .replaceAll(',', ''));
                    if (val != null && val > 0) {
                      provider.addExpense(
                          cat.id, val, noteCtrl.text.trim());
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

// ─── Icon action button ────────────────────────────────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ─── Edit chip ─────────────────────────────────────────────────────────────

class _EditChip extends StatelessWidget {
  final VoidCallback onTap;
  const _EditChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.edit, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text('Modifier',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─── Global progress bar ───────────────────────────────────────────────────

class _GlobalProgressBar extends StatelessWidget {
  final MonthlyBudget budget;
  const _GlobalProgressBar({required this.budget});

  @override
  Widget build(BuildContext context) {
    final hide = context.watch<AppProvider>().hideAmounts;
    final pct = budget.totalBudget == 0
        ? 0.0
        : (budget.totalSpent / budget.totalBudget).clamp(0.0, 1.0);
    final color = budget.isPositive ? kSuccess : kDanger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('${(pct * 100).toStringAsFixed(0)}% utilisé',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 11)),
            const Spacer(),
            Text(
              hide
                  ? '••••• restants'
                  : '${_fmt.format(budget.balance)} FCFA restants',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Summary cards ─────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final MonthlyBudget budget;
  const _SummaryCards({required this.budget});

  @override
  Widget build(BuildContext context) {
    final hide = context.watch<AppProvider>().hideAmounts;
    String f(num v) => hide ? '•••••' : _fmt.format(v);

    return Row(
      children: [
        _Card('Budget', f(budget.totalBudget), kPrimary, kPrimaryLight,
            Icons.account_balance_wallet_outlined),
        const SizedBox(width: 10),
        _Card('Dépensé', f(budget.totalSpent), kDanger, kDangerLight,
            Icons.trending_down),
        const SizedBox(width: 10),
        _Card(
          budget.isPositive ? 'Bénéfice' : 'Déficit',
          '${budget.isPositive && !hide ? '+' : ''}${f(budget.balance)}',
          budget.isPositive ? kSuccess : kDanger,
          budget.isPositive ? kSuccessLight : kDangerLight,
          budget.isPositive ? Icons.trending_up : Icons.trending_down,
        ),
      ],
    );
  }

  Widget _Card(
      String label, String value, Color fg, Color bg, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: fg.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: fg, size: 14),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.poppins(
                    color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value,
                  style: GoogleFonts.poppins(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
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
    final hide = context.watch<AppProvider>().hideAmounts;

    String f(num v) => hide ? '•••••' : _fmt.format(v);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                      child: Text(cat.icon,
                          style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name,
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Prévu : ${f(cat.budgeted)} FCFA',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.black45)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${f(cat.actual)} FCFA',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    Text(
                        cat.isOverBudget
                            ? 'Dépassé !'
                            : 'Reste ${f(cat.difference)}',
                        style:
                            GoogleFonts.poppins(fontSize: 10, color: color)),
                  ],
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: Colors.black38),
                  onSelected: (v) {
                    if (v == 'add') widget.onAddExpense();
                    if (v == 'edit') widget.onEdit();
                    if (v == 'delete') widget.onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'add',
                        child: Text('+ Ajouter une dépense')),
                    PopupMenuItem(
                        value: 'edit', child: Text('Modifier la catégorie')),
                    PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('Supprimer', style: TextStyle(color: kDanger))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  backgroundColor: const Color(0xFFEEEEEE),
                  color: color,
                  minHeight: 7,
                ),
              ),
            ),
            const SizedBox(height: 8),
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
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add, size: 16, color: kPrimary),
                            const SizedBox(width: 4),
                            Text('Ajouter dépense',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: kPrimary,
                                    fontWeight: FontWeight.w500)),
                          ]),
                    ),
                  ),
                ),
                if (cat.expenses.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        Text(
                            '${cat.expenses.length} dépense${cat.expenses.length > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.black54)),
                        Icon(
                            _expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: Colors.black38),
                      ]),
                    ),
                  ),
                ],
              ],
            ),
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
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(_dateFmt.format(exp.date),
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.black38)),
                            ],
                          ),
                        ),
                        Text('${f(exp.amount)} F',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kDanger)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => widget.onDeleteExpense(exp.id),
                          child: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.black26),
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

  const _MonthPicker({
    required this.month,
    required this.year,
    required this.months,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(children: [
           Icon(Icons.calendar_month, color: Colors.white, size: 14),
         
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Sélectionner le mois',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () => setS(() => y--),
                        icon: const Icon(Icons.chevron_left)),
                    Text('$y',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                        onPressed: () => setS(() => y++),
                        icon: const Icon(Icons.chevron_right)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 260,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 12,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => setS(() => m = i + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: m == i + 1 ? kPrimary : kPrimaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(months[i].substring(0, 3),
                            style: GoogleFonts.poppins(
                                color:
                                    m == i + 1 ? Colors.white : kPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              onChanged(m, y);
              Navigator.pop(ctx);
            },
            child: const Text('Confirmer'),
          ),
          ],
        ),
      ),
    );
  }
}