import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/events_page.dart';
import 'screens/event_detail_page.dart';
import 'screens/camera_frame_page.dart';
import 'screens/wishwall_page.dart';
import 'screens/change_password_page.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LinkieApp());
}

class LinkieApp extends StatelessWidget {
  const LinkieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'Linkie',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          final segments = uri.pathSegments;

          // /events/:id
          if (segments.length == 2 && segments[0] == 'events') {
            return MaterialPageRoute(
              builder: (_) => EventDetailPage(eventId: segments[1]),
              settings: settings,
            );
          }

          // /events/:id/camera-frame
          if (segments.length == 3 && segments[0] == 'events' && segments[2] == 'camera-frame') {
            return MaterialPageRoute(
              builder: (_) => CameraFramePage(eventId: segments[1]),
              settings: settings,
            );
          }

          // /events/:id/wishwall
          if (segments.length == 3 && segments[0] == 'events' && segments[2] == 'wishwall') {
            return MaterialPageRoute(
              builder: (_) => WishwallPage(eventId: segments[1]),
              settings: settings,
            );
          }

          // Named routes
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
            case '/events':
              return MaterialPageRoute(builder: (_) => const EventsPage(), settings: settings);
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage(), settings: settings);
            case '/register':
              return MaterialPageRoute(builder: (_) => const RegisterPage(), settings: settings);
            case '/change-password':
              return MaterialPageRoute(builder: (_) => const ChangePasswordPage(), settings: settings);
            default:
              return MaterialPageRoute(builder: (_) => const HomePage(), settings: settings);
          }
        },
      ),
    );
  }
}
