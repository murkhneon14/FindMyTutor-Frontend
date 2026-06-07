import 'package:flutter/material.dart';
import '../services/location_service.dart';

/// A banner widget that checks for location drift on mount and shows
/// a warning if the user has moved significantly from their saved location.
///
/// Usage — drop this anywhere near the top of a screen's body:
///   LocationDriftBanner(role: 'teacher', storedCoordinates: coords)
class LocationDriftBanner extends StatefulWidget {
  /// "teacher" or "student"
  final String role;

  /// GeoJSON coordinates from profile: [longitude, latitude]
  final List<dynamic> storedCoordinates;

  const LocationDriftBanner({
    super.key,
    required this.role,
    required this.storedCoordinates,
  });

  @override
  State<LocationDriftBanner> createState() => _LocationDriftBannerState();
}

class _LocationDriftBannerState extends State<LocationDriftBanner>
    with SingleTickerProviderStateMixin {
  double? _driftKm;
  bool _loading = true;
  bool _dismissed = false;
  bool _updating = false;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _checkDrift();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkDrift() async {
    final drift = await LocationService.checkLocationDrift(widget.storedCoordinates);
    if (mounted) {
      setState(() {
        _driftKm = drift;
        _loading = false;
      });
      if (drift != null) {
        _animController.forward();
      }
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _updating = true);
    final success = await LocationService.updateProfileLocation(widget.role);
    if (mounted) {
      if (success) {
        _animController.reverse().then((_) {
          if (mounted) setState(() => _dismissed = true);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Location updated successfully!'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to update location. Try again.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _dismiss() {
    _animController.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _driftKm == null || _dismissed) {
      return const SizedBox.shrink();
    }

    final distanceText = _driftKm! >= 1
        ? '${_driftKm!.toStringAsFixed(1)} km'
        : '${(_driftKm! * 1000).toStringAsFixed(0)} m';

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You\'ve moved!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Your current location is $distanceText away from your saved profile location. Update it so students/teachers can find you accurately.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF78350F),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Update button
                        Expanded(
                          child: GestureDetector(
                            onTap: _updating ? null : _updateLocation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: _updating
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Update Location',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Dismiss button
                        GestureDetector(
                          onTap: _dismiss,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B), width: 1),
                            ),
                            child: const Text(
                              'Later',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
