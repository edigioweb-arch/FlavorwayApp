import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const Color orangeFlavor = Color(0xFFF36A2D);
  static const Color violetFlavor = Color(0xFF4B1F5C);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F9FB),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.black, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            'Commandes',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: Container(
              height: 48,
              margin: const EdgeInsets.fromLTRB(22, 8, 22, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                tabs: [
                  const Tab(text: 'En cours'),
                  const Tab(text: 'Historique'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildActiveOrders(context),
            _buildOrdersHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrders(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, _) {
        final orders = OrderService.instance.activeOrders;

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'Aucune commande en cours',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return _buildOrderCard(
              context,
              restaurant: order.restaurantName,
              date: order.date,
              price: '${order.total.toStringAsFixed(0)} CFA',
            items: 'Commande FlavorWay',
              status: order.status,
              statusColor: Colors.orange,
              isActive: true,
              orderId: order.orderNumber,
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersHistory(BuildContext context) {
    return AnimatedBuilder(
      animation: OrderService.instance,
      builder: (context, _) {
        final orders = OrderService.instance.completedOrders;

        if (orders.isEmpty) {
          return Center(
            child: Text(
              'Aucune commande dans l’historique',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];

            return _buildOrderCard(
              context,
              restaurant: order.restaurantName,
              date: order.date,
              price: '${order.total.toStringAsFixed(0)} CFA',
            items: 'Commande FlavorWay',
              status: order.status, // Dynamic data, keep as is
              statusColor:
                  order.status == 'Livrée'
                      ? Colors.green
                      : Colors.orange,
              isActive: false,
              orderId: order.orderNumber,
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    BuildContext context, {
    required String restaurant,
    required String date,
    required String price,
    required String items,
    required String status,
    required Color statusColor,
    required bool isActive,
    required String orderId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: orangeFlavor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: orangeFlavor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      orderId,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive // l10n: inDelivery, delivered
                          ? Icons.timer_rounded
                          : Icons.check_circle_rounded,
                      color: statusColor,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            date,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1),
          ),
          Text(
            items,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1F1F1F),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  price,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: violetFlavor,
                  ),
                ),
              ),
              if (isActive)
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/order-tracking'),
                  icon: const Icon(Icons.chevron_right_rounded,
                      color: Colors.white),
                  iconAlignment: IconAlignment.end,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangeFlavor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                  label: Text(
                    status == 'En livraison' ? 'Détails' : 'Suivre',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => _showOrderTicket(
                        context,
                        restaurant: restaurant,
                        orderId: orderId,
                        items: items,
                        price: price,
                        status: status,
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: violetFlavor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90),
                        ),
                      ),
                      child: const Text(
                        'Ticket', // l10n: ticket
                        style: TextStyle(
                          color: violetFlavor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$restaurant ajouté au panier'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: orangeFlavor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(90),
                        ),
                      ),
                      child: const Text(
                        'Recommander', // l10n: reorder
                        style: TextStyle(
                          color: orangeFlavor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOrderTicket(
    BuildContext context, {
    required String restaurant,
    required String orderId,
    required String items,
    required String price,
    required String status,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(40),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            // l10n: orderTicket
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ticket de commande',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14), // Dynamic data, keep as is
              Text(orderId),
              Text(restaurant),
              Text(items),
              Text(price),
              Text(status),
            ],
          ),
        );
      },
    );
  }
}
