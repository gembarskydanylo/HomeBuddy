import 'package:flutter_test/flutter_test.dart';
import 'package:home_buddy/features/domigo_pro/domain/service_matching.dart';

void main() {
  final brussels = GeoPoint(50.8503, 4.3517);
  final vilvoorde = GeoPoint(50.9281, 4.4294);
  final antwerp = GeoPoint(51.2194, 4.4025);

  ProProfile professional({
    String id = 'pro-1',
    List<String> specialties = const ['plumber'],
    List<ServiceArea>? areas,
    ProVerification verification = ProVerification.verified,
    bool acceptingJobs = true,
  }) =>
      ProProfile(
        id: id,
        displayName: 'Test professional',
        specialties: specialties,
        serviceAreas: areas ?? [RadiusArea(center: brussels, radiusKm: 20)],
        verification: verification,
        acceptingJobs: acceptingJobs,
      );

  RepairRequest job({String specialty = 'plumber', GeoPoint? point}) =>
      RepairRequest(
        id: 'job-1',
        specialty: specialty,
        location: JobLocation(
          countryCode: 'BE',
          postalCode: '1800',
          approximatePoint: point ?? vilvoorde,
        ),
      );

  test('matches a professional inside a radius', () {
    expect(matchProfessionals(job(), [professional()]), hasLength(1));
  });

  test('does not match outside radius', () {
    expect(matchProfessionals(
      job(point: antwerp),
      [professional(areas: [RadiusArea(center: brussels, radiusKm: 10)])],
    ), isEmpty);
  });

  test('checks specialty before geographic area', () {
    expect(matchProfessionals(job(specialty: 'electrician'), [professional()]),
        isEmpty);
  });

  test('postal code area matches selected country and code', () {
    final pro = professional(areas: [
      PostalCodeArea(countryCode: 'BE', codes: ['1800', '1850'])
    ]);
    expect(matchProfessionals(job(point: antwerp), [pro]), hasLength(1));
    final otherCountry = RepairRequest(
      id: 'job-2', specialty: 'plumber',
      location: const JobLocation(countryCode: 'NL', postalCode: '1800'),
    );
    expect(matchProfessionals(otherCountry, [pro]), isEmpty);
  });

  test('multiple areas use union, duplicate profiles appear once', () {
    final pro = professional(areas: [
      RadiusArea(center: antwerp, radiusKm: 2),
      PostalCodeArea(countryCode: 'BE', codes: ['1800']),
    ]);
    expect(matchProfessionals(job(), [pro, pro]), hasLength(1));
  });

  test('pending, rejected, suspended or inactive providers stay hidden', () {
    final pros = [
      professional(id: 'pending', verification: ProVerification.pending),
      professional(id: 'rejected', verification: ProVerification.rejected),
      professional(id: 'suspended', verification: ProVerification.suspended),
      professional(id: 'inactive', acceptingJobs: false),
    ];
    expect(matchProfessionals(job(), pros), isEmpty);
    expect(matchProfessionals(job(), pros, requireVerified: false),
        hasLength(1));
  });

  test('radius distance is zero at identical points', () {
    expect(distanceKm(brussels, brussels), closeTo(0, 0.0001));
  });

  test('coordinates missing do not match a radius-only area', () {
    const noCoordinates = RepairRequest(
      id: 'job-3', specialty: 'plumber',
      location: JobLocation(countryCode: 'BE', postalCode: '1800'),
    );
    expect(matchProfessionals(noCoordinates, [professional()]), isEmpty);
  });
}
