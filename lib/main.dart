import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const UrbanExplorerApp());
}

class UrbanExplorerApp extends StatelessWidget {
  const UrbanExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                'Urban Explorer',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Discover interesting places around you.',
                style: TextStyle(fontSize: 20, color: Colors.black54),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Find cafés, quiet spaces, parks, and hidden urban spots based on your current location.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  child: const Text(
                    'Start Exploring',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String locationText = 'Getting location...';
List<Map<String, dynamic>> apiPlaces = [];
  final List<String> categories = const [
    '☕ Cafés',
    '📚 Quiet Spaces',
    '🌳 Parks',
    '🎨 Interesting Spots',
  ];

  final List<Map<String, String>> places = const [
    {
      'name': 'Bloomsbury Coffee House',
      'type': 'Café',
      'description': 'A cosy place for studying and meeting friends.',
    },
    {
      'name': 'Russell Square',
      'type': 'Park',
      'description': 'A calm green space near campus.',
    },
    {
      'name': 'Senate House Library',
      'type': 'Quiet Space',
      'description': 'A quiet indoor space for focused work.',
    },
  ];

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        locationText = 'Location services are disabled';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          locationText = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationText = 'Location permission permanently denied';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition();

        setState(() {
      locationText =
          '📍 Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    });

    fetchNearbyPlaces(position.latitude, position.longitude);
  }

  Future<void> fetchNearbyPlaces(double lat, double lng) async {
    const apiKey = 'AIzaSyCKsEC7MLoQdS_IfqVKpjspPiiHr1qmFpY';

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=1500'
        '&type=cafe'
        '&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        apiPlaces = List<Map<String, dynamic>>.from(data['results']);
      });
    } else {
      setState(() {
        locationText = 'Failed to load nearby places';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Urban Explorer'),
  actions: [
    IconButton(
      icon: const Icon(Icons.favorite),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FavouritesPage(),
          ),
        );
      },
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locationText,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Explore nearby',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose what kind of place you want to discover today.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Chip(
                    label: Text(categories[index]),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recommended places',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: apiPlaces.isEmpty ? places.length : apiPlaces.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final Map<String, String> place = apiPlaces.isEmpty
    ? places[index]
    : {
        'name': (apiPlaces[index]['name'] ?? 'Unknown place').toString(),
        'type': 'Cafe',
        'description':
            (apiPlaces[index]['vicinity'] ?? 'No address available').toString(),
      };

                  return Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        place['name']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${place['type']} · ${place['description']}',
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PlaceDetailPage(place: place),
                          ),
                        );
                      },
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

class PlaceDetailPage extends StatefulWidget {
  final Map<String, String> place;

  const PlaceDetailPage({
    super.key,
    required this.place,
  });

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  bool isFavourite = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(title: Text(place['name']!)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
  height: 200,
  width: double.infinity,
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(28),
    gradient: LinearGradient(
      colors: [
        Colors.deepPurple.shade200,
        Colors.deepPurple.shade50,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: const Center(
    child: Icon(
      Icons.explore,
      size: 90,
      color: Colors.deepPurple,
    ),
  ),
),
            const SizedBox(height: 24),
            Text(
              place['name']!,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              place['type']!,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Text(
              place['description']!,
              style: const TextStyle(fontSize: 17, height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
               onPressed: () async {
  await FirebaseFirestore.instance.collection('favourites').add({
    'name': place['name'],
    'type': place['type'],
    'description': place['description'],
    'createdAt': FieldValue.serverTimestamp(),
  });

  setState(() {
    isFavourite = true;
  });
},
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text(
                  isFavourite ? 'Saved to Favourites' : 'Save to Favourites',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favourites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favourites')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong loading favourites.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No favourites saved yet.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unknown place';
              final type = data['type'] ?? 'Place';
              final description = data['description'] ?? 'No description';

              return Dismissible(
                key: ValueKey(docs[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
                onDismissed: (direction) async {
                  await FirebaseFirestore.instance
                      .collection('favourites')
                      .doc(docs[index].id)
                      .delete();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Favourite removed'),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.deepPurple,
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('$type · $description'),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}