import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiuc_bazaar/MVVM/Models/orderModel.dart';
import 'package:iiuc_bazaar/MVVM/View%20Model/orderViewModel.dart';
import 'Products.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _userType = 'Buyer';
  bool _isLoading = true;
  final OrderViewModel _orderViewModel = OrderViewModel();

  // Seller Dashboard Stats
  int totalItemsSold = 0;
  int totalEarnings = 0;
  int thisMonthItemsSold = 0;
  int thisMonthSales = 0;

  final List<String> carouselImages = [
    'assets/slide1.jpg',
    'assets/slide2.jpg',
    'assets/slide3.jpg',
    'assets/slide4.jpg',
    'assets/slide5.jpg',
  ];

  final List<Map<String, String>> categories = [
    {'name': 'Shoes', 'image': 'assets/shoes.jpg'},
    {'name': 'Food', 'image': 'assets/food.jpg'},
    {'name': 'Clothing', 'image': 'assets/clothing.jpg'},
    {'name': 'Electronics', 'image': 'assets/electronics.jpg'},
    {'name': 'Books', 'image': 'assets/books.jpg'},
    {'name': 'Accessories', 'image': 'assets/accessories.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Get user type
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _userType = userDoc['userType'] ?? 'Buyer';
        });
      }

      // Only fetch sales if seller
      if (_userType == 'Seller') {
        final List<OrderModel> completedOrders =
        await _orderViewModel.fetchCompletedSales(user.uid);

        _calculateSellerStats(completedOrders);
      }
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateSellerStats(List<OrderModel> orders) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);

    totalItemsSold = 0;
    totalEarnings = 0;
    thisMonthItemsSold = 0;
    thisMonthSales = 0;

    for (var order in orders) {
      if (order.status != 'Completed') continue;

      final int qty = order.quantity;
      final int price = order.totalPrice.round(); // Convert double → int (BDT)

      // All-time
      totalItemsSold += qty;
      totalEarnings += price;

      // This month only
      if (order.orderDate.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        thisMonthItemsSold += qty;
        thisMonthSales += price;
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: Text(
          "IIUC Bazaar",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.teal.shade800),
            onPressed: () => _showExitDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCarousel(),
            const SizedBox(height: 20),
            if (_userType == 'Seller') _buildSellerDashboard(),
            if (_userType == 'Seller') const SizedBox(height: 20),
            _buildCategoriesSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return CarouselSlider.builder(
      itemCount: carouselImages.length,
      itemBuilder: (context, index, realIndex) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: Get.width * 0.02),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              carouselImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: Get.height * 0.26,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.88,
        aspectRatio: 16 / 9,
        autoPlayInterval: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildSellerDashboard() {
    final List<DashboardCardData> cards = [
      DashboardCardData(
        title: "Total Items Sold",
        value: totalItemsSold.toString(),
        icon: Icons.shopping_bag_outlined,
        color: Colors.teal.shade600,
      ),
      DashboardCardData(
        title: "Total Earnings",
        value: "৳$totalEarnings",
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.green.shade600,
      ),
      DashboardCardData(
        title: "This Month Items",
        value: thisMonthItemsSold.toString(),
        icon: Icons.today_outlined,
        color: Colors.orange.shade600,
      ),
      DashboardCardData(
        title: "This Month Sales",
        value: "৳$thisMonthSales",
        icon: Icons.trending_up,
        color: Colors.purple.shade600,
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Get.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Business Overview",
            style: GoogleFonts.poppins(
              fontSize: Get.width * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _buildDashboardCard(
                title: card.title,
                value: card.value,
                icon: card.icon,
                color: card.color,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final double screenWidth = Get.width;
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Categories",
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.04,
              mainAxisSpacing: screenWidth * 0.04,
              childAspectRatio: 1.5,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryCard(
                name: category['name']!,
                imagePath: category['image']!,
                onTap: () => Get.to(() => Products(filterKeyword: category['name']!)),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helper class
class DashboardCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  DashboardCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

// Category Card
class CategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.name,
    required this.imagePath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Get.width * 0.04),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: Get.width * 0.045,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Exit Dialog
void _showExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Exit App'),
      content: const Text('Are you sure you want to exit?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            SystemNavigator.pop();
          },
          child: const Text('Exit', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}