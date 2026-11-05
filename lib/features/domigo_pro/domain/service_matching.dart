import 'dart:math' as math;

/// Pure domain logic for the experimental Domigo Pro marketplace.
/// This file performs no network calls and does not expose customer addresses.
class GeoPoint {
  const GeoPoint(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);

  final double latitude;
  final double longitude;
}

double distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0088;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final haversine = math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm *
      math.asin(math.sqrt((haversine as num).toDouble().clamp(0.0, 1.0)));
}

sealed class ServiceArea {
  const ServiceArea();

  bool includes(JobLocation location);
}

/// A circular travel zone; the radius represents geographic distance,
/// not real driving distance or a guaranteed arrival time.
class RadiusArea extends ServiceArea {
  const RadiusArea({required this.center, required this.radiusKm})
      : assert(radiusKm > 0 && radiusKm <= 200);

  final GeoPoint center;
  final double radiusKm;

  @override
  bool includes(JobLocation location) {
    final point = location.approximatePoint;
    return point != null && distanceKm(center, point) <= radiusKm;
  }
}

/// A list of postal codes; avoids false positives from similar city names.
class PostalCodeArea extends ServiceArea {
  PostalCodeArea({required String countryCode, required Iterable<String> codes})
      : countryCode = countryCode.trim().toUpperCase(),
        codes = Set.unmodifiable(codes.map((code) => code.trim().toUpperCase())
            .where((code) => code.isNotEmpty));

  final String countryCode;
  final Set<String> codes;

  @override
  bool includes(JobLocation location) =>
      countryCode == location.countryCode.trim().toUpperCase() &&
      codes.contains(location.postalCode.trim().toUpperCase());
}

/// Location data is used for private matching only. Never render exact
/// customer coordinates or their street address in public search cards.
class JobLocation {
  const JobLocation({
    required this.countryCode,
    required this.postalCode,
    this.approximatePoint,
  });

  final String countryCode;
  final String postalCode;
  final GeoPoint? approximatePoint;
}

enum ProVerification { pending, verified, rejected, suspended }

class ProProfile {
  ProProfile({
    required this.id,
    required this.displayName,
    required Iterable<String> specialties,
    required Iterable<ServiceArea> serviceAreas,
    required this.verification,
    this.acceptingJobs = true,
  })  : specialties = Set.unmodifiable(specialties),
        serviceAreas = List.unmodifiable(serviceAreas);

  final String id;
  final String displayName;
  final Set<String> specialties;
  final List<ServiceArea> serviceAreas;
  final ProVerification verification;
  final bool acceptingJobs;
}

class RepairRequest {
  const RepairRequest({
    required this.id,
    required this.specialty,
    required this.location,
  });

  final String id;
  final String specialty;
  final JobLocation location;
}

/// Candidates are suggestions, not bookings or verified availability.
/// When [requireVerified] is true, only already verified professionals match.
List<ProProfile> matchProfessionals(
  RepairRequest request,
  Iterable<ProProfile> professionals, {
  bool requireVerified = true,
}) {
  final seen = <String>{};
  return professionals.where((pro) {
    if (pro.id.isEmpty || !pro.acceptingJobs ||
        (requireVerified && pro.verification != ProVerification.verified) ||
        !pro.specialties.contains(request.specialty) ||
        !pro.serviceAreas.any((area) => area.includes(request.location))) {
      return false;
    }
    return seen.add(pro.id);
  }).toList(growable: false);
}
