import 'dart:io';

void main() {
  final file = File('C:/Users/ugoau/Downloads/project/lib/home_screen.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains("import 'widgets/home_carousel_widget.dart';")) {
    content = content.replaceFirst(
      "import 'screens/filter_modal.dart';", 
      "import 'screens/filter_modal.dart';\nimport 'widgets/home_carousel_widget.dart';"
    );
  }

  // 1. Wrap the SingleChildScrollView in a Column and insert HomeCarouselWidget
  content = content.replaceFirst(
    '''          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                  bottom:
                      150), // Pour ne pas cacher le contenu avec BottomBar+Jauge
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Custom Header ---''',
    '''          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const HomeCarouselWidget(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 150),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Custom Header ---'''
  );

  // 2. Remove the old banner section completely
  // Let's use a regex to match from "// --- Banners ---" to the end of "// Dots"
  final regex = RegExp(
    r'// --- Banners ---.*?// Dots.*?const SizedBox\(height: 24\),',
    dotAll: true,
  );
  content = content.replaceAll(regex, '');

  // 3. Fix the closing brackets
  content = content.replaceFirst(
    '''                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}''',
    '''                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
          ],
          ),
          ),
        ],
      ),
    );
  }
}'''
  );

  file.writeAsStringSync(content);
  print('home_screen.dart transformed!');
}
