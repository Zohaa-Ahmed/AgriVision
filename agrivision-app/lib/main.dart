import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    home: SplashScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

// ==========================================
// 1. THE SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.eco, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text("AgriVision", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
            const SizedBox(height: 10),
            const Text("AI Crop Diagnostics", style: TextStyle(fontSize: 16, color: Colors.white70, fontStyle: FontStyle.italic))
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. THE ONBOARDING CAROUSEL
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {"title": "Welcome to AgriVision", "description": "Your pocket-sized agricultural expert. Detect crop diseases early and protect your yield.", "icon": Icons.energy_savings_leaf_outlined},
    {"title": "Snap a Leaf", "description": "Simply take a clear photo of a diseased plant leaf using your camera or gallery.", "icon": Icons.camera_enhance_outlined},
    {"title": "Get Instant AI Results", "description": "Our Deep Learning model analyzes the image and provides instant treatment recommendations.", "icon": Icons.health_and_safety_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PlantHome())),
                child: const Text("Skip", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(color: brandGreen.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(onboardingData[index]["icon"], size: 100, color: brandGreen),
                        ),
                        const SizedBox(height: 40),
                        Text(onboardingData[index]["title"], textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 16),
                        Text(onboardingData[index]["description"], textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 10,
                        width: _currentPage == index ? 24 : 10,
                        decoration: BoxDecoration(color: _currentPage == index ? brandGreen : Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PlantHome()));
                      } else {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: brandGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    child: Text(_currentPage == onboardingData.length - 1 ? "Get Started" : "Next", style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. MAIN CAMERA SCREEN
// ==========================================
class PlantHome extends StatefulWidget {
  const PlantHome({super.key});

  @override
  _PlantHomeState createState() => _PlantHomeState();
}

class _PlantHomeState extends State<PlantHome> {
  File? _image;
  bool _loading = false;
  final picker = ImagePicker();

  Future getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      uploadImage(_image!);
    }
  }

  Future uploadImage(File image) async {
    setState(() {
      _loading = true;
    });

    var uri = Uri.parse("https://agrivision-backend-iyjl.onrender.com/api/detect");
    try {
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var decodedResult = json.decode(responseData);
        
        setState(() {
          _loading = false;
        });

        // SUCCESS! Navigate to the new Result Screen
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(image: image, result: decodedResult),
          ),
        );

      } else {
        showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      showError("Connection Failed. Is Spring Boot running?");
    }
  }

  void showError(String msg) {
    setState(() {
      _loading = false;
    });
    // Show a sleek SnackBar instead of an ugly red box
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, color: brandGreen, size: 36),
                    SizedBox(width: 8),
                    Text("AgriVision", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Upload a leaf to diagnose diseases instantly.", style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                const SizedBox(height: 40),

                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8))],
                  ),
                  child: _image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: brandGreen.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.document_scanner_outlined, size: 60, color: brandGreen),
                            ),
                            const SizedBox(height: 20),
                            const Text("SCAN TO DISCOVER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: brandGreen, letterSpacing: 1.2)),
                            const SizedBox(height: 8),
                            Text("Open up a world of possibilities", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                          ],
                        )
                      : ClipRRect(borderRadius: BorderRadius.circular(30), child: Image.file(_image!, fit: BoxFit.cover)),
                ),
                const SizedBox(height: 35),

                if (_loading) 
                  const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brandGreen)))
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => getImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text("Camera", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: brandGreen, padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder(), elevation: 2),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => getImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, color: brandGreen),
                          label: const Text("Gallery", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandGreen)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: const StadiumBorder(), side: const BorderSide(color: brandGreen, width: 2), elevation: 0),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. NEW DEDICATED RESULT SCREEN
// ==========================================
class ResultScreen extends StatelessWidget {
  final File image;
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.image, required this.result});

  @override
  Widget build(BuildContext context) {
   // 🟢 UPDATE THESE LINES:
    bool isLowConfidence = result['disease_name'] == 'Low Confidence / Unknown';
    bool isBackground = result['disease_name'] == 'Background_Not_Plant';
    
    // Now 'isInvalid' is true if it's a background OR if the confidence was too low
    bool isInvalid = isBackground || isLowConfidence;

    // The rest of your existing color logic stays exactly the same!
    Color primaryColor = isInvalid ? Colors.orange.shade800 : const Color(0xFF2E7D32);
    Color bgLight = isInvalid ? Colors.orange.shade50 : const Color(0xFF2E7D32).withOpacity(0.05);
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text("Diagnosis Result", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the analyzed image
              Center(
                child: Hero(
                  tag: 'scanned_image',
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(image, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // The Result Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isInvalid ? Icons.warning_rounded : Icons.check_circle, color: primaryColor, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isInvalid ? "Invalid Image" : (result['disease_name'] ?? "Diagnosis"),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    if (!isInvalid) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Confidence Score: ${((result['confidence'] ?? 0) * 100).toStringAsFixed(1)}%",
                        style: TextStyle(fontSize: 15, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                    const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider(height: 1)),
                    
                    Text(isInvalid ? "Message:" : "Diagnosis Overview:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text(result['description'] ?? "", style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                    
                    const SizedBox(height: 24),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isInvalid ? Icons.error_outline : Icons.medical_services_outlined, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              Text(isInvalid ? "Action Required:" : "Recommended Treatment:", style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(result['treatment'] ?? "", style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Back Button to scan another leaf
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Scan Another Leaf", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}