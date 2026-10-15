// Test kanal push tiruan.
//
// Menguji janji-janji penting modul tanpa Firebase:
//   * token awal benar-benar dikirim ke backend lewat callback `onToken`,
//   * `onTokenRefresh` (diwakili `rotateToken`) mengirim ulang token BARU,
//   * ketiga app state tersalurkan lewat jalur yang sama dengan FCM sungguhan.

import 'package:flutter_test/flutter_test.dart';
import 'package:week6_campus_notify/messaging/push_service.dart';
import 'package:week6_campus_notify/messaging/simulated_push_service.dart';

void main() {
  group('SimulatedPushService', () {
    test('bootstrap mengirim token ke backend dan langganan topik', () async {
      final service = SimulatedPushService();
      final tokens = <String>[];

      final bootstrap = await service.start(
        onToken: (token) async => tokens.add(token),
      );

      expect(bootstrap.permissionGranted, isTrue);
      expect(bootstrap.topicSubscribed, isTrue);
      expect(tokens, hasLength(1));
      expect(tokens.single, contains(':APA91b'));
      expect(tokens.single.length, greaterThan(100));
      expect(service.isReal, isFalse);

      await service.dispose();
    });

    test('rotateToken meniru onTokenRefresh dan mengirim token BARU', () async {
      final service = SimulatedPushService();
      final tokens = <String>[];
      await service.start(onToken: (token) async => tokens.add(token));
      final sebelum = tokens.single;

      await service.rotateToken();

      expect(tokens, hasLength(2));
      expect(tokens.last, isNot(sebelum));
      await service.dispose();
    });

    test('unsubscribe dan subscribe mengubah status topik', () async {
      final service = SimulatedPushService();
      await service.start(onToken: (token) async {});
      expect(service.topicSubscribed.value, isTrue);

      await service.unsubscribe(PushService.campusTopic);
      expect(service.topicSubscribed.value, isFalse);

      await service.subscribe(PushService.campusTopic);
      expect(service.topicSubscribed.value, isTrue);

      await service.dispose();
    });

    test('emit menyalurkan tiga app state ke rute yang sama', () async {
      final service = SimulatedPushService();
      await service.start(onToken: (token) async {});

      final events = <PushEvent>[];
      final subscription = service.events.listen(events.add);

      await service.emit(kind: PushEventKind.foreground);
      await service.emit(kind: PushEventKind.opened);
      await service.emit(kind: PushEventKind.initial);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(events.map((event) => event.kind), [
        PushEventKind.foreground,
        PushEventKind.opened,
        PushEventKind.initial,
      ]);
      expect(events.every((event) => event.message.route == '/pengumuman/3'), isTrue);
      expect(events.map((event) => event.label), [
        'foreground',
        'background',
        'terminated',
      ]);

      await subscription.cancel();
      await service.dispose();
    });

    test('kanal tiruan tidak menyediakan simulator kedua', () async {
      final service = SimulatedPushService();
      // `simulator` mengembalikan dirinya sendiri supaya panel simulator di UI
      // bisa memanggil `emit` tanpa tahu implementasi konkretnya.
      expect(identical(service.simulator, service), isTrue);
      await service.dispose();
    });
  });
}
