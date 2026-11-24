import 'dart:async';

import 'package:calm_mobil/models/booking.dart';
import 'package:calm_mobil/models/booking_form.dart';
import 'package:calm_mobil/models/client_action.dart';
import 'package:calm_mobil/models/order.dart';
import 'package:calm_mobil/models/profile_form.dart';
import 'package:calm_mobil/models/profile_update.dart';
import 'package:calm_mobil/models/service_item.dart';
import 'package:calm_mobil/models/service_selection.dart';
import 'package:calm_mobil/services/api_client.dart';
import 'package:calm_mobil/services/api_client_data.dart';
import 'package:calm_mobil/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'api_fakes.dart';

// Sunday, November 22 2026, 17:40 on Cancún's wall clock.
final now = DateTime(2026, 11, 22, 17, 40);

const selection = ServiceSelection(
  services: [
    ServiceItem(id: '3', title: 'Dobladillo de pantalón', priceMxn: 100),
    ServiceItem(id: '7', title: 'Cambio de cierre', priceMxn: 130),
  ],
  isUrgent: true,
);

const contact = BookingContact(name: 'María López', phoneDigits: '9981234567', nip: '1357');

BookingRequest request({BookingContact? contact}) {
  return BookingRequest(contact: contact, selection: selection, date: '2026-11-26', time: '11:00');
}

void main() {
  final installed = <String>[];
  var signedIn = true;
  var signOuts = 0;

  ApiClientData dataOver(FakeApi api, {Future<void> Function(String token)? install, Future<void> Function()? signOut}) {
    return ApiClientData.using(
      api: api.client(timeout: const Duration(milliseconds: 200)),
      isSignedIn: () => signedIn,
      installSession: install ?? (token) async => installed.add(token),
      signOut: signOut ?? () async => signOuts++,
      now: () => now,
    );
  }

  setUp(() {
    installed.clear();
    signedIn = true;
    signOuts = 0;
  });

  group('session', () {
    test('isSignedIn asks Supabase Auth, not the API', () {
      final api = FakeApi((_) => json({}));
      final data = dataOver(api);

      expect(data.isSignedIn, isTrue);
      signedIn = false;
      expect(data.isSignedIn, isFalse);
      expect(api.sent, isEmpty);
    });

    test('signOut ends the Supabase session and swallows a failure to reach the server', () async {
      final api = FakeApi((_) => json({}));

      await dataOver(api).signOut();
      await dataOver(api, signOut: () async => throw Exception('offline')).signOut();

      expect(signOuts, 1);
      expect(api.sent, isEmpty);
    });
  });

  group('catalog', () {
    test('reads GET /client/services, with "extra" as the urgent surcharge', () async {
      final api = FakeApi((_) => json([
            {'id': 3, 'name': 'Dobladillo de pantalón', 'category': 'pants', 'basePriceMxn': 100},
            {'id': 5, 'name': 'Vestido Personalizado', 'category': 'dress', 'basePriceMxn': null},
            {'id': 9, 'name': 'Prenda urgente', 'category': 'extra', 'basePriceMxn': 80},
          ]));

      final catalog = await dataOver(api).catalog();

      expect(api.sent.single.method, 'GET');
      expect(api.sent.single.path, '/api/client/services');
      expect([for (final s in catalog.services) (s.id, s.title, s.priceMxn)], [
        ('3', 'Dobladillo de pantalón', 100),
        ('5', 'Vestido Personalizado', null),
      ]);
      expect(catalog.urgentSurchargeMxn, 80);
    });

    test('fails to load when the API fails', () async {
      final api = FakeApi((_) => failure(500, 'internal'));

      await expectLater(dataOver(api).catalog(), throwsA(isA<ApiException>()));
    });
  });

  group('agenda', () {
    test('reads GET /client/booking-calendar into this month and the next', () async {
      final api = FakeApi((_) => json({
            'today': '2026-11-22',
            'now': '17:40',
            'weekly': [
              for (final weekday in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'])
                {'weekday': weekday, 'opensAt': '10:00:00', 'closesAt': '18:00:00'},
              {'weekday': 'saturday', 'opensAt': '10:00', 'closesAt': '14:00'},
              {'weekday': 'sunday', 'opensAt': null, 'closesAt': null},
            ],
            'blocked': ['2026-11-25', '2026-12-01'],
            'booked': [
              {'date': '2026-11-24', 'time': '12:00:00'},
              {'date': '2026-12-02', 'time': '10:30'},
            ],
          }));

      final months = (await dataOver(api).agenda()).months;

      expect(api.sent.single.path, '/api/client/booking-calendar');
      final [november, december] = months;
      expect(november.today, 22);
      expect(november.freeSlotsFor(23), hasLength(16));
      expect(november.freeSlotsFor(28).last, '13:30');
      expect(november.freeSlotsFor(29), isEmpty);
      expect(november.freeSlotsFor(25), isEmpty);
      expect(november.freeSlotsFor(24), isNot(contains('12:00')));
      expect(december.month, 12);
      expect(december.freeSlotsFor(1), isEmpty);
      expect(december.freeSlotsFor(2), isNot(contains('10:30')));
    });
  });

  group('profile', () {
    test('reads GET /client/profile with her token', () async {
      final api = FakeApi((_) => json({'name': 'María López', 'phone': '9981234567'}));

      final profile = await dataOver(api).profile();

      expect(api.sent.single.path, '/api/client/profile');
      expect(api.sent.single.headers['Authorization'], 'Bearer access-1');
      expect(profile.fullName, 'María López');
      expect(profile.phone, '998 123 4567');
    });

    test('fails to load when her session is gone', () async {
      final api = FakeApi((_) => failure(401, 'signed_out'));

      await expectLater(dataOver(api).profile(), throwsA(isA<ApiException>()));
    });
  });

  group('orders', () {
    Map<String, Object?> appointment({
      String ticket = '4821',
      String date = '2026-11-26',
      String time = '11:00',
      bool hasOrder = false,
    }) {
      return {
        'ticket': ticket,
        'date': date,
        'time': time,
        'preliminaryTotalMxn': 230,
        'services': ['Dobladillo de pantalón', 'Cambio de cierre'],
        'hasOrder': hasOrder,
      };
    }

    test('reads GET /client/orders with Pedidos\' order and wording', () async {
      final api = FakeApi((_) => json({
            'orders': [
              {'ticket': '6540', 'work': 'Dobladillo', 'status': 'delivered', 'finalPriceMxn': 100, 'deliveryDate': '2026-11-13'},
              {'ticket': '7720', 'work': 'Cambio de cierre de chamarra', 'status': 'ready', 'finalPriceMxn': 150, 'deliveryDate': '2026-11-17'},
              {'ticket': '1111', 'work': 'Cancelado', 'status': 'cancelled', 'finalPriceMxn': 10, 'deliveryDate': '2026-11-17'},
            ],
            'appointments': [appointment()],
          }));

      final orders = await dataOver(api).orders();

      expect(api.sent.single.path, '/api/client/orders');
      expect([for (final o in orders) o.ticket], ['7720', '4821', '6540']);
      final [ready, booked, delivered] = orders;
      expect(ready.status, OrderStatus.ready);
      expect(ready.formattedAmount, r'$150 MXN');
      expect(ready.scheduledDay, 'martes 17 de noviembre');
      expect(booked.status, OrderStatus.appointment);
      expect(booked.work, 'Dobladillo de pantalón, Cambio de cierre');
      expect(booked.amountMxn, 230);
      expect(booked.appointmentOn, 'jueves 26 a las 11:00');
      expect(booked.scheduledTime, '11:00');
      expect(booked.isCancellable, isTrue);
      expect(delivered.statusLine, 'Entregado el 13 de noviembre');
    });

    test('leaves out appointments that became orders or have passed, and keeps the 24 h rule', () async {
      final api = FakeApi((_) => json({
            'orders': [],
            'appointments': [
              appointment(ticket: '1', hasOrder: true),
              appointment(ticket: '2', date: '2026-11-21'),
              appointment(ticket: '3', date: '2026-11-23', time: '10:00:00'),
            ],
          }));

      final orders = await dataOver(api).orders();

      expect([for (final o in orders) o.ticket], ['3']);
      expect(orders.single.scheduledTime, '10:00');
      expect(orders.single.isCancellable, isFalse);
    });

    test('fails to load when her session is gone', () async {
      final api = FakeApi((_) => failure(401, 'signed_out'));

      await expectLater(dataOver(api).orders(), throwsA(isA<ApiException>()));
    });
  });

  group('book', () {
    final confirmed = {
      'ticket': '4821',
      'client': {'id': 1, 'name': 'María López', 'phone': '9981234567'},
      'appointment': {'date': '2026-11-26', 'time': '11:00', 'totalMxn': 310},
    };

    test('posts her selection to /client/appointments with her session and keeps it', () async {
      final api = FakeApi((_) => json(confirmed, 201));

      final outcome = await dataOver(api).book(request());

      expect(outcome, isA<BookingConfirmed>().having((o) => o.ticket, 'ticket', '4821'));
      expect(api.sent.single.method, 'POST');
      expect(api.sent.single.path, '/api/client/appointments');
      expect(api.sent.single.body, {'serviceIds': [3, 7], 'urgent': true, 'date': '2026-11-26', 'time': '11:00'});
      expect(installed, isEmpty);
    });

    test('sends her contact without a session and installs the session that comes back', () async {
      final api = FakeApi((_) => json({...confirmed, 'refreshToken': 'token-2'}, 201));

      final outcome = await dataOver(api).book(request(contact: contact));

      expect(outcome, isA<BookingConfirmed>());
      expect(api.sent.single.body, {
        'serviceIds': [3, 7],
        'urgent': true,
        'date': '2026-11-26',
        'time': '11:00',
        'contact': {'name': 'María López', 'phone': '9981234567', 'nip': '1357'},
      });
      expect(installed, ['token-2']);
    });

    test('says unavailable when the new session cannot be installed', () async {
      final api = FakeApi((_) => json({...confirmed, 'refreshToken': 'token-2'}, 201));

      final outcome = await dataOver(api, install: (_) async => throw Exception('storage')).book(request(contact: contact));

      expect(outcome, isA<BookingRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable));
    });

    test('maps every refusal to the screen\'s outcome', () async {
      final cases = <(int, String, Matcher)>[
        (401, 'signed_out', isA<BookingSignedOut>()),
        (401, 'rejected', isA<BookingRefused>()
            .having((o) => o.message, 'message', AppConstants.bookingWrongPair)
            .having((o) => o.field, 'field', BookingField.nip)),
        (429, 'throttled', isA<BookingRefused>().having((o) => o.message, 'message', AppConstants.signInThrottled)),
        (409, 'slot_taken', isA<BookingSlotTaken>()),
        (409, 'phone_without_nip', isA<BookingRefused>()
            .having((o) => o.message, 'message', AppConstants.bookingPhoneWithoutNip)
            .having((o) => o.field, 'field', BookingField.phone)),
        (409, 'service_unavailable', isA<BookingRefused>()
            .having((o) => o.message, 'message', AppConstants.bookingServiceUnavailable)
            .having((o) => o.field, 'field', isNull)),
        (400, 'date', isA<BookingRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable)),
        (500, 'internal', isA<BookingRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable)),
      ];
      for (final (status, code, matcher) in cases) {
        final outcome = await dataOver(FakeApi((_) => failure(status, code))).book(request(contact: contact));

        expect(outcome, matcher, reason: '$status $code');
      }
      expect(installed, isEmpty);
    });

    test('says unavailable without network, in time or with a malformed answer', () async {
      for (final respond in <FutureOr<http.Response> Function(SentRequest)>[
        (_) => throw http.ClientException('offline'),
        (_) => Completer<http.Response>().future,
        (_) => json({'ticket': 7}, 201),
      ]) {
        final outcome = await dataOver(FakeApi(respond)).book(request());

        expect(outcome, isA<BookingRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable));
      }
    });
  });

  group('cancelAppointment', () {
    test('deletes /client/appointments/:ticket', () async {
      final api = FakeApi((_) => noContent());

      final outcome = await dataOver(api).cancelAppointment('4821');

      expect(outcome, isA<ActionDone>());
      expect(api.sent.single.method, 'DELETE');
      expect(api.sent.single.path, '/api/client/appointments/4821');
    });

    test('words the 24 h refusal and any failure', () async {
      Future<ClientActionOutcome> answer(FutureOr<http.Response> Function(SentRequest) respond) {
        return dataOver(FakeApi(respond)).cancelAppointment('4821');
      }

      expect(await answer((_) => failure(409, 'appointment_not_cancellable')),
          isA<ActionRefused>().having((o) => o.message, 'message', AppConstants.cancelRefused));
      for (final respond in <FutureOr<http.Response> Function(SentRequest)>[
        (_) => failure(401, 'signed_out'),
        (_) => failure(500, 'internal'),
        (_) => throw http.ClientException('offline'),
      ]) {
        expect(await answer(respond),
            isA<ActionRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable));
      }
    });
  });

  group('markOnMyWay', () {
    test('posts /client/orders/:ticket/on-my-way', () async {
      final api = FakeApi((_) => noContent());

      final outcome = await dataOver(api).markOnMyWay('7720');

      expect(outcome, isA<ActionDone>());
      expect(api.sent.single.method, 'POST');
      expect(api.sent.single.path, '/api/client/orders/7720/on-my-way');
    });

    test('words the not-ready refusal and any failure', () async {
      Future<ClientActionOutcome> answer(FutureOr<http.Response> Function(SentRequest) respond) {
        return dataOver(FakeApi(respond)).markOnMyWay('7720');
      }

      expect(await answer((_) => failure(409, 'order_not_ready')),
          isA<ActionRefused>().having((o) => o.message, 'message', AppConstants.onTheWayRefused));
      for (final respond in <FutureOr<http.Response> Function(SentRequest)>[
        (_) => failure(401, 'signed_out'),
        (_) => failure(503, 'down'),
        (_) => throw http.ClientException('offline'),
      ]) {
        expect(await answer(respond),
            isA<ActionRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable));
      }
    });
  });

  group('saveProfile', () {
    test('puts only the phone when she keeps her NIP', () async {
      final api = FakeApi((_) => json({'client': {'id': 1, 'name': 'María López', 'phone': '9987654321'}}));

      final outcome = await dataOver(api).saveProfile(const ProfileChange(phoneDigits: '9987654321'));

      expect(api.sent.single.method, 'PUT');
      expect(api.sent.single.path, '/api/client/profile');
      expect(api.sent.single.body, {'phone': '9987654321'});
      expect(outcome, isA<ProfileSaved>().having((o) => o.profile.phone, 'phone', '998 765 4321'));
    });

    test('puts both NIPs when she changes it', () async {
      final api = FakeApi((_) => json({'client': {'id': 1, 'name': 'María López', 'phone': '9981234567'}}));

      await dataOver(api).saveProfile(
        const ProfileChange(phoneDigits: '9981234567', currentNip: '1357', newNip: '2468'),
      );

      expect(api.sent.single.body, {'phone': '9981234567', 'currentNip': '1357', 'newNip': '2468'});
    });

    test('maps every refusal to Perfil\'s field and wording', () async {
      final cases = <(int, String, Matcher)>[
        (400, 'phone', isA<ProfileRefused>()
            .having((o) => o.message, 'message', 'Mensaje phone')
            .having((o) => o.field, 'field', ProfileField.phone)),
        (409, 'phone_taken', isA<ProfileRefused>()
            .having((o) => o.message, 'message', 'Mensaje phone_taken')
            .having((o) => o.field, 'field', ProfileField.phone)),
        (401, 'current_nip', isA<ProfileRefused>()
            .having((o) => o.message, 'message', 'Mensaje current_nip')
            .having((o) => o.field, 'field', ProfileField.currentNip)),
        (400, 'new_nip', isA<ProfileRefused>()
            .having((o) => o.message, 'message', 'Mensaje new_nip')
            .having((o) => o.field, 'field', ProfileField.newNip)),
        (401, 'signed_out', isA<ProfileRefused>()
            .having((o) => o.message, 'message', 'Mensaje signed_out')
            .having((o) => o.field, 'field', isNull)),
        (429, 'throttled', isA<ProfileRefused>()
            .having((o) => o.message, 'message', AppConstants.signInThrottled)
            .having((o) => o.field, 'field', isNull)),
        (500, 'internal', isA<ProfileRefused>()
            .having((o) => o.message, 'message', AppConstants.signInUnavailable)
            .having((o) => o.field, 'field', isNull)),
      ];
      for (final (status, code, matcher) in cases) {
        final api = FakeApi((_) => failure(status, code, 'Mensaje $code'));

        final outcome = await dataOver(api).saveProfile(const ProfileChange(phoneDigits: '9981234567'));

        expect(outcome, matcher, reason: '$status $code');
      }
    });

    test('says unavailable without network or with a malformed answer', () async {
      for (final respond in <FutureOr<http.Response> Function(SentRequest)>[
        (_) => throw http.ClientException('offline'),
        (_) => json({'client': null}),
        (_) => failure(400, 'phone', ''),
      ]) {
        final outcome = await dataOver(FakeApi(respond)).saveProfile(const ProfileChange(phoneDigits: '9981234567'));

        expect(outcome, isA<ProfileRefused>().having((o) => o.message, 'message', isNotEmpty));
      }
      final outcome = await dataOver(FakeApi((_) => throw http.ClientException('offline')))
          .saveProfile(const ProfileChange(phoneDigits: '9981234567'));
      expect(outcome, isA<ProfileRefused>().having((o) => o.message, 'message', AppConstants.signInUnavailable));
    });
  });
}
