import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 1) File card (PDF): full width, radius 26.
class FileCard extends StatelessWidget {
  final String title;
  const FileCard({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.aiBubble,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Icon(Icons.description_outlined,
                  size: 40, color: c.textMuted),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.pdfRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('PDF',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: AppDims.chatFontSize,
                            color: c.textPrimary)),
                    Text('PDF',
                        style: TextStyle(
                            fontSize: 13, color: c.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: c.textMuted),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2) Checkout card.
class CheckoutCard extends StatelessWidget {
  final String domain;
  final String total;
  final VoidCallback? onAllow;
  final VoidCallback? onDeny;
  const CheckoutCard({
    super.key,
    required this.domain,
    required this.total,
    this.onAllow,
    this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [c.shadowFloat],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  color: c.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Checkout · Muse wants to place an order at $domain',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: c.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please review the order before approving.',
            style: TextStyle(fontSize: 15, color: c.textMuted),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.surfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(Icons.storefront_outlined,
                      size: 48, color: c.textMuted),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                          radius: 10,
                          backgroundColor: c.surfaceSoft,
                          child: Text('M',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: c.textPrimary))),
                      SizedBox(width: 6),
                      Text('Review order',
                          style: TextStyle(
                              fontSize: 13, color: c.textPrimary)),
                      SizedBox(width: 4),
                      Icon(Icons.open_in_full,
                          size: 14, color: c.textPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('VISA',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Credit Card •••• 1234',
                          style: TextStyle(
                              fontSize: AppDims.chatFontSize,
                              color: c.textPrimary)),
                      Row(
                        children: [
                          Icon(Icons.circle,
                              size: 8, color: c.linkGreen),
                          SizedBox(width: 4),
                          Text('Pay with Link',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: c.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: c.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Estimated total',
                  style: TextStyle(
                      fontSize: 15, color: c.textMuted)),
              Text(total,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: c.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 9,
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: c.btnSecondary,
                      foregroundColor: c.textPrimary,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: onDeny,
                    child: const Text('Deny'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 11,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      c.accent,
                      c.accentEnd
                    ]),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: onAllow,
                    child: const Text('Allow',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3) Browser card: seat picker.
class BrowserCard extends StatefulWidget {
  const BrowserCard({super.key});

  @override
  State<BrowserCard> createState() => _BrowserCardState();
}

class _BrowserCardState extends State<BrowserCard> {
  final Set<int> _selected = {14};

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.aiBubble,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F0FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.public,
                    color: c.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Browser',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary)),
                    Text('Selecting seats...',
                        style: TextStyle(
                            fontSize: 13, color: c.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('SCREEN',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: c.textMuted)),
                const SizedBox(height: 6),
                Container(
                    height: 4,
                    decoration: BoxDecoration(
                        color: c.seatAvailable,
                        borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 10),
                Column(
                  children: List.generate(6, (row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 16,
                            child: Text(
                                String.fromCharCode(65 + row),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: c.textMuted)),
                          ),
                          Expanded(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 11,
                                mainAxisSpacing: 5,
                                crossAxisSpacing: 5,
                              ),
                              itemCount: 11,
                              itemBuilder: (context, col) {
                                final int idx = row * 11 + col;
                                final bool taken = (idx % 9 == 4);
                                final bool sel =
                                    _selected.contains(idx);
                                final Color seat = sel
                                    ? c.seatSelected
                                    : (taken
                                        ? c.seatTaken
                                        : c.seatAvailable);
                                return GestureDetector(
                                  onTap: taken
                                      ? null
                                      : () => setState(() {
                                            if (sel) {
                                              _selected.remove(idx);
                                            } else {
                                              _selected.add(idx);
                                            }
                                          }),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: seat,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: seat,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legend(
                        color: c.seatAvailable,
                        label: 'Available'),
                    SizedBox(width: 12),
                    _Legend(
                        color: c.seatTaken, label: 'Taken'),
                    SizedBox(width: 12),
                    _Legend(
                        color: c.seatSelected,
                        label: 'Selected'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 48,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text('Open browser',
                  style: TextStyle(
                      fontSize: 15, color: c.textPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final AppColors c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: c.textMuted)),
      ],
    );
  }
}
