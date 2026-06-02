import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ═══════════════════════════════════════════════════════════════════════════════
// FirebaseService — مقسّم لمسارات منفصلة حسب نوع البيانات
//
// المسارات:
//   realtime/devices_state      ← حالة الأجهزة (SSE - فوري)
//   realtime/tables_state       ← حالة التربيزات (SSE - فوري) ← جديد
//   realtime/drink_tables_state ← حالة تربيزات المشروبات (SSE - فوري) ← جديد
//   static/                     ← أسعار ومنيو وإعدادات (push عند التعديل)
//   records/history             ← السجلات اليومية (append)
//   records/shifts              ← الشيفتات (append)
//   archives/                   ← الأرشيف (append فقط)
//   yearly_archives/            ← الأرشيف السنوي
//   subscription                ← بيانات الاشتراك
//   tournaments                 ← البطولات
//   customer_orders             ← طلبات العملاء
// ═══════════════════════════════════════════════════════════════════════════════

class FirebaseService {
  static const String _baseUrl =
      'https://psmanagementapp-default-rtdb.firebaseio.com';
  // ⚠️ TODO: انقل الـ secret ده لـ --dart-define أو Firebase Environment Config
  // flutter run --dart-define=FB_SECRET=your_secret
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

  // ═══════════════════════════════════════════════════════════════════════════
  // مسارات المحل — مقسّمة حسب نوع البيانات
  // ═══════════════════════════════════════════════════════════════════════════

  static String devicesStatePath(String shopId) =>
      'shops/$shopId/realtime/devices_state';

  static String tablesStatePath(String shopId) =>
      'shops/$shopId/realtime/tables_state';

  static String drinkTablesStatePath(String shopId) =>
      'shops/$shopId/realtime/drink_tables_state';

  static String tablesPath(String shopId) =>
      'shops/$shopId/operational/tables';

  static String drinkTablesPath(String shopId) =>
      'shops/$shopId/operational/drink_tables';

  static String staticDataPath(String shopId) =>
      'shops/$shopId/static';

  static String pricesPath(String shopId) =>
      'shops/$shopId/static/prices';

  static String menuPath(String shopId) =>
      'shops/$shopId/static/menu';

  static String inventoryPath(String shopId) =>
      'shops/$shopId/static/inventory';

  static String settingsPath(String shopId) =>
      'shops/$shopId/static/settings';

  static String cashiersPath(String shopId) =>
      'shops/$shopId/static/cashiers';

  static String debtsPath(String shopId) =>
      'shops/$shopId/static/debts';

  static String historyPath(String shopId) =>
      'shops/$shopId/records/history';

  static String dailySummaryPath(String shopId) =>
      'shops/$shopId/records/daily_summary';

  static String shiftsHistoryPath(String shopId) =>
      'shops/$shopId/records/shifts_history';

  static String openShiftsPath(String shopId) =>
      'shops/$shopId/records/open_shifts';

  static String shopArchivePath(String shopId) =>
      'shops/$shopId/archives';

  /// مسار التفاصيل الكاملة للأرشيف اليومي (منفصل عن الإجماليات)
  static String shopArchiveDetailsPath(String shopId) =>
      'shops/$shopId/archive_details';

  /// مسار تفاصيل أرشيف يوم بعينه
  static String shopArchiveDetailPath(String shopId, String archiveId) =>
      'shops/$shopId/archive_details/$archiveId';

  static String shopYearlyArchivePath(String shopId) =>
      'shops/$shopId/yearly_archives';

  static String shopSubscriptionPath(String shopId) =>
      'shops/$shopId/subscription';

  static String shopTournamentsPath(String shopId) =>
      'shops/$shopId/tournaments';

  static String customerOrdersPath(String shopId) =>
      'shops/$shopId/customer_orders';

  static String shopDataPath(String shopId) =>
      'shops/$shopId/app_data';

  // ═══════════════════════════════════════════════════════════════════════════
  // Push منفصل لكل نوع بيانات
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> pushDevicesState(
      String shopId,
      List<Map<String, dynamic>> devicesState,
      String senderId) async {
    return set(devicesStatePath(shopId), {
      'devices': devicesState,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    });
  }

  static Future<bool> pushSingleDeviceState(
      String shopId, int deviceIndex, Map<String, dynamic> deviceData, String senderId) async {
    final updateData = {
      'devices/$deviceIndex': deviceData,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    };
    return patch(devicesStatePath(shopId), updateData);
  }

  static Future<bool> pushTablesState(
    String shopId, List<Map<String, dynamic>> tables, String senderId) async {
    return set(tablesStatePath(shopId), {
      'tables': tables,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    });
  }

  static Future<bool> pushDrinkTablesState(
      String shopId, List<Map<String, dynamic>> drinkTables, String senderId) async {
    return set(drinkTablesStatePath(shopId), {
      'drink_tables': drinkTables,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
      'sender_id': senderId,
    });
  }

  static Future<bool> pushTables(
      String shopId, List<Map<String, dynamic>> tables) async {
    return set(tablesPath(shopId), tables);
  }

  static Future<bool> pushDrinkTables(
      String shopId, List<Map<String, dynamic>> drinkTables) async {
    return set(drinkTablesPath(shopId), drinkTables);
  }

  static Future<bool> pushStaticData(
      String shopId, Map<String, dynamic> staticData) async {
    return set(staticDataPath(shopId), staticData);
  }



  static Future<bool> appendSingleHistoryRecord(
      String shopId, Map<String, dynamic> singleRecord) async {
    return post(historyPath(shopId), singleRecord);
  }

  static Future<bool> pushOpenShifts(
      String shopId, Map<String, dynamic> openShifts, [String? senderId]) async {
    final data = Map<String, dynamic>.from(openShifts);
    if (senderId != null) data['_sender_id'] = senderId;
    return set(openShiftsPath(shopId), data);
  }

  static Future<bool> pushShiftsHistory(
      String shopId, List<Map<String, dynamic>> shifts) async {
    return set(shiftsHistoryPath(shopId), shifts);
  }

  static Future<bool> pushDebts(
      String shopId, List<Map<String, dynamic>> debts) async {
    return set(debtsPath(shopId), debts);
  }

  static Future<bool> pushTournaments(
      String shopId, List<Map<String, dynamic>> tournaments) async {
    return set(shopTournamentsPath(shopId), tournaments);
  }

  // ─── أرشيف مقسّم (إجماليات + تفاصيل منفصلة) ───────────────────────────

  /// يكتب الإجماليات في `archives` والجلسات الكاملة في `archive_details`.
  static Future<String?> pushArchiveWithDetails({
    required String shopId,
    required String date,
    required double totalTime,
    required double totalBuffet,
    required double totalOverall,
    required List<Map<String, dynamic>> records,
  }) async {
    final archiveId = await push(shopArchivePath(shopId), {
      'date': date,
      'total_time': totalTime,
      'total_buffet': totalBuffet,
      'total_overall': totalOverall,
      'records_count': records.length,
    });
    if (archiveId == null) return null;

    final ok = await set(shopArchiveDetailPath(shopId, archiveId), {
      'date': date,
      'records': records,
    });
    if (!ok) {
      await delete('${shopArchivePath(shopId)}/$archiveId');
      return null;
    }
    return archiveId;
  }

  /// يجيب التفاصيل الكاملة لأرشيف يوم معيّن (استخدمه عند الطلب فقط).
  static Future<List<Map<String, dynamic>>?> getArchiveDetails(
      String shopId, String archiveId) async {
    try {
      final data = await get(shopArchiveDetailPath(shopId, archiveId));
      if (data == null || data is! Map) return null;
      final records = data['records'];
      if (records == null) return [];
      if (records is List) {
        return records
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList();
      }
      return [];
    } catch (e) {
      print('Firebase getArchiveDetails error [$archiveId]: $e');
      return null;
    }
  }

  /// يجيب قائمة إجماليات الأرشيف بدون الجلسات (خفيف جداً).
  static Future<List<Map<String, dynamic>>> getArchivesList(
      String shopId) async {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Pull منفصل لكل نوع بيانات
  // ═══════════════════════════════════════════════════════════════════════════

  /// بيجيب آخر [limit] سجل من history باستخدام limitToLast
  /// — أسرع بكتير من تحميل كل السجلات لما تكون كتير
  static Future<List<Map<String, dynamic>>> getRecentHistory(
    String shopId, {
    int limit = 200,
  }) async {
    try {
      final url = _urlWithQuery(historyPath(shopId), {
        'limitToLast': limit.toString(),
        'orderBy': r'"$key"',
      });
      final r = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final body = jsonDecode(r.body);
      if (body == null) return [];
      if (body is List) {
        return body
            .whereType<Map>()
            .map((h) => Map<String, dynamic>.from(h))
            .toList();
      }
      if (body is Map) {
        final list = body.values
            .whereType<Map>()
            .map((h) => Map<String, dynamic>.from(h))
            .toList();
        list.sort((a, b) {
          final da = DateTime.tryParse(a['date']?.toString() ?? '');
          final db = DateTime.tryParse(b['date']?.toString() ?? '');
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });
        return list;
      }
      return [];
    } catch (e) {
      print('Firebase getRecentHistory error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> pullAllData(String shopId) async {
    try {
      final oldData = await get(shopDataPath(shopId));

      final results = await Future.wait([
        get(devicesStatePath(shopId)),
        get(tablesStatePath(shopId)),
        get(drinkTablesStatePath(shopId)),
        get(staticDataPath(shopId)),
        getRecentHistory(shopId),          // بدل get(historyPath) — أسرع
        get(dailySummaryPath(shopId)),
        get(shiftsHistoryPath(shopId)),
        get(openShiftsPath(shopId)),
        get(debtsPath(shopId)),
        get(shopTournamentsPath(shopId)),
        get(tablesPath(shopId)),
        get(drinkTablesPath(shopId)),
      ]);

      final devicesData      = results[0];
      final tablesRealtime   = results[1];
      final drinkRealtime    = results[2];
      final staticData       = results[3];
      final historyData      = results[4];
      final dailySummaryData = results[5];
      final shiftsHistoryData = results[6];
      final openShiftsData   = results[7];
      final debtsData        = results[8];
      final tournamentsData  = results[9];
      final tablesOld        = results[10];
      final drinkOld         = results[11];

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
      } else if (oldData != null && oldData is Map) {
        combined['prices'] = oldData['prices'];
        combined['menu'] = oldData['menu'];
        combined['inventory'] = oldData['inventory'];
        combined['cashiers'] = oldData['cashiers'];
        combined['cashier_password_hash'] = oldData['cashier_password_hash'];
        combined['admin_password_hash'] = oldData['admin_password_hash'];
        combined['shop_name'] = oldData['shop_name'];
        combined['match_enabled'] = oldData['match_enabled'];
        combined['num_devices'] = oldData['num_devices'];
      }

      if (historyData != null) {
        // getRecentHistory بترجع List مباشرة
        if (historyData is List) {
          combined['history'] = historyData;
        } else {
          combined['history'] = [];
        }
      } else if (oldData != null && oldData is Map) {
        combined['history'] = oldData['history'] ?? [];
      }

      if (dailySummaryData != null && dailySummaryData is Map) {
        combined['daily_inventory_summary'] = Map<String, dynamic>.from(dailySummaryData);
      } else if (oldData != null && oldData is Map) {
        combined['daily_inventory_summary'] = oldData['daily_inventory_summary'] ?? {};
      }

      if (shiftsHistoryData != null) {
        combined['shifts_history'] = shiftsHistoryData is List ? shiftsHistoryData : [];
      } else if (oldData != null && oldData is Map) {
        combined['shifts_history'] = oldData['shifts_history'] ?? [];
      }

      if (openShiftsData != null && openShiftsData is Map) {
        combined['open_shifts'] = Map<String, dynamic>.from(openShiftsData);
      } else if (oldData != null && oldData is Map) {
        combined['open_shifts'] = oldData['open_shifts'] ?? {};
      }

      if (debtsData != null) {
        combined['debts'] = debtsData is List ? debtsData : [];
      } else if (oldData != null && oldData is Map) {
        combined['debts'] = oldData['debts'] ?? [];
      }

      if (tournamentsData != null) {
        combined['tournaments'] = tournamentsData is List ? tournamentsData : [];
      } else if (oldData != null && oldData is Map) {
        combined['tournaments'] = oldData['tournaments'] ?? [];
      }

      combined['last_updated'] = DateTime.now().millisecondsSinceEpoch;

      return combined;
    } catch (e) {
      print('Firebase pullAllData error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> pullDevicesState(String shopId) async {
    try {
      final data = await get(devicesStatePath(shopId));
      if (data == null || data is! Map) return null;
      final devices = data['devices'];
      if (devices == null) return null;
      if (devices is List) {
        return devices.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static StreamSubscription<dynamic> listenToDevices(
    String shopId, {
    required void Function(
      Map<String, dynamic> rawData,
      List<Map<String, dynamic>> devices,
    ) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      devicesStatePath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;

        final eventPath = payload['path'] as String?;
        final eventData = payload['data'];

        if (eventPath != null && eventPath.startsWith('/devices/')) {
          // You can handle partial updates here or let the sync service re-fetch
          // In this implementation, we just pass the full device list if we have it
          // or we can just send back the whole rawData if eventData is a map and contains devices
        } 
        
        if (eventData != null && eventData is Map) {
          final devices = eventData['devices'];
          if (devices is List) {
            try {
              final typed = devices
                  .map((d) => d != null ? Map<String, dynamic>.from(d as Map) : <String,dynamic>{})
                  .toList();
              final rawData = Map<String, dynamic>.from(eventData);
              onData(rawData, typed);
            } catch (_) {}
          }
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  static StreamSubscription<dynamic> listenToTables(
    String shopId, {
    required void Function(Map<String, dynamic> rawData, List<Map<String, dynamic>> tables) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      tablesStatePath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final eventData = payload['data'];
        if (eventData == null || eventData is! Map) return;
        final tables = eventData['tables'];
        if (tables == null) return;
        if (tables is List) {
          try {
            final typed = tables
                .map((t) => t != null ? Map<String, dynamic>.from(t as Map) : <String,dynamic>{})
                .toList();
            final rawData = Map<String, dynamic>.from(eventData);
            onData(rawData, typed);
          } catch (_) {}
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  static StreamSubscription<dynamic> listenToDrinkTables(
    String shopId, {
    required void Function(Map<String, dynamic> rawData, List<Map<String, dynamic>> drinkTables) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      drinkTablesStatePath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final eventData = payload['data'];
        if (eventData == null || eventData is! Map) return;
        final drinkTables = eventData['drink_tables'];
        if (drinkTables == null) return;
        if (drinkTables is List) {
          try {
            final typed = drinkTables
                .map((t) => t != null ? Map<String, dynamic>.from(t as Map) : <String,dynamic>{})
                .toList();
            final rawData = Map<String, dynamic>.from(eventData);
            onData(rawData, typed);
          } catch (_) {}
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  static StreamSubscription<dynamic> listenToHistory(
    String shopId, {
    int limit = 200,
    required void Function(List<Map<String, dynamic>> history) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    final fullUrl = _urlWithQuery(historyPath(shopId), {
      'limitToLast': limit.toString(),
      'orderBy': r'"$key"',
    });
    return _listenRaw(
      fullUrl,
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final data = payload['data'];
        if (data == null) {
          onData([]);
          return;
        }
        if (data is Map) {
          try {
            final typed = data.values
                .map((h) => Map<String, dynamic>.from(h as Map))
                .toList();
            _sortHistoryByDate(typed);
            onData(typed);
          } catch (_) {}
        } else if (data is List) {
          try {
            final typed = data
                .map((h) => h != null ? Map<String, dynamic>.from(h as Map) : <String,dynamic>{})
                .toList();
            _sortHistoryByDate(typed);
            onData(typed);
          } catch (_) {}
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  /// فارز السجلات من الأقدم للأحدث حسب حقل date أو timestamp
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

  static StreamSubscription<dynamic> listenToDailySummary(
    String shopId, {
    required void Function(Map<String, int> summary) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      dailySummaryPath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final data = payload['data'];
        if (data == null) {
          onData({});
          return;
        }
        if (data is Map) {
          try {
            final typed = Map<String, int>.from(
              data.map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
            );
            onData(typed);
          } catch (_) {}
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  static StreamSubscription<dynamic> listenToShiftsHistory(
    String shopId, {
    required void Function(List<Map<String, dynamic>> shifts) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      shiftsHistoryPath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final data = payload['data'];
        if (data == null) { onData([]); return; }
        if (data is List) {
          try {
            final typed = data
                .map((s) => s != null ? Map<String, dynamic>.from(s as Map) : <String,dynamic>{})
                .toList();
            onData(typed);
          } catch (_) {}
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  static StreamSubscription<dynamic> listenToStatic(
    String shopId, {
    required void Function(Map<String, dynamic> data) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      staticDataPath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final data = payload['data'];
        if (data == null || data is! Map) return;
        try {
          onData(Map<String, dynamic>.from(data));
        } catch (_) {}
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }

  static StreamSubscription<dynamic> listen(
    String path, {
    required void Function(dynamic data) onData,
    void Function(Object error)? onError,
    void Function()? onDone,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    final controller = StreamController<dynamic>.broadcast();
    bool cancelled = false;

    Future<void> connect() async {
      while (!cancelled) {
        http.Client? client;
        try {
          client = http.Client();
          final request =
              http.Request('GET', Uri.parse(_url(path)));
          request.headers['Accept'] = 'text/event-stream';
          request.headers['Cache-Control'] = 'no-cache';

          final response = await client.send(request);

          if (response.statusCode != 200) {
            client.close();
            await Future.delayed(retryDelay);
            continue;
          }

          StringBuffer buffer = StringBuffer();

          await for (final chunk
              in response.stream.transform(utf8.decoder)) {
            if (cancelled) break;

            buffer.write(chunk);
            final raw = buffer.toString();
            final blocks = raw.split('\n\n');

            for (int i = 0; i < blocks.length - 1; i++) {
              _processSSEBlock(blocks[i], controller);
            }
            buffer = StringBuffer(blocks.last);
          }
        } catch (e) {
          if (!cancelled) onError?.call(e);
        } finally {
          client?.close();
        }

        if (!cancelled) await Future.delayed(retryDelay);
      }

      if (!controller.isClosed) controller.close();
      onDone?.call();
    }

    connect();

    final subscription = controller.stream.listen(
      onData,
      onError: onError,
    );

    return _CancellableSubscription(subscription, onCancel: () {
      cancelled = true;
    });
  }

  /// مثل [listen] بالظبط لكن بياخد URL كامل بدل path —
  /// بيُستخدم لما محتاجين نضيف query params زي limitToLast
  static StreamSubscription<dynamic> _listenRaw(
    String fullUrl, {
    required void Function(dynamic data) onData,
    void Function(Object error)? onError,
    void Function()? onDone,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    final controller = StreamController<dynamic>.broadcast();
    bool cancelled = false;

    Future<void> connect() async {
      while (!cancelled) {
        http.Client? client;
        try {
          client = http.Client();
          final request = http.Request('GET', Uri.parse(fullUrl));
          request.headers['Accept'] = 'text/event-stream';
          request.headers['Cache-Control'] = 'no-cache';

          final response = await client.send(request);

          if (response.statusCode != 200) {
            client.close();
            await Future.delayed(retryDelay);
            continue;
          }

          StringBuffer buffer = StringBuffer();

          await for (final chunk in response.stream.transform(utf8.decoder)) {
            if (cancelled) break;
            buffer.write(chunk);
            final raw = buffer.toString();
            final blocks = raw.split('\n\n');
            for (int i = 0; i < blocks.length - 1; i++) {
              _processSSEBlock(blocks[i], controller);
            }
            buffer = StringBuffer(blocks.last);
          }
        } catch (e) {
          if (!cancelled) onError?.call(e);
        } finally {
          client?.close();
        }
        if (!cancelled) await Future.delayed(retryDelay);
      }
      if (!controller.isClosed) controller.close();
      onDone?.call();
    }

    connect();

    final subscription = controller.stream.listen(onData, onError: onError);
    return _CancellableSubscription(subscription, onCancel: () {
      cancelled = true;
    });
  }

  static void _processSSEBlock(
      String block, StreamController<dynamic> controller) {
    String? eventType;
    String? dataLine;

    for (final line in block.split('\n')) {
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        dataLine = line.substring(5).trim();
      }
    }

    if ((eventType == 'put' || eventType == 'patch') &&
        dataLine != null) {
      try {
        final parsed = jsonDecode(dataLine);
        if (!controller.isClosed) {
          controller.add({
            'event': eventType,
            'path': parsed['path'], 
            'data': parsed['data']
          });
        }
      } catch (_) {}
    }
  }

  static Future<Map<String, dynamic>?> getSubscriptionWithTimestamp(String shopId) async {
    try {
      final subFuture = http
          .get(Uri.parse(_url(shopSubscriptionPath(shopId))))
          .timeout(const Duration(seconds: 10));

      final timeFuture = http
          .get(Uri.parse('$_baseUrl/.json?shallow=true&auth=$_secret'))
          .timeout(const Duration(seconds: 10));

      final results = await Future.wait([subFuture, timeFuture]);

      final subResponse = results[0];
      final timeResponse = results[1];

      if (subResponse.statusCode != 200) return null;

      final subData = jsonDecode(subResponse.body);
      if (subData == null || subData is! Map) return null;

      final result = Map<String, dynamic>.from(subData);

      final dateHeader = timeResponse.headers['date'];
      if (dateHeader != null) {
        try {
          final serverTime = DateTime.parse(dateHeader);
          result['_server_time_ms'] =
              serverTime.millisecondsSinceEpoch;
        } catch (_) {
          result['_server_time_ms'] =
              DateTime.now().millisecondsSinceEpoch;
        }
      } else {
        result['_server_time_ms'] =
            DateTime.now().millisecondsSinceEpoch;
      }

      return result;
    } catch (e) {
      print('Firebase getSubscriptionWithTimestamp error: $e');
      return null;
    }
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
    } catch (_) {
      return {};
    }
  }

  static StreamSubscription<dynamic> listenToOpenShifts(
    String shopId, {
    String? senderId,
    required void Function(Map<String, dynamic> openShifts) onData,
    void Function(Object error)? onError,
    Duration retryDelay = const Duration(seconds: 2),
  }) {
    return listen(
      openShiftsPath(shopId),
      onData: (payload) {
        if (payload == null || payload is! Map) return;
        final raw = payload['data'];
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          if (senderId != null && data['_sender_id'] == senderId) return;
          data.remove('_sender_id');
          onData(data);
        } else {
          onData({});
        }
      },
      onError: onError,
      retryDelay: retryDelay,
    );
  }
}

class _CancellableSubscription<T> implements StreamSubscription<T> {
  final StreamSubscription<T> _inner;
  final void Function() onCancel;

  _CancellableSubscription(this._inner, {required this.onCancel});

  @override
  Future<void> cancel() {
    onCancel();
    return _inner.cancel();
  }

  @override
  bool get isPaused => _inner.isPaused;
  @override
  void pause([Future<void>? resumeSignal]) =>
      _inner.pause(resumeSignal);
  @override
  void resume() => _inner.resume();
  @override
  void onData(void Function(T data)? handleData) =>
      _inner.onData(handleData);
  @override
  void onError(Function? handleError) =>
      _inner.onError(handleError);
  @override
  void onDone(void Function()? handleDone) =>
      _inner.onDone(handleDone);
  @override
  Future<E> asFuture<E>([E? futureValue]) =>
      _inner.asFuture(futureValue);
}
