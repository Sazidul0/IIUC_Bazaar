import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
  List<OrderModel> _salesData = [];

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
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && mounted) {
        setState(() => _userType = userDoc['userType'] ?? 'Buyer');
      }

      if (_userType == 'Seller') {
        _salesData = await _orderViewModel.fetchCompletedSales(user.uid);
        if (mounted) setState(() {});
      }
    } catch (e) {
      print("Error loading initial data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            if (_userType == 'Seller') _buildMonthlySalesChart(),
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

  Widget _buildMonthlySalesChart() {
    if (_salesData.isEmpty) {
      return _buildNoSalesWidget();
    }

    final chartData = _prepareMonthlySalesData();

    if (chartData.every((e) => e.amount == 0)) {
      return _buildNoSalesWidget();
    }

    return Padding(
      padding: EdgeInsets.all(Get.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sales - Last 30 Days",
            style: GoogleFonts.poppins(
              fontSize: Get.width * 0.052,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: Get.width * 0.95,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SfCartesianChart(
              primaryXAxis: const CategoryAxis(
                labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                majorGridLines: MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '৳{value}',
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                numberFormat: null,
              ),
              title: ChartTitle(
                text: 'Monthly Sales Overview',
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.teal.shade700,
                ),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x : ৳point.y',
                animationDuration: 1,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              zoomPanBehavior: ZoomPanBehavior(enablePinching: true, enablePanning: true),
              series: <CartesianSeries>[
                ColumnSeries<MonthlySalesData, String>(
                  dataSource: chartData,
                  xValueMapper: (data, _) => data.day,
                  yValueMapper: (data, _) => data.amount,
                  name: 'Sales',
                  color: Colors.teal.shade500,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  width: 0.75,
                  spacing: 0.2,
                  animationDuration: 1200, // Fixed the animation duration issue
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelAlignment: ChartDataLabelAlignment.top,
                    textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSalesWidget() {
    return Padding(
      padding: EdgeInsets.all(Get.width * 0.04),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(Icons.bar_chart_outlined, size: 60, color: Colors.grey[400]), // Fixed icon
            const SizedBox(height: 12),
            Text(
              "No sales in the last 30 days",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  List<MonthlySalesData> _prepareMonthlySalesData() {
    final Map<String, double> dailySales = {};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Initialize last 30 days
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = "${date.day}/${date.month}";
      dailySales[key] = 0;
    }

    // Fill actual sales
    for (var order in _salesData) {
      if (order.orderDate.isAfter(thirtyDaysAgo)) {
        final date = order.orderDate;
        final key = "${date.day}/${date.month}";
        dailySales[key] = (dailySales[key] ?? 0) + order.totalPrice;
      }
    }

    return dailySales.entries.map((e) => MonthlySalesData(e.key, e.value)).toList();
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

// Data class for chart
class MonthlySalesData {
  final String day;
  final double amount;
  MonthlySalesData(this.day, this.amount);
}

// Category Card
class CategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback onTap;

  const CategoryCard({Key? key, required this.name, required this.imagePath, required this.onTap})
      : super(key: key);

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
