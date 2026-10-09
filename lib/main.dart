import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

const appName = 'CACHIA MICHEL';
const developerName = 'CACHIA MICHEL';
const supportEmail = 'support@cachiamichel.com';
const screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

const _brandNavy = Color(0xFF8BC34A);
const _brandBlue = Color(0xFF5C82BC);
const _safetyGold = Color(0xFF558B2F);
const _yardGreen = Color(0xFF1565C0);
const _canvas = Color(0xFFF6F7FB);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = screenshotMode
      ? MemoryOperationsStorage()
      : FileOperationsStorage.defaultLocation();
  final store = OperationsStore(
    storage: storage,
    screenshotMode: screenshotMode,
  );
  await store.load();
  runApp(OperationsApp(store: store));
}

class OperationsApp extends StatelessWidget {
  const OperationsApp({super.key, required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _brandNavy,
          brightness: Brightness.light,
        ).copyWith(
          primary: _brandNavy,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFDCE6F7),
          onPrimaryContainer: const Color(0xFF14243F),
          secondary: _safetyGold,
          onSecondary: const Color(0xFF241A05),
          secondaryContainer: const Color(0xFFFFE8B3),
          onSecondaryContainer: const Color(0xFF2E2208),
          tertiary: _yardGreen,
          onTertiary: Colors.white,
          tertiaryContainer: const Color(0xFFD8F2ED),
          surface: _canvas,
          surfaceContainerHighest: Colors.white,
        );

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _canvas,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: _canvas,
          foregroundColor: _brandNavy,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE1E6EF)),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDCE6F7),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
      ),
      home: OperationsShell(store: store),
    );
  }
}

enum Workstream {
  shipments(
    'Shipments',
    'shipment',
    Icons.local_shipping_outlined,
    Icons.local_shipping,
  ),
  containers(
    'Yard',
    'container',
    Icons.inventory_2_outlined,
    Icons.inventory_2,
  ),
  tasks('Tasks', 'task', Icons.task_alt_outlined, Icons.task_alt),
  patrols('Patrol', 'patrol', Icons.security_outlined, Icons.security);

  const Workstream(this.label, this.recordName, this.icon, this.selectedIcon);

  final String label;
  final String recordName;
  final IconData icon;
  final IconData selectedIcon;

  String get storageKey => name;
}

class OperationItem {
  const OperationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.owner,
    required this.status,
    required this.dueLabel,
    required this.priority,
    required this.progress,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final Workstream type;
  final String title;
  final String detail;
  final String owner;
  final String status;
  final String dueLabel;
  final String priority;
  final int progress;
  final String notes;
  final DateTime createdAt;

  OperationItem copyWith({
    String? title,
    String? detail,
    String? owner,
    String? status,
    String? dueLabel,
    String? priority,
    int? progress,
    String? notes,
  }) {
    return OperationItem(
      id: id,
      type: type,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      owner: owner ?? this.owner,
      status: status ?? this.status,
      dueLabel: dueLabel ?? this.dueLabel,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.storageKey,
    'title': title,
    'detail': detail,
    'owner': owner,
    'status': status,
    'dueLabel': dueLabel,
    'priority': priority,
    'progress': progress,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OperationItem.fromJson(Map<String, Object?> json) {
    final typeName = json['type'] as String? ?? Workstream.tasks.storageKey;
    final type = Workstream.values.firstWhere(
      (stream) => stream.storageKey == typeName,
      orElse: () => Workstream.tasks,
    );
    return OperationItem(
      id:
          json['id'] as String? ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      title: json['title'] as String? ?? 'Untitled record',
      detail: json['detail'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      status: json['status'] as String? ?? statusOptions(type).first,
      dueLabel: json['dueLabel'] as String? ?? 'Today',
      priority: json['priority'] as String? ?? 'Standard',
      progress: json['progress'] as int? ?? 0,
      notes: json['notes'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

abstract class OperationsStorage {
  Future<String?> readPayload();

  Future<void> writePayload(String payload);
}

class FileOperationsStorage implements OperationsStorage {
  FileOperationsStorage(this._file);

  factory FileOperationsStorage.defaultLocation() {
    final path = Platform.isAndroid
        ? '/data/user/0/com.taziggg100.cachiamichel/files/operations.json'
        : '${Directory.systemTemp.path}/cachia_michel_operations.json';
    return FileOperationsStorage(File(path));
  }

  final File _file;

  @override
  Future<String?> readPayload() async {
    if (!await _file.exists()) {
      return null;
    }
    return _file.readAsString();
  }

  @override
  Future<void> writePayload(String payload) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(payload);
  }
}

class MemoryOperationsStorage implements OperationsStorage {
  String? _payload;

  @override
  Future<String?> readPayload() async => _payload;

  @override
  Future<void> writePayload(String payload) async {
    _payload = payload;
  }
}

class OperationsStore extends ChangeNotifier {
  OperationsStore({
    required OperationsStorage storage,
    this.screenshotMode = false,
    List<OperationItem>? initialItems,
  }) : _storage = storage,
       _items = List<OperationItem>.from(initialItems ?? []);

  factory OperationsStore.memory({List<OperationItem>? initialItems}) {
    return OperationsStore(
      storage: MemoryOperationsStorage(),
      initialItems: initialItems,
    );
  }

  final OperationsStorage _storage;
  final bool screenshotMode;
  List<OperationItem> _items;

  String siteName = 'North quay operations';
  String shiftLead = 'Shift supervisor';
  String handoverWindow = '18:00 handover';

  List<OperationItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (screenshotMode) {
      _items = _sampleItems();
      siteName = 'Port gate and yard';
      shiftLead = 'M. Cachia';
      handoverWindow = '18:00 shift handover';
      notifyListeners();
      return;
    }

    final payload = await _storage.readPayload();
    if (payload == null || payload.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(payload) as Map<String, Object?>;
      final rawItems = decoded['items'] as List<Object?>? ?? [];
      _items = rawItems
          .whereType<Map<String, Object?>>()
          .map(OperationItem.fromJson)
          .toList();
      final settings = decoded['settings'] as Map<String, Object?>? ?? {};
      siteName = settings['siteName'] as String? ?? siteName;
      shiftLead = settings['shiftLead'] as String? ?? shiftLead;
      handoverWindow = settings['handoverWindow'] as String? ?? handoverWindow;
    } on FormatException {
      _items = [];
    }
    notifyListeners();
  }

  List<OperationItem> itemsFor(Workstream type) {
    return _items.where((item) => item.type == type).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  OperationItem? itemById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  int countFor(Workstream type) =>
      _items.where((item) => item.type == type).length;

  int get activeCount => _items
      .where(
        (item) => item.progress < 100 && item.status.toLowerCase() != 'done',
      )
      .length;

  int get criticalCount => _items
      .where(
        (item) => item.priority == 'Critical' || item.status.contains('hold'),
      )
      .length;

  Future<void> addItem(OperationItem item) async {
    _items = [item, ..._items];
    notifyListeners();
    await _persist();
  }

  Future<void> updateItem(OperationItem item) async {
    _items = _items
        .map((existing) => existing.id == item.id ? item : existing)
        .toList();
    notifyListeners();
    await _persist();
  }

  Future<void> advanceItem(String id) async {
    final item = itemById(id);
    if (item == null) {
      return;
    }
    final nextProgress = (item.progress + 25).clamp(0, 100);
    final statuses = statusOptions(item.type);
    final statusIndex = nextProgress >= 100
        ? statuses.length - 1
        : (nextProgress / 35).floor().clamp(0, statuses.length - 1);
    await updateItem(
      item.copyWith(progress: nextProgress, status: statuses[statusIndex]),
    );
  }

  Future<void> completeItem(String id) async {
    final item = itemById(id);
    if (item == null) {
      return;
    }
    final statuses = statusOptions(item.type);
    await updateItem(item.copyWith(progress: 100, status: statuses.last));
  }

  Future<void> clearAll() async {
    _items = [];
    notifyListeners();
    await _persist();
  }

  Future<void> saveSettings({
    required String siteName,
    required String shiftLead,
    required String handoverWindow,
  }) async {
    this.siteName = siteName.trim().isEmpty ? this.siteName : siteName.trim();
    this.shiftLead = shiftLead.trim().isEmpty
        ? this.shiftLead
        : shiftLead.trim();
    this.handoverWindow = handoverWindow.trim().isEmpty
        ? this.handoverWindow
        : handoverWindow.trim();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    if (screenshotMode) {
      return;
    }
    final payload = jsonEncode({
      'items': _items.map((item) => item.toJson()).toList(),
      'settings': {
        'siteName': siteName,
        'shiftLead': shiftLead,
        'handoverWindow': handoverWindow,
      },
    });
    await _storage.writePayload(payload);
  }
}

class OperationsShell extends StatefulWidget {
  const OperationsShell({super.key, required this.store});

  final OperationsStore store;

  @override
  State<OperationsShell> createState() => _OperationsShellState();
}

class _OperationsShellState extends State<OperationsShell> {
  int _index = 0;

  Workstream? get _selectedWorkstream {
    if (_index == 0) {
      return null;
    }
    return Workstream.values[_index - 1];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final selected = _selectedWorkstream;
        final pages = [
          DashboardScreen(
            store: widget.store,
            onCreate: _openCreateSheet,
            onOpenItem: _openDetail,
          ),
          ...Workstream.values.map(
            (stream) => WorkstreamScreen(
              stream: stream,
              store: widget.store,
              onOpenItem: _openDetail,
            ),
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text(appName),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsScreen(store: widget.store),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(child: pages[_index]),
          floatingActionButton: selected == null
              ? null
              : FloatingActionButton.extended(
                  key: ValueKey('add-${selected.storageKey}'),
                  onPressed: () => _openCreateSheet(selected),
                  icon: const Icon(Icons.add),
                  label: Text('Add ${selected.recordName}'),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Today',
              ),
              ...Workstream.values.map(
                (stream) => NavigationDestination(
                  key: ValueKey('nav-${stream.storageKey}'),
                  icon: Icon(stream.icon),
                  selectedIcon: Icon(stream.selectedIcon),
                  label: stream.label,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateSheet(Workstream stream) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CreateItemSheet(store: widget.store, type: stream),
    );
  }

  void _openDetail(OperationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ItemDetailScreen(store: widget.store, itemId: item.id),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.store,
    required this.onCreate,
    required this.onOpenItem,
  });

  final OperationsStore store;
  final ValueChanged<Workstream> onCreate;
  final ValueChanged<OperationItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = store.items
        .where((item) => item.priority != 'Standard' || item.progress < 45)
        .take(4)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _DashboardHeader(store: store),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatCard(
              label: 'Active',
              value: '${store.activeCount}',
              icon: Icons.bolt,
            ),
            StatCard(
              label: 'Watch',
              value: '${store.criticalCount}',
              icon: Icons.warning_amber_rounded,
              color: _safetyGold,
            ),
            StatCard(
              label: 'Shipments',
              value: '${store.countFor(Workstream.shipments)}',
              icon: Icons.local_shipping,
            ),
            StatCard(
              label: 'Patrol logs',
              value: '${store.countFor(Workstream.patrols)}',
              icon: Icons.security,
              color: _yardGreen,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Quick capture', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: Workstream.values.map((stream) {
            return ActionChip(
              key: ValueKey('quick-${stream.storageKey}'),
              avatar: Icon(stream.icon, size: 18),
              label: Text(stream.label),
              onPressed: () => onCreate(stream),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'CACHIA MICHEL',
          trailing: '${urgent.length} open',
        ),
        const SizedBox(height: 10),
        if (urgent.isEmpty)
          const EmptyPanel(
            icon: Icons.fact_check_outlined,
            title: 'No active records yet',
            subtitle:
                'Add shipments, containers, tasks, or patrol logs as the shift starts.',
          )
        else
          ...urgent.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OperationTile(item: item, onTap: () => onOpenItem(item)),
            ),
          ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.store});

  final OperationsStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'docs/icon.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.siteName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${store.shiftLead} • ${store.handoverWindow}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.84),
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

class WorkstreamScreen extends StatelessWidget {
  const WorkstreamScreen({
    super.key,
    required this.stream,
    required this.store,
    required this.onOpenItem,
  });

  final Workstream stream;
  final OperationsStore store;
  final ValueChanged<OperationItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    final items = store.itemsFor(stream);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        SectionIntro(stream: stream, count: items.length),
        const SizedBox(height: 14),
        if (items.isEmpty)
          EmptyPanel(
            icon: stream.icon,
            title: 'No ${stream.recordName} records',
            subtitle:
                'Use the add button to capture the next ${stream.recordName}.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OperationTile(item: item, onTap: () => onOpenItem(item)),
            ),
          ),
      ],
    );
  }
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({super.key, required this.stream, required this.count});

  final Workstream stream;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Icon(stream.selectedIcon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.label,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 1
                        ? '1 record in local storage'
                        : '$count records in local storage',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class OperationTile extends StatelessWidget {
  const OperationTile({super.key, required this.item, required this.onTap});

  final OperationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priorityColor = switch (item.priority) {
      'Critical' => theme.colorScheme.error,
      'High' => _safetyGold,
      _ => _brandBlue,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.type.icon, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(item.detail, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  StatusPill(label: item.priority, color: priorityColor),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: item.progress / 100,
                  backgroundColor: const Color(0xFFE7ECF3),
                  color: item.progress >= 100
                      ? _yardGreen
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(label: item.status, color: colorScheme.primary),
                  StatusPill(label: item.dueLabel, color: _yardGreen),
                  StatusPill(label: item.owner, color: const Color(0xFF6D7480)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({
    super.key,
    required this.store,
    required this.itemId,
  });

  final OperationsStore store;
  final String itemId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final item = store.itemById(itemId);
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Record detail')),
            body: const Center(child: Text('Record not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${item.type.recordName.toTitleCase()} detail'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              OperationTile(item: item, onTap: () {}),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Status board',
                        trailing: '${item.progress}%',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.notes.isEmpty ? 'No notes recorded.' : item.notes,
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => store.advanceItem(item.id),
                            icon: const Icon(Icons.trending_up),
                            label: const Text('Advance status'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => store.completeItem(item.id),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Complete'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => CreateItemSheet(
                                  store: store,
                                  type: item.type,
                                  existing: item,
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CreateItemSheet extends StatefulWidget {
  const CreateItemSheet({
    super.key,
    required this.store,
    required this.type,
    this.existing,
  });

  final OperationsStore store;
  final Workstream type;
  final OperationItem? existing;

  @override
  State<CreateItemSheet> createState() => _CreateItemSheetState();
}

class _CreateItemSheetState extends State<CreateItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _detail;
  late final TextEditingController _owner;
  late final TextEditingController _due;
  late final TextEditingController _notes;
  late String _status;
  late String _priority;
  late double _progress;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _detail = TextEditingController(text: existing?.detail ?? '');
    _owner = TextEditingController(text: existing?.owner ?? '');
    _due = TextEditingController(text: existing?.dueLabel ?? 'Today');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _status = existing?.status ?? statusOptions(widget.type).first;
    _priority = existing?.priority ?? 'Standard';
    _progress = (existing?.progress ?? 15).toDouble();
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _owner.dispose();
    _due.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final labels = formLabels(widget.type);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null
                    ? 'Add ${widget.type.recordName}'
                    : 'Edit ${widget.type.recordName}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('primary-field'),
                controller: _title,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: labels.primary),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('detail-field'),
                controller: _detail,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: labels.detail),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('owner-field'),
                      controller: _owner,
                      decoration: InputDecoration(labelText: labels.owner),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('due-field'),
                      controller: _due,
                      decoration: const InputDecoration(
                        labelText: 'Due or time',
                      ),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: statusOptions(widget.type)
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const ['Standard', 'High', 'Critical']
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _priority = value ?? _priority),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 12),
              Text('Progress ${_progress.round()}%'),
              Slider(
                value: _progress,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_progress.round()}%',
                onChanged: (value) => setState(() => _progress = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('save-record'),
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final navigator = Navigator.of(context);
    final existing = widget.existing;
    final item = OperationItem(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      type: widget.type,
      title: _title.text.trim(),
      detail: _detail.text.trim(),
      owner: _owner.text.trim(),
      status: _status,
      dueLabel: _due.text.trim(),
      priority: _priority,
      progress: _progress.round(),
      notes: _notes.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    if (existing == null) {
      await widget.store.addItem(item);
    } else {
      await widget.store.updateItem(item);
    }
    if (mounted) {
      navigator.pop();
    }
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final OperationsStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _siteName;
  late final TextEditingController _shiftLead;
  late final TextEditingController _handoverWindow;

  @override
  void initState() {
    super.initState();
    _siteName = TextEditingController(text: widget.store.siteName);
    _shiftLead = TextEditingController(text: widget.store.shiftLead);
    _handoverWindow = TextEditingController(text: widget.store.handoverWindow);
  }

  @override
  void dispose() {
    _siteName.dispose();
    _shiftLead.dispose();
    _handoverWindow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings and privacy')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Shift profile'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _siteName,
                        decoration: const InputDecoration(
                          labelText: 'Site name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _shiftLead,
                        decoration: const InputDecoration(
                          labelText: 'Shift lead',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _handoverWindow,
                        decoration: const InputDecoration(
                          labelText: 'Handover window',
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => widget.store.saveSettings(
                          siteName: _siteName.text,
                          shiftLead: _shiftLead.text,
                          handoverWindow: _handoverWindow.text,
                        ),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save settings'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: 'Privacy'),
                      SizedBox(height: 10),
                      Text(
                        '$appName stores shipment logs, container records, tasks, patrol logs, and preferences on this device only.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No account registration, cloud sync, analytics, location tracking, advertising identifiers, or external service calls are used.',
                      ),
                      SizedBox(height: 8),
                      Text('Support contact: $supportEmail'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: widget.store.items.isEmpty
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear local records?'),
                            content: const Text(
                              'This removes records saved on this device.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed ?? false) {
                          await widget.store.clearAll();
                        }
                      },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear local records'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 44) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: cardColor),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _brandNavy,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 36, color: colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Color.alphaBlend(color.withValues(alpha: 0.35), _brandNavy),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FormLabels {
  const FormLabels(this.primary, this.detail, this.owner);

  final String primary;
  final String detail;
  final String owner;
}

FormLabels formLabels(Workstream type) {
  return switch (type) {
    Workstream.shipments => const FormLabels(
      'Shipment reference',
      'Route or consignee',
      'Dispatcher',
    ),
    Workstream.containers => const FormLabels(
      'Container number',
      'Yard slot or seal',
      'Handler',
    ),
    Workstream.tasks => const FormLabels('Task title', 'Work area', 'Owner'),
    Workstream.patrols => const FormLabels(
      'Patrol route',
      'Checkpoint outcome',
      'Guard',
    ),
  };
}

List<String> statusOptions(Workstream type) {
  return switch (type) {
    Workstream.shipments => const [
      'Queued',
      'In transit',
      'Customs hold',
      'Delivered',
    ],
    Workstream.containers => const [
      'To inspect',
      'In yard',
      'Loaded',
      'Released',
    ],
    Workstream.tasks => const ['Open', 'In progress', 'Blocked', 'Done'],
    Workstream.patrols => const [
      'Scheduled',
      'In progress',
      'Issue found',
      'Complete',
    ],
  };
}

extension on String {
  String toTitleCase() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

List<OperationItem> _sampleItems() {
  final now = DateTime(2026, 5, 11, 8, 30);
  return [
    OperationItem(
      id: 'sample-shipment-1',
      type: Workstream.shipments,
      title: 'CM-4821 outbound',
      detail: 'Warehouse A to Port Gate 4',
      owner: 'Nadia',
      status: 'In transit',
      dueLabel: '14:30 today',
      priority: 'High',
      progress: 62,
      notes: 'Driver checked in, seal photo verified at dispatch desk.',
      createdAt: now.subtract(const Duration(minutes: 25)),
    ),
    OperationItem(
      id: 'sample-container-1',
      type: Workstream.containers,
      title: 'MSCU 778241-6',
      detail: 'Yard B-18 • seal 442913',
      owner: 'Karim',
      status: 'In yard',
      dueLabel: 'Gate check',
      priority: 'Critical',
      progress: 35,
      notes: 'Hold for supervisor review before release paperwork.',
      createdAt: now.subtract(const Duration(minutes: 45)),
    ),
    OperationItem(
      id: 'sample-task-1',
      type: Workstream.tasks,
      title: 'Prepare customs packet',
      detail: 'Office counter and scanner station',
      owner: 'Meryem',
      status: 'In progress',
      dueLabel: 'Before 12:00',
      priority: 'High',
      progress: 50,
      notes: 'Invoice set complete; waiting for container inspection note.',
      createdAt: now.subtract(const Duration(hours: 1)),
    ),
    OperationItem(
      id: 'sample-patrol-1',
      type: Workstream.patrols,
      title: 'Perimeter route 2',
      detail: '6 checkpoints • east fence clear',
      owner: 'Youssef',
      status: 'Complete',
      dueLabel: '09:00 round',
      priority: 'Standard',
      progress: 100,
      notes: 'Gate lock checked and visitor lane reset.',
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    OperationItem(
      id: 'sample-shipment-2',
      type: Workstream.shipments,
      title: 'CM-4880 inbound',
      detail: 'Supplier dock to storage bay C',
      owner: 'Imane',
      status: 'Queued',
      dueLabel: '16:00 today',
      priority: 'Standard',
      progress: 15,
      notes: 'Awaiting arrival call from carrier.',
      createdAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}
