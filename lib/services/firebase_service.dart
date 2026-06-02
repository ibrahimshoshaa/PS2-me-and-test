import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════════
// FirebaseService — مقسّم لمسارات منفصلة حسب نوع البيانات (Optimized for Bandwidth)
// ═══════════════════════════════════════════════════════════════════════════════

class FirebaseService {
  static const String _baseUrl =
      'https://psmanagementapp-default-rtdb.firebaseio.com';
  
  static const String _secret = String.fromEnvironment(
    'FB_SECRET',
    defaultValue: 'uy6vaerRBXq497rXIltP2F5NJCn75dyev9DeHeSF',
  );

  static String _url(String path) => '$_baseUrl/$path.json?auth=$_secret';

  /// مثل `_url` لكن بيقبل query params إضافية (مثلاً limitToLast)
  static String _urlWithQuery(String path, Map<String, String> params) {
    final base = '$_baseUrl/$path.json?auth=$_secret';
    if (params.isEmpty) return base;
    final extra = params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    return '$base&$extra';
  }

  // ─── CRUD الأساسي ──────────────────────────────────────────────────────────

  static Future<dynamic> get(String path) async {
    try {
      final r = await http
          .get(Uri.parse(_url(path)))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) {
      print('Firebase GET error [$path]: $e');
    }
    return null;
  }

  static Future<bool> set(String path, dynamic data) async {
    try {
      final r = await http
          .put(Uri.parse(_url(path)), body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (e) {
      print('Firebase SET error [$path]: $e');
      return false;
    }
  }

  static Future<bool> patch(String path, dynamic data) async {
    try {
      final r = await http
          .patch(Uri.parse(_url(path)), body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (e) {
      print('Firebase PATCH error [$path]: $e');
      return false;
    }
  }

  static Future<bool> post(String path, dynamic data) async {
    try {
      final r = await http
          .post(Uri.parse(_url(path)), body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (e) {
      print('Firebase POST error [$path]: $e');
      return false;
    }
  }

  static Future<String?> push(String path, dynamic data) async {
    try {
      final r = await http
          .post(Uri.parse(_url(path)), body: jsonEncode(data))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        return jsonDecode(r.body)['name'];
      }
    } catch (e) {
      print('Firebase PUSH error [$path]: $e');
    }
    return null;
  }

  static Future<bool> delete(String path) async {
    try {
      final r = await http
          .delete(Uri.parse(_url(path)))
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 200;
    } catch (e) {
      print('Firebase DELETE error [$path]: $e');
      return false;
    }
  }

  // ─── المسارات المتوفرة ───────────────────────────────────────────────────────

  static String devicesStatePath(String shopId) => 'shops/$shopId/realtime/devices_state';
  static String tablesStatePath(String shopId) => 'shops/$shopId/realtime/tables_state';
  static String drinkTablesStatePath(String shopId) => 'shops/$shopId/realtime/drink_tables_state';
  static String tablesPath(String shopId) => 'shops/$shopId/operational/tables';
  static String drinkTablesPath(String shopId) => 'shops/$shopId/operational/drink_tables';
  static String staticDataPath(String shopId) => 'shops/$shopId/static';
  static String pricesPath(String shopId) => 'shops/$shopId/static/prices';
  static String menuPath(String shopId) => 'shops/$shopId/static/menu';
  static String inventoryPath(String shopId) => 'shops/$shopId/static/inventory';
  static String settingsPath(String shopId) => 'shops/$shopId/static/settings';
  static String cashiersPath(String shopId) => 'shops/$shopId/static/cashiers';
  static String debtsPath(String shopId) => 'shops/$shopId/static/debts';
  static String historyPath(String shopId) => 'shops/$shopId/records/history';
  static String dailySummaryPath(String shopId) => 'shops/$shopId/records/daily_summary';
  static String shiftsHistoryPath(String shopId) => 'shops/$shopId/records/shifts_history';
  static String openShiftsPath(String shopId) => 'shops/$shopId/records/open_shifts';
  static String shopArchivePath(String shopId) => 'shops/$shopId/archives';
  static String shopArchiveDetailsPath(String shopId) => 'shops/$shopId/archive_details';
  static String shopArchiveDetailPath(String shopId, String archiveId) => 'shops/$shopId/archive_details/$archiveId';
  static String shopYearlyArchivePath(String shopId) => 'shops/$shopId/yearly_archives';
  static String shopSubscriptionPath(String shopId) => 'shops/$shopId/subscription';
  static String shopTournamentsPath(String shopId) => 'shops/$shopId/tournaments';
  static String customerOrdersPath(String shopId) => 'shops/$shopId/customer_orders';
  static String shopDataPath(String shopId) => 'shops/$shopId/app_data';

  // ─── Realtime Push Sync ────────────────────────────────────────────────────

  static Future<bool> pushDevicesState(String shopId, List<Map<String, dynamic>> devicesState, String senderId) async {
    return set(devicesStatePath(shopId), {
      'devices': devicesState,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    });
  }

  static Future<bool> pushSingleDeviceState(String shopId, int deviceIndex, Map<String, dynamic> deviceData, String senderId) async {
    final updateData = {
      'devices/$deviceIndex': deviceData,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    };
    return patch(devicesStatePath(shopId), updateData);
  }

  static Future<bool> pushTablesState(String shopId, List<Map<String, dynamic>> tables, String senderId) async {
    return set(tablesStatePath(shopId), {
      'tables': tables,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    });
  }

  static Future<bool> pushDrinkTablesState(String shopId, List<Map<String, dynamic>> drinkTables, String senderId) async {
    return set(drinkTablesStatePath(shopId), {
      'drink_tables': drinkTables,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    });
  }

  static Future<bool> pushTables(String shopId, List<Map<String, dynamic>> tables) async {
    return set(tablesPath(shopId), tables);
  }

  static Future<bool> pushDrinkTables(String shopId, List<Map<String, dynamic>> drinkTables) async {
    return set(drinkTablesPath(shopId), drinkTables);
  }

  static Future<bool> pushStaticData(String shopId, Map<String, dynamic> staticData) async {
    return set(staticDataPath(shopId), staticData);
  }

  static Future<bool> appendSingleHistoryRecord(String shopId, Map<String, dynamic> singleRecord) async {
    return post(historyPath(shopId), singleRecord);
  }

  static Future<bool> pushOpenShifts(String shopId, Map<String, dynamic> openShifts, [String? senderId]) async {
    final data = Map<String, dynamic>.from(openShifts);
    if (senderId != null) data['_sender_id'] = senderId;
    return set(openShiftsPath(shopId), data);
  }

  static Future<bool> pushShiftsHistory(String shopId, List<Map<String, dynamic>> shifts) async {
    return set(shiftsHistoryPath(shopId), shifts);
  }

  static Future<bool> pushDebts(String shopId, List<Map<String, dynamic>> debts) async {
    return set(debtsPath(shopId), debts);
  }

  static Future<bool> pushTournaments(String shopId, List<Map<String, dynamic>> tournaments) async {
    return set(shopTournamentsPath(shopId), tournaments);
  }

  // ─── Archives ──────────────────────────────────────────────────────────────

  static Future<String?> pushArchive({
    required String shopId,
    required String date,
    required double totalTime,
    required double totalBuffet,
    required double totalOverall,
  }) async {
    return push(shopArchivePath(shopId), {
      'date': date,
      'total_time': totalTime,
      'total_buffet': totalBuffet,
      'total_overall': totalOverall,
    });
  }

  static Future<List<Map<String, dynamic>>?> getArchiveDetails(String shopId, String archiveId) async {
    try {
      final data = await get(shopArchiveDetailPath(shopId, archiveId));
      if (data == null || data is! Map) return null;
      final records = data['records'];
      if (records == null) return [];
      if (records is List) {
        return records.whereType<Map>().map((r) => Map<String, dynamic>.from(r)).toList();
      }
      return [];
    } catch (e) {
      print('Firebase getArchiveDetails error [$archiveId]: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getArchivesList(String shopId) async {
    try {
      final data = await get(shopArchivePath(shopId));
      if (data == null) return [];
      if (data is Map) {
        return data.entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          m['_id'] = e.key;
          return m;
        }).toList()
          ..sort((a, b) {
            final da = DateTime.tryParse(a['date']?.toString() ?? '');
            final db = DateTime.tryParse(b['date']?.toString() ?? '');
            if (da == null || db == null) return 0;
            return db.compareTo(da);
          });
      }
      return [];
    } catch (e) {
      print('Firebase getArchivesList error: $e');
      return [];
    }
  }

  // ─── OPTIMIZED LAZY-LOADING ON-DEMAND METHODS (Requirement 1 & 2) ───────────

  /// Paginates history items via REST parameters to download only the last 15 items
  static Future<List<Map<String, dynamic>>> getRecentHistory(String shopId, {int limit = 15}) async {
    try {
      final url = _urlWithQuery(historyPath(shopId), {
        'limitToLast': limit.toString(),
        'orderBy': r'"$key"',
      });
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body);
      if (body == null) return [];
      if (body is List) {
        return body.whereType<Map>().map((h) => Map<String, dynamic>.from(h)).toList();
      }
      if (body is Map) {
        final list = body.values.whereType<Map>().map((h) => Map<String, dynamic>.from(h)).toList();
        _sortHistoryByDate(list);
        return list;
      }
    } catch (e) {
      print('Firebase getRecentHistory error: $e');
    }
    return [];
  }

  /// Standalone fetching for Debts node on demand
  static Future<List<Map<String, dynamic>>> getDebts(String shopId) async {
    try {
      final data = await get(debtsPath(shopId));
      if (data == null) return [];
      if (data is List) return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (data is Map) return data.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Firebase getDebts error: $e');
    }
    return [];
  }

  /// Standalone fetching for Tournaments node on demand
  static Future<List<Map<String, dynamic>>> getTournaments(String shopId) async {
    try {
      final data = await get(shopTournamentsPath(shopId));
      if (data == null) return [];
      if (data is List) return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (data is Map) return data.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Firebase getTournaments error: $e');
    }
    return [];
  }

  /// Standalone fetching for Shifts History node on demand
  static Future<List<Map<String, dynamic>>> getShiftsHistory(String shopId) async {
    try {
      final data = await get(shiftsHistoryPath(shopId));
      if (data == null) return [];
      if (data is List) return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (data is Map) return data.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      print('Firebase getShiftsHistory error: $e');
    }
    return [];
  }

  // ─── OPTIMIZED LOOP CONTROL (Requirement 3) ─────────────────────────────────

  /// EXCLUDES all heavy historical nodes entirely. Used strictly during single startup initialization.
  static Future<Map<String, dynamic>?> pullAllData(String shopId) async {
    try {
      final oldData = await get(shopDataPath(shopId));

      final results = await Future.wait([
        get(devicesStatePath(shopId)),
        get(tablesStatePath(shopId)),
        get(drinkTablesStatePath(shopId)),
        get(staticDataPath(shopId)),
        get(dailySummaryPath(shopId)),
        get(openShiftsPath(shopId)),
        get(tablesPath(shopId)),
        get(drinkTablesPath(shopId)),
      ]);

      final devicesData       = results[0];
      final tablesRealtime    = results[1];
      final drinkRealtime     = results[2];
      final staticData        = results[3];
      final dailySummaryData  = results[4];
      final openShiftsData    = results[5];
      final tablesOld         = results[6];
      final drinkOld          = results[7];

      final combined = <String, dynamic>{};

      if (devicesData != null && devicesData is Map) {
        final devices = devicesData['devices'];
        if (devices != null) combined['devices_state'] = devices;
      } else if (oldData != null && oldData is Map) {
        combined['devices_state'] = oldData['devices_state'] ?? [];
      }

      if (tablesRealtime != null && tablesRealtime is Map) {
        final t = tablesRealtime['tables'];
        combined['tables'] = (t != null && t is List) ? t : [];
      } else if (tablesOld != null) {
        combined['tables'] = tablesOld is List ? tablesOld : [];
      } else if (oldData != null && oldData is Map) {
        combined['tables'] = oldData['tables'] ?? [];
      }

      if (drinkRealtime != null && drinkRealtime is Map) {
        final d = drinkRealtime['drink_tables'];
        combined['drink_tables'] = (d != null && d is List) ? d : [];
      } else if (drinkOld != null) {
        combined['drink_tables'] = drinkOld is List ? drinkOld : [];
      } else if (oldData != null && oldData is Map) {
        combined['drink_tables'] = oldData['drink_tables'] ?? [];
      }

      if (staticData != null && staticData is Map) {
        final s = Map<String, dynamic>.from(staticData);
        combined['prices'] = s['prices'];
        combined['menu'] = s['menu'];
        combined['inventory'] = s['inventory'];
        combined['cashiers'] = s['cashiers'];
        combined['admin_password_hash'] = s['admin_password_hash'];
        combined['shop_name'] = s['shop_name'];
        combined['match_enabled'] = s['match_enabled'];
        combined['num_devices'] = s['num_devices'];
      }

      // Safe defaults to ensure UI continuity without downloading backend structures
      combined['history'] = [];
      combined['shifts_history'] = [];
      combined['debts'] = [];
      combined['tournaments'] = [];

      if (dailySummaryData != null && dailySummaryData is Map) {
        combined['daily_inventory_summary'] = Map<String, dynamic>.from(dailySummaryData);
      }
      if (openShiftsData != null && openShiftsData is Map) {
        combined['open_shifts'] = Map<String, dynamic>.from(openShiftsData);
      }

      combined['last_updated'] = DateTime.now().millisecondsSinceEpoch;
      return combined;
    } catch (e) {
      print('Firebase pullAllData error: $e');
      return null;
    }
  }

  /// Minimal operational footprint method targeted for continuous polling fallback loops (_pollAll)
  static Future<Map<String, dynamic>?> pullEssentialRealtimeData(String shopId) async {
    try {
      final results = await Future.wait([
        get(devicesStatePath(shopId)),
        get(tablesStatePath(shopId)),
        get(drinkTablesStatePath(shopId)),
        get(openShiftsPath(shopId)),
      ]);

      final combined = <String, dynamic>{};

      if (results[0] != null && results[0] is Map) {
        final devices = results[0]['devices'];
        if (devices != null) combined['devices_state'] = devices;
      }
      if (results[1] != null && results[1] is Map) {
        final t = results[1]['tables'];
        combined['tables'] = (t != null && t is List) ? t : [];
      }
      if (results[2] != null && results[2] is Map) {
        final d = results[2]['drink_tables'];
        combined['drink_tables'] = (d != null && d is List) ? d : [];
      }
      if (results[3] != null && results[3] is Map) {
        combined['open_shifts'] = Map<String, dynamic>.from(results[3]);
      }

      combined['last_updated'] = DateTime.now().millisecondsSinceEpoch;
      return combined;
    } catch (e) {
      print('Firebase pullEssentialRealtimeData error: $e');
      return null;
    }
  }

  // ─── Stream Subscriptions ──────────────────────────────────────────────────

  static StreamSubscription<dynamic> listenToDevices(String shopId, {required void Function(Map<String, dynamic> rawData, List<Map<String, dynamic>> devices) onData, void Function(Object error)? onError}) {
    return listen(devicesStatePath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final eventData = payload['data'];
      if (eventData != null && eventData is Map) {
        final devices = eventData['devices'];
        if (devices is List) {
          final typed = devices.map((d) => d != null ? Map<String, dynamic>.from(d as Map) : <String, dynamic>{}).toList();
          onData(Map<String, dynamic>.from(eventData), typed);
        }
      }
    }, onError: onError);
  }

  static StreamSubscription<dynamic> listenToTables(String shopId, {required void Function(Map<String, dynamic> rawData, List<Map<String, dynamic>> tables) onData, void Function(Object error)? onError}) {
    return listen(tablesStatePath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final eventData = payload['data'];
      if (eventData == null || eventData is! Map) return;
      final tables = eventData['tables'];
      if (tables is List) {
        final typed = tables.map((t) => t != null ? Map<String, dynamic>.from(t as Map) : <String, dynamic>{}).toList();
        onData(Map<String, dynamic>.from(eventData), typed);
      }
    }, onError: onError);
  }

  static StreamSubscription<dynamic> listenToDrinkTables(String shopId, {required void Function(Map<String, dynamic> rawData, List<Map<String, dynamic>> drinkTables) onData, void Function(Object error)? onError}) {
    return listen(drinkTablesStatePath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final eventData = payload['data'];
      if (eventData == null || eventData is! Map) return;
      final drinkTables = eventData['drink_tables'];
      if (drinkTables is List) {
        final typed = drinkTables.map((t) => t != null ? Map<String, dynamic>.from(t as Map) : <String, dynamic>{}).toList();
        onData(Map<String, dynamic>.from(eventData), typed);
      }
    }, onError: onError);
  }

  static StreamSubscription<dynamic> listenToHistory(String shopId, {int limit = 15, required void Function(List<Map<String, dynamic>> history) onData, void Function(Object error)? onError}) {
    final fullUrl = _urlWithQuery(historyPath(shopId), {
      'limitToLast': limit.toString(),
      'orderBy': r'"$key"',
    });
    return _listenRaw(fullUrl, onData: (payload) {
      if (payload == null || payload is! Map) return;
      final data = payload['data'];
      if (data == null) { onData([]); return; }
      if (data is Map) {
        final typed = data.values.map((h) => Map<String, dynamic>.from(h as Map)).toList();
        _sortHistoryByDate(typed);
        onData(typed);
      } else if (data is List) {
        final typed = data.map((h) => h != null ? Map<String, dynamic>.from(h as Map) : <String, dynamic>{}).toList();
        _sortHistoryByDate(typed);
        onData(typed);
      }
    }, onError: onError);
  }

  static void _sortHistoryByDate(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final aVal = a['date'] ?? a['timestamp'] ?? a['created_at'];
      final bVal = b['date'] ?? b['timestamp'] ?? b['created_at'];
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return -1;
      if (bVal == null) return 1;
      if (aVal is num && bVal is num) return aVal.compareTo(bVal);
      return aVal.toString().compareTo(bVal.toString());
    });
  }

  static StreamSubscription<dynamic> listenToDailySummary(String shopId, {required void Function(Map<String, int> summary) onData, void Function(Object error)? onError}) {
    return listen(dailySummaryPath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final data = payload['data'];
      if (data is Map) {
        onData(Map<String, int>.from(data.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))));
      }
    }, onError: onError);
  }

  static StreamSubscription<dynamic> listenToShiftsHistory(String shopId, {required void Function(List<Map<String, dynamic>> shifts) onData, void Function(Object error)? onError}) {
    return listen(shiftsHistoryPath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final data = payload['data'];
      if (data is List) {
        onData(data.map((s) => s != null ? Map<String, dynamic>.from(s as Map) : <String, dynamic>{}).toList());
      }
    }, onError: onError);
  }

  static StreamSubscription<dynamic> listenToStatic(String shopId, {required void Function(Map<String, dynamic> data) onData, void Function(Object error)? onError}) {
    return listen(staticDataPath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final data = payload['data'];
      if (data is Map) onData(Map<String, dynamic>.from(data));
    }, onError: onError);
  }

  static StreamSubscription<dynamic> listen(String path, {required void Function(dynamic data) onData, void Function(Object error)? onError, void Function()? onDone}) {
    final controller = StreamController<dynamic>.broadcast();
    bool cancelled = false;
    Future<void> connect() async {
      while (!cancelled) {
        http.Client? client;
        try {
          client = http.Client();
          final request = http.Request('GET', Uri.parse(_url(path)))..headers['Accept'] = 'text/event-stream'..headers['Cache-Control'] = 'no-cache';
          final response = await client.send(request);
          if (response.statusCode != 200) { client.close(); await Future.delayed(const Duration(seconds: 2)); continue; }
          StringBuffer buffer = StringBuffer();
          await for (final chunk in response.stream.transform(utf8.decoder)) {
            if (cancelled) break;
            buffer.write(chunk);
            final raw = buffer.toString();
            final blocks = raw.split('\n\n');
            for (int i = 0; i < blocks.length - 1; i++) { _processSSEBlock(blocks[i], controller); }
            buffer = StringBuffer(blocks.last);
          }
        } catch (e) { if (!cancelled) onError?.call(e); } finally { client?.close(); }
        if (!cancelled) await Future.delayed(const Duration(seconds: 2));
      }
      if (!controller.isClosed) controller.close();
      onDone?.call();
    }
    connect();
    return _CancellableSubscription(controller.stream.listen(onData, onError: onError), onCancel: () => cancelled = true);
  }

  static StreamSubscription<dynamic> _listenRaw(String fullUrl, {required void Function(dynamic data) onData, void Function(Object error)? onError, void Function()? onDone}) {
    final controller = StreamController<dynamic>.broadcast();
    bool cancelled = false;
    Future<void> connect() async {
      while (!cancelled) {
        http.Client? client;
        try {
          client = http.Client();
          final request = http.Request('GET', Uri.parse(fullUrl))..headers['Accept'] = 'text/event-stream'..headers['Cache-Control'] = 'no-cache';
          final response = await client.send(request);
          if (response.statusCode != 200) { client.close(); await Future.delayed(const Duration(seconds: 2)); continue; }
          StringBuffer buffer = StringBuffer();
          await for (final chunk in response.stream.transform(utf8.decoder)) {
            if (cancelled) break;
            buffer.write(chunk);
            final raw = buffer.toString();
            final blocks = raw.split('\n\n');
            for (int i = 0; i < blocks.length - 1; i++) { _processSSEBlock(blocks[i], controller); }
            buffer = StringBuffer(blocks.last);
          }
        } catch (e) { if (!cancelled) onError?.call(e); } finally { client?.close(); }
        if (!cancelled) await Future.delayed(const Duration(seconds: 2));
      }
      if (!controller.isClosed) controller.close();
      onDone?.call();
    }
    connect();
    return _CancellableSubscription(controller.stream.listen(onData, onError: onError), onCancel: () => cancelled = true);
  }

  static void _processSSEBlock(String block, StreamController<dynamic> controller) {
    String? eventType; String? dataLine;
    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) eventType = line.substring(6).trim();
      else if (line.startsWith('data:')) dataLine = line.substring(5).trim();
    }
    if ((eventType == 'put' || eventType == 'patch') && dataLine != null) {
      try {
        final parsed = jsonDecode(dataLine);
        if (!controller.isClosed) controller.add({'event': eventType, 'path': parsed['path'], 'data': parsed['data']});
      } catch (_) {}
    }
  }

  static Future<Map<String, dynamic>?> getSubscriptionWithTimestamp(String shopId) async {
    try {
      final subFuture = http.get(Uri.parse(_url(shopSubscriptionPath(shopId)))).timeout(const Duration(seconds: 10));
      final timeFuture = http.get(Uri.parse('$_baseUrl/.json?shallow=true&auth=$_secret')).timeout(const Duration(seconds: 10));
      final results = await Future.wait([subFuture, timeFuture]);
      if (results[0].statusCode != 200) return null;
      final subData = jsonDecode(results[0].body);
      if (subData == null || subData is! Map) return null;
      final result = Map<String, dynamic>.from(subData);
      final dateHeader = results[1].headers['date'];
      if (dateHeader != null) {
        try { result['_server_time_ms'] = DateTime.parse(dateHeader).millisecondsSinceEpoch; } catch (_) { result['_server_time_ms'] = DateTime.now().millisecondsSinceEpoch; }
      } else { result['_server_time_ms'] = DateTime.now().millisecondsSinceEpoch; }
      return result;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>?> getSubscription(String shopId) async {
    final data = await get(shopSubscriptionPath(shopId));
    if (data == null || data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getAllOpenShifts(String shopId) async {
    try {
      final data = await get(openShiftsPath(shopId));
      if (data == null || data is! Map) return {};
      return Map<String, dynamic>.from(data);
    } catch (_) { return {}; }
  }

  static StreamSubscription<dynamic> listenToOpenShifts(String shopId, {String? senderId, required void Function(Map<String, dynamic> openShifts) onData, void Function(Object error)? onError}) {
    return listen(openShiftsPath(shopId), onData: (payload) {
      if (payload == null || payload is! Map) return;
      final raw = payload['data'];
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw);
        if (senderId != null && data['_sender_id'] == senderId) return;
        data.remove('_sender_id');
        onData(data);
      } else { onData({}); }
    }, onError: onError);
  }
}

class _CancellableSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _inner; final void Function() onCancel;
  _CancellableSubscription(this._inner, {required this.onCancel});
  @override Future<void> cancel() { onCancel(); return _inner.cancel(); }
  @override bool get isPaused => _inner.isPaused;
  @override void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);
  @override void resume() => _inner.resume();
  @override void onData(void Function(T data)? handleData) => _inner.onData(handleData);
  @override void onError(Function? handleError) => _inner.onError(handleError);
  @override void onDone(void Function()? handleDone) => _inner.onDone(handleDone);
  @override Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}
