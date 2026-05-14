import 'package:flutter/material.dart';
import '../models/public_event.dart';
import '../models/ar_frame.dart';
import '../services/event_service.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService = EventService();

  List<PublicEvent> _events = [];
  PublicEvent? _currentEvent;
  List<ArFrame> _frames = [];
  bool _loading = false;
  String? _error;

  List<PublicEvent> get events => _events;
  PublicEvent? get currentEvent => _currentEvent;
  List<ArFrame> get frames => _frames;
  bool get loading => _loading;
  String? get error => _error;

  /// Fetch all active events
  Future<void> fetchEvents({String? status}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _eventService.getAllEvents(status: status ?? 'Active');
      // Filter out past events
      _events = _events.where((e) => e.eventStatus != 'past').toList();
      // Sort: live first, then by startTime ascending
      _events.sort((a, b) {
        if (a.eventStatus == 'live' && b.eventStatus != 'live') return -1;
        if (a.eventStatus != 'live' && b.eventStatus == 'live') return 1;
        return DateTime.parse(a.startTime).compareTo(DateTime.parse(b.startTime));
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch single event by ID
  Future<void> fetchEventById(String id) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _currentEvent = await _eventService.getEventById(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Fetch frames for an event
  Future<void> fetchEventFrames(String eventId) async {
    try {
      _frames = await _eventService.getEventFrames(eventId);
      notifyListeners();
    } catch (e) {
      _frames = [];
      notifyListeners();
    }
  }

  /// Record frame usage (silent)
  Future<void> recordFrameUsage(String eventId, String frameId) async {
    await _eventService.recordFrameUsage(eventId, frameId);
  }
}
