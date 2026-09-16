import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/cart_service.dart';
import 'services/city_service.dart';
import 'services/restaurant_service.dart';
import 'services/restaurant_subscription_service.dart';
import 'services/message_service.dart';
import 'services/notification_service.dart';
import 'services/notification_navigation_service.dart';
import 'services/locale_service.dart';
import 'services/user_auth_service.dart';
import 'screens/messages_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
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
import 'widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.instance.initialize();

  // UserAuthService est placé en provider racine DIRECT, au-dessus de tout,
  // pour éviter toute coupure de contexte (Navigator, MaterialApp, routes).
  // AuthGate utilise Consumer<UserAuthService> et doit pouvoir remonter
  // jusqu'ici sans interruption.
  runApp(
    ChangeNotifierProvider<UserAuthService>.value(
      value: UserAuthService.instance,
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartService()),
          ChangeNotifierProvider(create: (_) => CityService()),
          ChangeNotifierProvider(create: (_) => RestaurantService()),
          ChangeNotifierProvider(
              create: (_) => RestaurantSubscriptionService()),
          ChangeNotifierProvider(create: (_) => MessageService()),
          ChangeNotifierProvider.value(value: NotificationService.instance),
          ChangeNotifierProvider.value(value: LocaleService.instance),
        ],
        child: const FlavorWayApp(),
      ),
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
          builder: (context, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                NotificationNavigationService.instance.flushPendingPayload());
            return child ?? const SizedBox.shrink();
          },
          title: 'FlavorWay',
          debugShowCheckedModeBanner: false,
          navigatorKey: NotificationNavigationService.instance.navigatorKey,
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

          // AuthGate utilise Consumer<UserAuthService> qui remonte
          // jusqu'au provider racine dans runApp().
          home: const AuthGate(
            loginWidget: WelcomePage(),
            verificationWidget: EmailVerificationScreen(),
            homeWidget: HomeScreen(),
          ),

          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/restaurant-detail': (context) => const RestaurantDetailScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/orders': (context) => const OrdersScreen(),
            '/cart': (context) => const CartScreen(),
            '/checkout': (context) => const CheckoutScreen(),
            '/order-success': (context) => const OrderSuccessScreen(),
            '/order-tracking': (context) {
              final rawArguments = ModalRoute.of(context)?.settings.arguments;
              String orderReference = '';

              if (rawArguments is String) {
                orderReference = rawArguments;
              } else if (rawArguments is Map) {
                orderReference = (rawArguments['order_reference'] ??
                        rawArguments['order_number'] ??
                        rawArguments['order_id'] ??
                        '')
                    .toString();
              }

              return OrderTrackingScreen(orderReference: orderReference);
            },
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
