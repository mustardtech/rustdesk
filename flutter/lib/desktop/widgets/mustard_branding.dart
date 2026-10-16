import 'package:flutter/material.dart';

import '../../common.dart';

bool get isMustardClient =>
    appName == 'MustardSupport' || appName == 'MustardRemote';

String get mustardDisplayName =>
    appName == 'MustardSupport' ? 'Mustard Support' : 'Mustard Remote';

class MustardBranding extends StatelessWidget {
  const MustardBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFD7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDAC5B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.support_agent, color: Color(0xFF535B4D)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mustardDisplayName,
              style: const TextStyle(
                color: Color(0xFF535B4D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
