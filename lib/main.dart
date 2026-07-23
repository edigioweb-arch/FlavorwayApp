import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/cart_service.dart';
import 'services/restaurant_service.dart';
import 'services/message_service.dart';
import 'services/notification_service.dart';
import 'services/locale_service.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/restaurant_detail_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/order_success_screen.dart';
import 'screens/order_tracking_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/restaurant_owner/restaurant_owner_login_screen.dart';
import 'screens/restaurant_owner/restaurant_dashboard_screen.dart';
import 'screens/restaurant_owner/edit_menu_screen.dart';
import 'screens/restaurant_owner/edit_restaurant_screen.dart';
import 'screens/reservations_screen.dart';
import 'screens/restaurant_owner/edit_gallery_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => RestaurantService()),
        ChangeNotifierProvider(create: (_) => MessageService()),
        ChangeNotifierProvider.value(value: NotificationService.instance),
        ChangeNotifierProvider.value(value: LocaleService.instance),
      ],
      child: const FlavorWayApp(),
    ),
  );
}

class FlavorWayApp extends StatelessWidget {
  const FlavorWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleService>(
      builder: (context, localeService, child) {
        return MaterialApp(
          title: 'FlavorWay',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr'),
            Locale('en'),
          ],
          locale: localeService.locale,
          theme: ThemeData(
            primarySwatch: Colors.purple,
            useMaterial3: true,
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const WelcomePage(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/home': (context) => const HomeScreen(),
            '/restaurant-detail': (context) => const RestaurantDetailScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/orders': (context) => const OrdersScreen(),
            '/cart': (context) => const CartScreen(),
            '/checkout': (context) => const CheckoutScreen(),
            '/order-success': (context) => const OrderSuccessScreen(),
            '/order-tracking': (context) => const OrderTrackingScreen(),
            '/chat': (context) => const ChatScreen(
                  conversationId: 'restaurant_joli_coin',
                ),
            '/restaurant-owner-login': (context) =>
                RestaurantOwnerLoginScreen(),
            '/messages': (context) => const MessagesScreen(),
            '/notifications': (context) => const NotificationsScreen(),
            '/reservations': (context) => const ReservationsScreen(),
            '/restaurant-dashboard': (context) => RestaurantDashboardScreen(),
            '/edit-menu': (context) => EditMenuScreen(),
            '/edit-restaurant': (context) => EditRestaurantScreen(),
            '/edit-gallery': (context) => EditGalleryScreen(),
          },
        );
      },
    );
  }
}
