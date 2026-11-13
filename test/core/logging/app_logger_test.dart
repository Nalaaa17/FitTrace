import 'package:fit_trace/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger.scrub', () {
    test('redacts Garmin session cookies and auth headers', () {
      const raw =
          'Cookie: GARMIN-SSO=abc123xyz; SESSION=s3cr3tVal; SESSIONID=sid9876; '
          'CASTGC=TGT-999-xyz; connect-csrf-token=csrfSecret '
          'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig '
          '{"access_token":"tokSecret123","refresh_token":"refSecret456"} '
          'https://connect.garmin.com/modern?ticket=ST-998877-abc';

      final scrubbed = AppLogger.scrub(raw);

      expect(scrubbed, isNot(contains('abc123xyz')));
      expect(scrubbed, isNot(contains('s3cr3tVal')));
      expect(scrubbed, isNot(contains('sid9876')));
      expect(scrubbed, isNot(contains('TGT-999-xyz')));
      expect(scrubbed, isNot(contains('csrfSecret')));
      expect(scrubbed, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
      expect(scrubbed, isNot(contains('tokSecret123')));
      expect(scrubbed, isNot(contains('refSecret456')));
      expect(scrubbed, isNot(contains('ST-998877-abc')));
      expect(scrubbed, contains('[REDACTED]'));
    });

    test('preserves non-sensitive activity metadata', () {
      const raw = 'Synced activity 12345 (5.02 km, movingTime=1520s)';
      expect(AppLogger.scrub(raw), raw);
    });
  });
}

