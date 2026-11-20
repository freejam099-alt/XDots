import 'package:chat_bot/base.dart';
import 'package:chat_bot/module/claude/chat_screen.dart';
import 'package:chat_bot/module/claude/ruang_kreasi.dart';
import 'package:chat_bot/module/services/services_page.dart';
import 'package:chat_bot/module/claude/widgets/floating_nav_layout.dart';
import 'package:chat_bot/module/claude/widgets/vector_icons.dart';
import 'package:chat_bot/module/home/home_viewmodel.dart';

import '../../base/theme.dart';
import '../../const.dart';
import '../prompt/prompt_page.dart';
import '../setting/setting_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  /// Indeks tab = indeks pill: 0 Chat, 1 Prompt, 2 Ruang Kreasi,
  /// 3 Server, 4 Pengaturan.
  void _onPillTap(int index) {
    ref.read(homeIndexProvider.notifier).update((state) => index);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // VersionCheck repo lama dimatikan: menagih update + link
    // Github orang (ChatBot-All), tidak berlaku untuk Ministral.
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
    final int currentIndex = ref.watch(homeIndexProvider);
    final bool kbOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Navbar hanya icon, tanpa nama. Tengah = Ruang Kreasi (bohlam asli).
    const navIcons = [
      ChatVectorIcon(),
      LibraryVectorIcon(),
      MicVectorIcon(),
      ServerVectorIcon(),
      SettingVectorIcon(),
    ];

    return FloatingNavLayout(
      icons: navIcons,
      currentIndex: currentIndex,
      onTap: _onPillTap,
      child: IndexedStack(
        sizing: StackFit.expand,
        index: currentIndex,
        children: [
          ClaudeChatScreen(
            navIcons: navIcons,
            navIndex: currentIndex,
            onNavTap: _onPillTap,
            embedded: true,
            keyboardOpen: kbOpen,
          ),
          const PromptPage(),
          RuangKreasiPage(active: currentIndex == 2),
          const ServicesPage(),
          const SettingPage(),
        ],
      ),
    );
  }
}
