import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'Products.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // List of carousel images (Google Drive links with corrected format)
    final List<String> carouselImages = [
      'https://drive.google.com/uc?export=view&id=1nZg26w-YdMjQu-vEhcA2hg17DpU4gy7B',
      'https://drive.google.com/uc?export=view&id=1DO0CWyNhX5nfc7d-4q3U77Qlk6orqDr-',
      'https://drive.google.com/uc?export=view&id=1SylxteyQabsgmyffoSrwOdge17jKzRrK',
      'https://drive.google.com/uc?export=view&id=1UKNH8HYOvPtate9gxjCwnoJqhdVPiK1T',
      'https://drive.google.com/uc?export=view&id=1_g4ED-ZZTGCkKMGkaDjOEgaymwGTvIQt',
    ];

    // List of categories (Google Drive links with corrected format)
    final List<Map<String, String>> categories = [
      {
        'name': 'Shoes',
        'image': 'https://drive.google.com/uc?export=view&id=1C1CmEt63pet5yjZrOnujWAGvqiMK071L',
      },
      {
        'name': 'Food',
        'image': 'https://drive.google.com/uc?export=view&id=1bDiYPT6x0qJVdEQsUE7-bPBSbuNwoFZ3',
      },
      {
        'name': 'Clothing',
        'image': 'https://drive.google.com/uc?export=view&id=1hm7DhvDhYRP0l3EktKBCwUB0erbVVBCp',
      },
      {
        'name': 'Electronics',
        'image': 'https://drive.google.com/uc?export=view&id=1XAm7tiVoYkst6r7IdVnmpZOw0hCb8TPH',
      },
      {
        'name': 'Books',
        'image': 'https://drive.google.com/uc?export=view&id=12LYMU3lXyfS2_6m6EYDCjjbmTzQQH0My',
      },
      {
        'name': 'Accessories',
        'image': 'https://drive.google.com/uc?export=view&id=148h_3FqcXzHu_ACJKqAIx4LOt81jlM7C',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("IIUC Bazaar", style: GoogleFonts.bokor(fontSize: 25),),
            Spacer(),
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                _showExitConfirmationDialog(context);
              },
            ),
          ],
        ),
        // GoogleFonts.poppins(fontSize: 15, color: HexColor("#8d8d8d")),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carousel Slider
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                viewportFraction: 0.8,
              ),
              items: carouselImages.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Text(
                    "   Categories",
                    style: GoogleFonts.poppins(fontSize: 20, color: HexColor("#8d8d8d")),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the Products page with the selected category as a filter
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Products(
                            filterKeyword: category['name']!,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(category['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Text(
                          category['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


void _showExitConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Exit Confirmation'),
        content: Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              // Exit the application
              // Note: This is not recommended in Flutter for mobile apps,
              // but you can use SystemNavigator.pop() if necessary.
              SystemNavigator.pop(); // Uncomment this line if you want to exit.
            },
          ),
        ],
      );
    },
  );
}
