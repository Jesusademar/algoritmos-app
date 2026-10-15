import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:app_grafos/app/app_theme.dart';
import 'package:app_grafos/shared/help/algorithm_manuals.dart';

Future<void> showAlgorithmManual(
  BuildContext context,
  AlgorithmManual manual, {
  Color accent = AppColors.primary,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Row(
      children: [
        Icon(Icons.menu_book_rounded, color: accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Manual de uso · ${manual.title}',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
    content: SizedBox(
      width: 700,
      height: math.min(620, MediaQuery.sizeOf(context).height * 0.62),
      child: SingleChildScrollView(
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                manual.introduction,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < manual.sections.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              manual.sections[i].title,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.bold,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        manual.sections[i].body,
                        style: const TextStyle(height: 1.6),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.buttonFill(accent),
          foregroundColor: AppColors.text,
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text('¡Entendido!'),
      ),
    ],
  ),
);
