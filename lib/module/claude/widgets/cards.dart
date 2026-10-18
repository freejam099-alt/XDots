import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../chat_data.dart';
import 'file_icon.dart';

Uri? webActionUri(String? value) {
  final Uri? uri = Uri.tryParse(value ?? '');
  return uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty
      ? uri
      : null;
}

Future<void> openWebAction(BuildContext context, String? value) async {
  final Uri? uri = webActionUri(value);
  if (uri == null) return;
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
  } catch (_) {
    // A failed launch must never appear as a completed browser action.
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tautan tidak dapat dibuka.')),
  );
}

/// Membaca hanya potongan awal berkas, bukan seluruh berkas ke memori.
Future<String?> readFileExcerpt(MsgAttachment attachment) async {
  const Set<String> textExtensions = {
    'txt',
    'md',
    'markdown',
    'json',
    'xml',
    'yaml',
    'yml',
    'csv',
    'log',
    'html',
    'htm',
    'css',
    'js',
    'ts',
    'dart',
    'py',
    'java',
    'kt',
    'c',
    'h',
    'cpp',
    'sh',
    'sql',
    'ini',
    'toml',
  };
  if (!textExtensions.contains(attachment.name.split('.').last.toLowerCase())) {
    return null;
  }
  RandomAccessFile? handle;
  try {
    handle = await File(attachment.path).open();
    final List<int> bytes = await handle.read(8192);
    final bool truncated = await handle.length() > bytes.length;
    final String text = utf8.decode(bytes, allowMalformed: true);
    return '$text${truncated ? '\n\n… Pratinjau dibatasi 8 KB.' : ''}';
  } catch (_) {
    return 'Berkas tidak tersedia di perangkat ini.';
  } finally {
    await handle?.close();
  }
}

Future<void> showAttachmentPreview(
    BuildContext context, MsgAttachment attachment) {
  final AppColors c = AppColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                FileIconImage(filename: attachment.name, size: 36),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(attachment.name,
                        style: TextStyle(color: c.textPrimary, fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: c.textMuted)),
              ]),
              const SizedBox(height: 16),
              Flexible(
                child: attachment.kind == 0 || attachment.kind == 1
                    ? Image.file(File(attachment.path),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Text('Gambar tidak tersedia.'))
                    : FutureBuilder<String?>(
                        future: readFileExcerpt(attachment),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator());
                          }
                          return SingleChildScrollView(
                            child: SelectableText(
                              snapshot.data ??
                                  'Pratinjau format ini belum didukung. Isi berkas tidak ditampilkan.',
                              style: TextStyle(
                                  color: c.textPrimary,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontFamily: AppDims.fontFamily),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Kartu berkas nyata; tidak mengarang judul, format atau isi dokumen.
class FileCard extends StatelessWidget {
  final String title;
  final List<MsgAttachment> attachments;
  const FileCard({super.key, required this.title, this.attachments = const []});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return _CardSurface(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(title,
                  style: TextStyle(fontSize: 16, color: c.textPrimary))),
        if (attachments.isEmpty)
          Text('Tidak ada berkas terlampir.',
              style: TextStyle(color: c.textMuted)),
        for (final MsgAttachment attachment in attachments)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: FileIconImage(filename: attachment.name, size: 42),
            title: Text(attachment.name,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: const Text('Lihat pratinjau berkas'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => showAttachmentPreview(context, attachment),
          ),
      ],
    ));
  }
}

/// Permintaan ini aktif hanya bila masih ada callback backend yang menunggu.
class CheckoutCard extends StatelessWidget {
  final String? domain;
  final String? total;
  final String summary;
  final String? actionUrl;
  final String? previewImage;
  final ApprovalStatus status;
  final VoidCallback? onAllow;
  final VoidCallback? onDeny;
  const CheckoutCard(
      {super.key,
      this.domain,
      this.total,
      this.summary = '',
      this.actionUrl,
      this.previewImage,
      this.status = ApprovalStatus.expired,
      this.onAllow,
      this.onDeny});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final bool active =
        status == ApprovalStatus.pending && onAllow != null && onDeny != null;
    final String label = active
        ? 'Menunggu persetujuan'
        : switch (status) {
            ApprovalStatus.approved => 'Disetujui',
            ApprovalStatus.denied => 'Ditolak',
            _ => 'Permintaan tidak aktif',
          };
    return _CardSurface(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.verified_user_outlined, color: c.accent),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary))),
        ]),
        if (domain != null && domain!.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(domain!, style: TextStyle(color: c.textMuted))),
        if (summary.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(summary,
                  style: TextStyle(color: c.textPrimary, height: 1.4))),
        if (webActionUri(previewImage) != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _WebPreview(url: previewImage!)),
        if (webActionUri(actionUrl) != null)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                  onPressed: () => openWebAction(context, actionUrl),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Tinjau detail'))),
        if (total != null && total!.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(spacing: 12, runSpacing: 6, children: [
                Text('Estimasi total', style: TextStyle(color: c.textMuted)),
                Text(total!,
                    style: TextStyle(
                        color: c.textPrimary, fontWeight: FontWeight.w600)),
              ])),
        if (active) ...[
          const SizedBox(height: 12),
          Text('Periksa detail dan ketentuan sebelum mengizinkan tindakan ini.',
              style: TextStyle(fontSize: 13, height: 1.4, color: c.textMuted)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: c.btnSecondary,
                        foregroundColor: c.textPrimary,
                        minimumSize: const Size(0, 48),
                        shape: const StadiumBorder()),
                    onPressed: onDeny,
                    child: const Text('Tolak'))),
            const SizedBox(width: 10),
            Expanded(
                child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: c.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: const StadiumBorder()),
                    onPressed: onAllow,
                    child: const Text('Izinkan'))),
          ]),
        ],
      ],
    ));
  }
}

/// Browser ditampilkan hanya dari event nyata, tanpa kursi atau halaman simulasi.
class BrowserCard extends StatelessWidget {
  final String detail;
  final String? url;
  final String? previewImage;
  const BrowserCard({super.key, this.detail = '', this.url, this.previewImage});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    final Uri? uri = webActionUri(url);
    return _CardSurface(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: c.globeBox, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.public, color: c.globeIcon)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(uri?.host ?? 'Browser',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600))),
        ]),
        if (detail.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(detail,
                  style: TextStyle(color: c.textMuted, height: 1.4))),
        if (webActionUri(previewImage) != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _WebPreview(url: previewImage!)),
        if (uri != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                      onPressed: () => openWebAction(context, url),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Buka browser')))),
      ],
    ));
  }
}

class _WebPreview extends StatelessWidget {
  final String url;
  const _WebPreview({required this.url});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(url,
            width: double.infinity,
            height: 170,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Pratinjau tidak tersedia.',
                    style: TextStyle(color: AppColors.of(context).textMuted)))),
      );
}

class _CardSurface extends StatelessWidget {
  final Widget child;
  const _CardSurface({required this.child});
  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [c.shadowFloat]),
        child: child);
  }
}
