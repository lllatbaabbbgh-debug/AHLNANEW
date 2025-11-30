import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class OffersRepository {
  static const table = 'offers';
  static const fallbackTable = 'app_settings';
  SupabaseClient? get _c => SupabaseManager.client;
  SupabaseClient? get _svc => SupabaseManager.serviceClient ?? _c;

  Future<String?> getLink() async {
    final c = _c ?? _svc;
    if (c == null) return null;
    try {
      final res = await c.from(table).select().eq('id', 'current').maybeSingle();
      if (res == null) return null;
      final m = Map<String, dynamic>.from(res);
      return m['url']?.toString();
    } catch (e) {
      try {
        final fb = await c.from(fallbackTable).select().maybeSingle();
        if (fb == null) return null;
        final fm = Map<String, dynamic>.from(fb);
        return fm['offer_image_url']?.toString();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> setLink(String url) async {
    final c = _svc ?? _c;
    if (c == null) return;
    try {
      await c.from(table).upsert({
        'id': 'current',
        'url': url,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      try {
        await c.from(fallbackTable).upsert({
          'id': 'offers',
          'offer_image_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
      } catch (_) {}
    }
  }

  Future<void> deleteLink() async {
    final c = _svc ?? _c;
    if (c == null) return;
    try {
      await c.from(table).delete().eq('id', 'current');
    } catch (e) {
      try {
        await c.from(fallbackTable).update({'offer_image_url': null}).eq('id', 'offers');
      } catch (_) {}
    }
  }

  Stream<String?> streamLink() {
    final c = _c ?? _svc;
    if (c == null) return const Stream.empty();
    final offersStream = c
        .from(table)
        .stream(primaryKey: ['id'])
        .eq('id', 'current')
        .map((rows) {
          if (rows.isEmpty) return null;
          final m = Map<String, dynamic>.from(rows.first);
          return m['url']?.toString();
        });
    final fbStream = c
        .from(fallbackTable)
        .stream(primaryKey: ['id'])
        .eq('id', 'offers')
        .map((rows) {
          if (rows.isEmpty) return null;
          final m = Map<String, dynamic>.from(rows.first);
          return m['offer_image_url']?.toString();
        });
    return Stream<String?>.multi((controller) {
      final s1 = offersStream.listen(controller.add, onError: controller.addError);
      final s2 = fbStream.listen(controller.add, onError: controller.addError);
      controller.onCancel = () {
        s1.cancel();
        s2.cancel();
      };
    }, isBroadcast: true);
  }

  Stream<String?> liveLink() {
    return Stream<String?>.multi((controller) async {
      final initial = await getLink();
      controller.add(initial);
      // لا تقم بالاستماع للتحديثات المستمرة لتجنب وميض الواجهة
      // إذا أردت تحديثات لاحقاً، يمكن تفعيل هذا لاحقاً
      // final sub = streamLink().listen(controller.add, onError: controller.addError);
      // controller.onCancel = () => sub.cancel();
    }, isBroadcast: true);
  }
}
