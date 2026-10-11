import 'package:chat_bot/hive_bean/openai_bean.dart';
import 'package:chat_bot/hive_bean/supported_models.dart';
import 'package:chat_bot/utils/hive_box.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../utils/extension_string.dart';
import 'app_theme.dart';
import 'model_store.dart';

class _FetchedModel {
  final String id;
  final String provider;
  const _FetchedModel(this.id, this.provider);
}

/// Kelola model: Fetch (dari konfigurasi provider tersimpan,
/// dengan animasi) dan Manual (isi sendiri nama model).
/// Setiap baris menampilkan nama + ID + tombol + (tambahkan).
class ModelFetchPage extends StatefulWidget {
  const ModelFetchPage({super.key});

  @override
  State<ModelFetchPage> createState() => _ModelFetchPageState();
}

class _ModelFetchPageState extends State<ModelFetchPage> {
  final TextEditingController _manualController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey =
      GlobalKey<AnimatedListState>();
  final List<_FetchedModel> _models = [];
  bool _fetching = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    setState(() => _fetching = true);
    // Jeda singkat agar animasi loading terlihat (motion).
    await Future.delayed(const Duration(milliseconds: 700));
    final List<_FetchedModel> found = [];
    for (final AllModelBean bean in HiveBox().openAIConfig.values) {
      final List<SupportedModels> list = bean.supportedModels ?? [];
      for (final SupportedModels m in list) {
        if (m.id == null || m.id!.isEmpty) continue;
        found.add(_FetchedModel(
            m.id!, bean.alias ?? m.ownedBy ?? 'Server'));
      }
    }
    if (!mounted) return;
    setState(() => _fetching = false);
    for (final _FetchedModel m in found) {
      if (_models.any((e) => e.id == m.id)) continue;
      _models.add(m);
      _listKey.currentState?.insertItem(
        _models.length - 1,
        duration: const Duration(milliseconds: 220),
      );
    }
    if (found.isEmpty && mounted) {
      'Belum ada konfigurasi server. Tambah manual.'.toast();
    }
  }

  void _addManual() {
    final String name = _manualController.text.trim();
    if (name.isEmpty) return;
    ModelStore.addManualModel(name);
    _manualController.clear();
    if (_models.any((e) => e.id == name)) return;
    setState(() => _models.add(_FetchedModel(name, 'Manual')));
    _listKey.currentState?.insertItem(
      _models.length - 1,
      duration: const Duration(milliseconds: 220),
    );
  }

  void _plus(_FetchedModel m) {
    // + = tambahkan ke kandidat Ruang Kreasi.
    ModelStore.addManualModel(m.id);
    'Ditambahkan: ${m.id}'.success();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(Icons.arrow_back,
              color: c.textPrimary),
        ),
        title: Text(
          'Kelola Model',
          style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: DefaultTextStyle(
        style: const TextStyle(fontFamily: AppDims.fontFamily),
        child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDims.screenPaddingH),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _fetching ? null : _fetch,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          c.accent,
                          c.accentEnd
                        ]),
                        borderRadius:
                            BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: _fetching
                            ? LoadingAnimationWidget
                                .prograssiveDots(
                                color: Colors.white,
                                size: 32,
                              )
                            : const Text('Fetch',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600,
                                    fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius:
                          BorderRadius.circular(999),
                      boxShadow: const [
                        c.shadowFloat
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _manualController,
                        style: TextStyle(
                            fontSize: 16,
                            color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText:
                              'Manual (isi sendiri nama model)',
                          hintStyle: TextStyle(
                              fontSize: 15,
                              color: c.textHint),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _addManual(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addManual,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.btnSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add,
                        color: c.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _fetching && _models.isEmpty
                  ? Center(
                      child: LoadingAnimationWidget
                          .prograssiveDots(
                        color: c.accent,
                        size: 48,
                      ),
                    )
                  : AnimatedList(
                      key: _listKey,
                      padding:
                          const EdgeInsets.only(bottom: 24),
                      initialItemCount: _models.length,
                      itemBuilder: (context, i, animation) {
                        final _FetchedModel m = _models[i];
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic)),
                            child: Container(
                              margin: const EdgeInsets.only(
                                  bottom: 8),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 11),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius:
                                    BorderRadius.circular(
                                        22),
                                boxShadow: const [
                                  c.shadowFloat
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(m.id,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                color: c
                                                    .textPrimary)),
                                        Text(
                                          'ID: ${m.id} · ${m.provider}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: c
                                                  .textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow
                                              .ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior:
                                        HitTestBehavior.opaque,
                                    onTap: () => _plus(m),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration:
                                          BoxDecoration(
                                        color: c
                                            .btnSecondary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                          Icons.add,
                                          color: c
                                              .textPrimary),
                                    ),
                                  ),
                                ],
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
          ),
    );
  }
}
