import 'package:flutter/material.dart';

/// Memetakan nama file ke PNG perwakilan di assets/file_icons/
/// (disalin dari folder School di perangkat).
String fileIconAsset(String filename) {
  final List<String> parts = filename.split('.');
  final String ext =
      parts.length > 1 ? parts.last.toLowerCase() : '';
  switch (ext) {
    case 'pdf':
      return 'assets/file_icons/ic_file_pdf.png';
    case 'doc':
    case 'docx':
      return 'assets/file_icons/ic_file_docx.png';
    case 'ppt':
    case 'pptx':
      return 'assets/file_icons/ic_file_pptx_v2.png';
    case 'md':
    case 'markdown':
    case 'txt':
      return 'assets/file_icons/ic_file_markdown.png';
    case 'html':
    case 'htm':
    case 'css':
    case 'js':
      return 'assets/file_icons/ic_file_html_css_javascript.png';
    case 'xml':
    case 'json':
    case 'py':
    case 'java':
    case 'kt':
    case 'dart':
    case 'cpp':
    case 'c':
    case 'h':
    case 'sh':
    case 'ts':
      return 'assets/file_icons/ic_code_xml.png';
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'bmp':
      return 'assets/file_icons/ic_png_jpg_dll.png';
    default:
      return 'assets/file_icons/ic_file_docx.png';
  }
}

/// Gambar perwakilan file (dengan fallback bila asset hilang).
class FileIconImage extends StatelessWidget {
  final String filename;
  final double size;
  const FileIconImage({super.key, required this.filename, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      fileIconAsset(filename),
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.insert_drive_file_outlined, size: size);
      },
    );
  }
}
