import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/widgets/neon_icon.dart';

/// Tarjeta de acceso con estados visibles para ratón y teclado.
class AlgorithmLaunchCard extends StatefulWidget {
  const AlgorithmLaunchCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.category,
    this.preview,
    this.actionLabel = 'Abrir módulo',
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final String? category;
  final Widget? preview;
  final String actionLabel;

  @override
  State<AlgorithmLaunchCard> createState() => _AlgorithmLaunchCardState();
}

class _AlgorithmLaunchCardState extends State<AlgorithmLaunchCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _focused;
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              widget.accent.withValues(alpha: active ? 0.19 : 0.10),
              AppColors.surface,
            ),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppLayout.radius),
        border: Border.all(
          color: active ? widget.accent : widget.accent.withValues(alpha: 0.28),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: active ? 0.16 : 0.04),
            blurRadius: active ? 28 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppLayout.radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => _hovered = value),
          onFocusChange: (value) => setState(() => _focused = value),
          splashColor: widget.accent.withValues(alpha: 0.12),
          highlightColor: widget.accent.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AnimatedScale(
                      scale: active ? 1.07 : 1,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: NeonIcon(
                        icon: widget.icon,
                        accent: widget.accent,
                        size: 25,
                      ),
                    ),
                    if (widget.category != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: widget.accent.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Text(
                              widget.category!,
                              style: TextStyle(
                                color: widget.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.preview != null) ...[
                  const SizedBox(height: 20),
                  widget.preview!,
                ],
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                const Spacer(),
                Divider(
                  height: 1,
                  color: widget.accent.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.actionLabel,
                        style: TextStyle(
                          color: widget.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.accent,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
