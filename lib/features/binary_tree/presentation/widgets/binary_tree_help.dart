import 'package:flutter/material.dart';

import 'package:app_grafos/shared/help/algorithm_manuals.dart';
import 'package:app_grafos/shared/widgets/algorithm_manual_dialog.dart';

Future<void> showBinaryTreeHelp(BuildContext context) =>
    showAlgorithmManual(context, AlgorithmManual.binaryTree);
