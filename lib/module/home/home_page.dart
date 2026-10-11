import 'package:chat_bot/base.dart';
import 'package:chat_bot/base/version_check.dart';
import 'package:chat_bot/module/claude/app_theme.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:chat_bot/module/claude/ruang_kreasi.dart';
import 'package:chat_bot/module/claude/widgets/floating_pill_navbar.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:chat_bot/module/home/home_viewmodel.dart';

import '../../base/theme.dart';
import '../../const.dart';
import '../prompt/prompt_page.dart';
import '../services/services_page.dart';
import '../setting/setting_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  /// Provider 0..3 -> pill 0,1,3,4 (2 = Ruang Kreasi).
  int _toPillIndex(int providerIndex) {
    switch (providerIndex) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      default:
        return 4;
    }
  }

  void _onPillTap(int pillIndex) {
    if (pillIndex == 2) {
      // Tengah = Ruang Kreasi: ganti model + atur tools.
      openRuangKreasi(context);
      return;
    }
    int providerIndex = 0;
    if (pillIndex == 0) {
      providerIndex = 0;
    } else if (pillIndex == 1) {
      providerIndex = 1;
    } else if (pillIndex == 3) {
      providerIndex = 2;
    } else {
      providerIndex = 3;
    }
    ref.read(homeIndexProvider.notifier).update((state) => providerIndex);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      VersionCheck().checkLastedVersion(context);
    });
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();

    var brightness = View.of(context).platformDispatcher.platformBrightness;

    if (SpUtil.getInt(spLightTheme, defValue: ThemeType.system.index) !=
        ThemeType.system.index) {
      return;
    }

    if (brightness == Brightness.dark) {
      ref.read(themeProvider.notifier).change(ThemeType.system.index);
    } else {
      ref.read(themeProvider.notifier).change(ThemeType.system.index);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentIndex = ref.watch(homeIndexProvider);

    // Navbar hanya icon, tanpa nama. Tengah = mic Ruang Kreasi.
    const navIcons = [
      ChatVectorIcon(),
      LibraryVectorIcon(),
      VoiceVectorIcon(),
      ServerVectorIcon(),
      SettingVectorIcon(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: [
          ClaudeChatScreen(
            navIcons: navIcons,
            navIndex: _toPillIndex(currentIndex),
            onNavTap: _onPillTap,
            embedded: true,
          ),
          const PromptPage(),
          const ServicesPage(),
          const SettingPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          top: currentIndex == 0 ? AppDims.inputGapToNav : 0,
          bottom:
              AppDims.pillBottomGap + MediaQuery.paddingOf(context).bottom,
        ),
        child: FloatingPillNavbar(
          icons: navIcons,
          currentIndex: _toPillIndex(currentIndex),
          onTap: _onPillTap,
        ),
      ),
    );
  }
}
