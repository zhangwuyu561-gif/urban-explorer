import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
String selectedCategory = 'cafe';
double? currentLat;
double? currentLng;
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

    currentLat = position.latitude;
currentLng = position.longitude;

fetchNearbyPlaces(position.latitude, position.longitude, selectedCategory);
  }

  Future<void> fetchNearbyPlaces(double lat, double lng, String type) async {
    const apiKey = 'AIzaSyCKsEC7MLoQdS_IfqVKpjspPiiHr1qmFpY';

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=1500'
        '&type=$type'
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
          icon: const Icon(Icons.people),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CommunityPage(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.map),
          onPressed: () {
            if (apiPlaces.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapViewPage(
                    places: apiPlaces,
                  ),
                ),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryPage(),
              ),
            );
          },
        ),
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
                  final categoryLabel = categories[index];

final categoryType = switch (categoryLabel) {
  '☕ Cafés' => 'cafe',
  '📚 Quiet Spaces' => 'library',
  '🌳 Parks' => 'park',
  '🎨 Interesting Spots' => 'tourist_attraction',
  _ => 'cafe',
};

return ChoiceChip(
  label: Text(categoryLabel),
  selected: selectedCategory == categoryType,
  onSelected: (selected) {
    if (currentLat != null && currentLng != null) {
      setState(() {
        selectedCategory = categoryType;
        apiPlaces = [];
      });

      fetchNearbyPlaces(currentLat!, currentLng!, selectedCategory);
    }
  },
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
        'type': selectedCategory,
        'description':
            (apiPlaces[index]['vicinity'] ?? 'No address available').toString(),
            'image': apiPlaces[index]['photos'] != null &&
        apiPlaces[index]['photos'].isNotEmpty
    ? 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=${apiPlaces[index]['photos'][0]['photo_reference']}'
        '&key=AIzaSyCKsEC7MLoQdS_IfqVKpjspPiiHr1qmFpY'
    : 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
      };

                  return Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
                    child: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (place['image'] != null && place['image']!.isNotEmpty)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            place['image']!,
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 140,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
      if (place['image'] != null && place['image']!.isNotEmpty)
        const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          place['name']!,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('${place['type']} · ${place['description']}'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
  await FirebaseFirestore.instance.collection('history').add({
    'name': place['name'],
    'type': place['type'],
    'description': place['description'],
    'image': place['image'] ?? '',
    'viewedAt': FieldValue.serverTimestamp(),
  });

  Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceDetailPage(place: place),
            ),
          );
        },
      ),
    ],
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

  final TextEditingController commentController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  int selectedRating = 5;
  String selectedTag = 'Study';

  final List<String> commentTags = [
    'Study',
    'Relax',
    'Social',
    'Hidden Gem',
    'Good Atmosphere',
  ];

  Future<void> openInGoogleMaps(String placeName) async {
    final encodedPlace = Uri.encodeComponent(placeName);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedPlace',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> addComment() async {
    final place = widget.place;
    final commentText = commentController.text.trim();
    final username = usernameController.text.trim();

    if (commentText.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('comments').add({
      'placeName': place['name'],
      'username': username.isEmpty ? 'Anonymous user' : username,
      'comment': commentText,
      'rating': selectedRating,
      'tag': selectedTag,
      'createdAt': FieldValue.serverTimestamp(),
    });

    commentController.clear();
    usernameController.clear();

    setState(() {
      selectedRating = 5;
      selectedTag = 'Study';
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(
        title: Text(place['name']!),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.network(
                place['image'] ??
                    'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=400',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            Text(
              place['name']!,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              place['type']!,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
            ),
const SizedBox(height: 12),

StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('comments')
      .where('placeName', isEqualTo: place['name'])
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Text(
        'No ratings yet',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black54,
        ),
      );
    }

    final comments = snapshot.data!.docs;

    double totalRating = 0;

    for (final doc in comments) {
      final data = doc.data() as Map<String, dynamic>;
      totalRating += (data['rating'] ?? 0).toDouble();
    }

    final averageRating = totalRating / comments.length;

    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          averageRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${comments.length} reviews',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  },
),
            const SizedBox(height: 24),

            Text(
              place['description']!,
              style: const TextStyle(
                fontSize: 17,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  openInGoogleMaps(place['name']!);
                },
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('favourites').add({
                    'name': place['name'],
                    'type': place['type'],
                    'description': place['description'],
                    'image': place['image'] ?? '',
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

            const SizedBox(height: 32),

            const Text(
              'Comments',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                hintText: 'Your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Share your thoughts about this place...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: List.generate(5, (index) {
                final starNumber = index + 1;

                return IconButton(
                  icon: Icon(
                    starNumber <= selectedRating
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      selectedRating = starNumber;
                    });
                  },
                );
              }),
            ),

            Wrap(
              spacing: 8,
              children: commentTags.map((tag) {
                return ChoiceChip(
                  label: Text(tag),
                  selected: selectedTag == tag,
                  onSelected: (selected) {
                    setState(() {
                      selectedTag = tag;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: addComment,
                child: const Text('Post Comment'),
              ),
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('comments')
                  .where('placeName', isEqualTo: place['name'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No comments yet.');
                }

                final comments = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data =
                        comments[index].data() as Map<String, dynamic>;

                    final username = data['username'] ?? 'Anonymous user';
                    final comment = data['comment'] ?? '';
                    final rating = data['rating'] ?? 5;
                    final tag = data['tag'] ?? 'General';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.deepPurple.shade100,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '⭐ $rating',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(comment),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visited History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('history')
            .orderBy('viewedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong loading history.'),
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
                'No places viewed yet.',
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
              final image = data['image'] ?? '';

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: image.toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            image,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade100,
                          child: const Icon(Icons.history),
                        ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('$type · $description'),
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
class MapViewPage extends StatelessWidget {
  final List<Map<String, dynamic>> places;

  const MapViewPage({
    super.key,
    required this.places,
  });

  @override
  Widget build(BuildContext context) {
    final validPlaces = places.where((place) {
      return place['geometry'] != null &&
          place['geometry']['location'] != null &&
          place['geometry']['location']['lat'] != null &&
          place['geometry']['location']['lng'] != null;
    }).toList();

    final firstLocation = validPlaces.isNotEmpty
        ? validPlaces.first['geometry']['location']
        : {'lat': 51.5246, 'lng': -0.1340};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(
            firstLocation['lat'],
            firstLocation['lng'],
          ),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.urban_explorer',
          ),
          MarkerLayer(
            markers: validPlaces.map((place) {
              final location = place['geometry']['location'];
              final name = place['name'] ?? 'Place';

              return Marker(
                point: LatLng(
                  location['lat'],
                  location['lng'],
                ),
                width: 80,
                height: 80,
                child: Tooltip(
                  message: name,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.deepPurple,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('comments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No posts yet.'));
          }

          final posts = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;

              final placeName = data['placeName'] ?? 'Unknown place';
              final username = data['username'] ?? 'Anonymous';
              final comment = data['comment'] ?? '';
              final rating = data['rating'] ?? 5;
              final tag = data['tag'] ?? '';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Text('⭐ $rating'),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(comment),

                      const SizedBox(height: 10),

                      Text(
                        '— $username',
                        style: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
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