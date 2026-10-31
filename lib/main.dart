import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const UmpMusicApp());
}

class UmpMusicApp extends StatelessWidget {
  const UmpMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMP - Unidentified Music Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121016), // Dark Plum Accent
        colorScheme: const theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121016),
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF9E7CFF),
          onPrimary: Colors.white,
          secondary: Color(0xFF9E7CFF),
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Color(0xFF1E1A24),
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
          primary: Color(0xFF9E7CFF), // One UI Soft Violet
          surface: Color(0xFF1E1A24),
          surfaceContainerHigh: Color(0xFF2A2433),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// MODELS & SERVICES
// ---------------------------------------------------------------------------

class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
  });
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer player = AudioPlayer();
  final yt.YoutubeExplode _yt = yt.YoutubeExplode();

  final ValueNotifier<Song?> currentSong = ValueNotifier(null);
  final List<Song> queue = [];
  int currentIndex = -1;

  // Crossfade implementation helper
  Future<void> playSong(Song song) async {
    currentSong.value = song;
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(song.id);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      
      // Crossfade logic simulation: soft fade out then play next
      if (player.playing) {
        for (double i = 1.0; i >= 0.0; i -= 0.2) {
          await player.setVolume(i);
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      await player.setUrl(streamInfo.url.toString());
      await player.setVolume(1.0);
      player.play();
    } catch (e) {
      debugPrint("Streaming Error: $e");
    }
  }

  void playNext() {
    if (currentIndex < queue.length - 1) {
      currentIndex++;
      playSong(queue[currentIndex]);
    }
  }

  void playPrevious() {
    if (currentIndex > 0) {
      currentIndex--;
      playSong(queue[currentIndex]);
    }
  }
}

// ---------------------------------------------------------------------------
// MAIN NAVIGATION SCREEN (Samsung One UI Styled)
// ---------------------------------------------------------------------------

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex],
          const Positioned(
            left: 0,
            right: 0,
            bottom: 75,
            child: MiniPlayerWidget(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1A24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF9E7CFF),
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME SCREEN (Recommendations: Hindi, Punjabi, Haryanvi)
// ---------------------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("UMP", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const Text("Unidentified Music Player", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                const CircleAvatar(
                  backgroundColor: Color(0xFF2A2433),
                  child: Icon(Icons.person, color: Colors.white),
                )
              ],
            ),
            const SizedBox(height: 24),

            // Regional Sections
            _buildSection("🔥 Trending Hindi Mix", "Hindi Hits 2026"),
            _buildSection("⚡ Punjabi Beats", "Punjabi Top Tracks"),
            _buildSection("🎧 Haryanvi Ragni & Beats", "Haryanvi Latest"),
            _buildSection("✨ Recommended For You", "Based on your history"),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String query) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: FutureBuilder<List<Song>>(
            future: _fetchCategorySongs(query),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final song = snapshot.data![index];
                  return GestureDetector(
                    onTap: () {
                      AudioPlayerService().queue.clear();
                      AudioPlayerService().queue.addAll(snapshot.data!);
                      AudioPlayerService().currentIndex = index;
                      AudioPlayerService().playSong(song);
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(song.thumbnailUrl, height: 120, width: 120, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 6),
                          Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<List<Song>> _fetchCategorySongs(String query) async {
    final ytClient = yt.YoutubeExplode();
    var searchResults = await ytClient.search.search(query);
    return searchResults.take(6).map((video) {
      return Song(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.highResUrl,
        duration: video.duration ?? Duration.zero,
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// SEARCH SCREEN
// ---------------------------------------------------------------------------

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Song> _searchResults = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isLoading = true);
    
    final ytClient = yt.YoutubeExplode();
    var results = await ytClient.search.search(query);
    
    setState(() {
      _searchResults = results.map((video) {
        return Song(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.highResUrl,
          duration: video.duration ?? Duration.zero,
        );
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search songs, artists, or AI recs...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9E7CFF)),
                filled: true,
                fillColor: const Color(0xFF1E1A24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final song = _searchResults[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(song.thumbnailUrl, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      AudioPlayerService().playSong(song);
                    },
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

// ---------------------------------------------------------------------------
// MINI PLAYER WIDGET
// ---------------------------------------------------------------------------

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService();
    return ValueListenableBuilder<Song?>(
      valueListenable: playerService.currentSong,
      builder: (context, song, child) {
        if (song == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2433),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(song.thumbnailUrl, width: 45, height: 45, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              StreamBuilder<PlayerState>(
                stream: playerService.player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton(
                    icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: const Color(0xFF9E7CFF), size: 36),
                    onPressed: () {
                      if (playing) {
                        playerService.player.pause();
                      } else {
                        playerService.player.play();
                      }
                    },
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}
