import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  runApp(const UmpApp());
}

class UmpApp extends StatelessWidget {
  const UmpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UMP',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF120E1A), // Samsung Dark Plum-Ink Theme[span_3](start_span)[span_3](end_span)
        primaryColor: const Color(0xFFFF9F0A), // Saffron Accent[span_4](start_span)[span_4](end_span)
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9F0A),
          secondary: Color(0xFFDA70D6), // Orchid Accent[span_5](start_span)[span_5](end_span)
          surface: Color(0xFF1E1829),
        ),
      ),
      home: const MusicPlayerScreen(),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  late AudioPlayer _audioPlayer;
  final YoutubeExplode _yt = YoutubeExplode();
  
  bool _isPlaying = false;
  String _currentTitle = "Search your favorite track";
  String _currentArtist = "UMP Music Streamer";
  String _thumbnailUrl = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _yt.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _playSongFromQuery(String query) async {
    try {
      setState(() {
        _currentTitle = "Searching song...";
      });

      var videos = await _yt.search.search(query);
      if (videos.isEmpty) return;

      var video = videos.first;
      var manifest = await _yt.videos.streamsClient.getManifest(video.id);
      var audioStream = manifest.audioOnly.withHighestBitrate();

      await _audioPlayer.setUrl(audioStream.url.toString());
      await _audioPlayer.play();

      setState(() {
        _currentTitle = video.title;
        _currentArtist = video.author;
        _thumbnailUrl = video.thumbnails.highResUrl;
      });
    } catch (e) {
      setState(() {
        _currentTitle = "Playback Error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("UMP Music", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Search Bar (Samsung One UI Rounded Card Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2238),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: "Search song...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Color(0xFFFF9F0A)),
                    onPressed: () {
                      if (_searchController.text.isNotEmpty) {
                        _playSongFromQuery(_searchController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Album Art Container with Glow
            Container(
              height: 260,
              width: 260,
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9F0A).withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
                image: _thumbnailUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_thumbnailUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _thumbnailUrl.isEmpty
                  ? const Center(child: Icon(Icons.music_note, size: 80, color: Colors.white54))
                  : null,
            ),
            const SizedBox(height: 30),

            // Track Meta Info
            Text(
              _currentTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentArtist,
              style: const TextStyle(fontSize: 14, color: Color(0xFFDA70D6)),
            ),
            const SizedBox(height: 40),

            // Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 36),
                  onPressed: () {},
                ),
                const SizedBox(width: 20),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFFF9F0A),
                  child: IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 32, color: Colors.black),
                    onPressed: () {
                      if (_isPlaying) {
                        _audioPlayer.pause();
                      } else {
                        _audioPlayer.play();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 36),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
