import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

// This reconstructed app intentionally runs in owner-authorized Free Mode.
// No purchase SDK, paywall, or premium entitlement check is used in this build.
class AppEntitlements {
  static const bool freeModeEnabled = true;
  static const bool premiumGateEnabled = false;
}

void main() => runApp(const PocketFlashRecoveryApp());

class PocketFlashRecoveryApp extends StatelessWidget {
  const PocketFlashRecoveryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PocketFlash',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)), useMaterial3: true),
        home: const LibraryScreen(),
      );
}

class GameFile {
  const GameFile(this.name, this.path);
  final String name;
  final String path;
  Map<String, String> toJson() => {'name': name, 'path': path};
  factory GameFile.fromJson(Map<String, dynamic> json) => GameFile(json['name'] as String, json['path'] as String);
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<GameFile> games = [];
  bool busy = false;
  static const _libraryKey = 'recovery_library_v1';

  @override
  void initState() { super.initState(); _loadLibrary(); }

  Future<Directory> _gameDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/swf_games');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _loadLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_libraryKey) ?? [];
    final loaded = <GameFile>[];
    for (final item in raw) {
      try {
        final game = GameFile.fromJson(jsonDecode(item) as Map<String, dynamic>);
        if (await File(game.path).exists()) loaded.add(game);
      } catch (_) { /* Skip corrupt legacy entries. */ }
    }
    if (mounted) setState(() => games = loaded);
  }

  Future<void> _saveLibrary() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_libraryKey, games.map((g) => jsonEncode(g.toJson())).toList());
  }

  Future<void> _importSwf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: const ['swf'], withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) throw Exception('File bytes unavailable. Try selecting the file again.');
      setState(() => busy = true);
      final dir = await _gameDirectory();
      final safeName = picked.name.replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '_');
      final target = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName');
      await target.writeAsBytes(bytes, flush: true);
      games = [GameFile(picked.name, target.path), ...games.where((g) => g.path != target.path)];
      await _saveLibrary();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported ${picked.name}')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _delete(GameFile game) async {
    try { final f = File(game.path); if (await f.exists()) await f.delete(); } catch (_) {}
    setState(() => games.removeWhere((g) => g.path == game.path));
    await _saveLibrary();
  }

  Future<void> _play(GameFile game) async {
    try {
      final bytes = await File(game.path).readAsBytes();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlayerScreen(title: game.name, swfBase64: base64Encode(bytes))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open game: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PocketFlash'), actions: [IconButton(tooltip: 'Import SWF', onPressed: busy ? null : _importSwf, icon: const Icon(Icons.add))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: busy ? null : _importSwf, icon: const Icon(Icons.file_open), label: const Text('Import SWF')),
    body: Column(children: [
      if (busy) const LinearProgressIndicator(),
      Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 4), child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [const Icon(Icons.info_outline), const SizedBox(width: 12), Expanded(child: Text('FREE MODE · Included features are available without an in-app purchase. Import a .swf file, then tap it to try playback with the bundled Ruffle engine.'))])))),
      Expanded(child: games.isEmpty ? const Center(child: Padding(padding: EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.sports_esports_outlined, size: 56), SizedBox(height: 12), Text('No games imported', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), SizedBox(height: 6), Text('Tap “Import SWF” to add a local Flash game.', textAlign: TextAlign.center)]))) : ListView.separated(
        itemCount: games.length, separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) { final game = games[index]; return ListTile(leading: const CircleAvatar(child: Icon(Icons.sports_esports)), title: Text(game.name, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: const Text('Local SWF file'), onTap: () => _play(game), trailing: PopupMenuButton<String>(onSelected: (v) { if (v == 'delete') _delete(game); }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Remove from library'))])); },
      )))
    ]),
  );
}

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.title, required this.swfBase64});
  final String title;
  final String swfBase64;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController controller;
  bool loadedPage = false;
  bool sentGame = false;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) { loadedPage = true; _sendGameWhenReady(); }, onWebResourceError: (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Player resource error: ${e.description}'))); }))
      ..loadFlutterAsset('assets/player.html');
  }

  Future<void> _sendGameWhenReady() async {
    if (!loadedPage || sentGame) return;
    sentGame = true;
    final encoded = jsonEncode(widget.swfBase64);
    // player.html defines loadSwfBase64 and waits for Ruffle initialization.
    await controller.runJavaScript('window.loadSwfBase64($encoded);');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis), backgroundColor: Colors.black, foregroundColor: Colors.white),
    body: WebViewWidget(controller: controller),
  );
}
