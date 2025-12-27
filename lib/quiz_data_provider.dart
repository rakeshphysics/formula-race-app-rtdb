// lib/quiz_data_provider.dart
import 'package:flutter/material.dart';
import 'package:formularacing/decrypt_utility.dart';
import 'dart:convert';

class QuizDataProvider extends ChangeNotifier {
  Map<String, dynamic> _allQuizData = {};
  bool _isLoading = true;

  Map<String, dynamic> get allQuizData => _allQuizData;
  bool get isLoading => _isLoading;

  Future<void> loadAllQuizData() async {
    // List all your encrypted files here
    final encryptedFiles = [
      'assets/formulas/11/center_of_mass.aes',
      'assets/formulas/11/circular_motion.aes',
      'assets/formulas/11/elasticity.aes',
      'assets/formulas/11/fluids.aes',
      'assets/formulas/11/gravitation.aes',
      'assets/formulas/11/kinematics.aes',
      'assets/formulas/11/kinetic_theory.aes',
      'assets/formulas/11/laws_of_motion.aes',
      'assets/formulas/11/rotational_motion.aes',
      'assets/formulas/11/shm.aes',
      'assets/formulas/11/thermodynamics.aes',
      'assets/formulas/11/units_and_dimensions.aes',
      'assets/formulas/11/vectors.aes',
      'assets/formulas/11/waves.aes',
      'assets/formulas/11/work_power_energy.aes',
      'assets/formulas/12/ac.aes',
      'assets/formulas/12/capacitors.aes',
      'assets/formulas/12/current_electricity.aes',
      'assets/formulas/12/electrostatics.aes',
      'assets/formulas/12/em_waves.aes',
      'assets/formulas/12/emi.aes',
      'assets/formulas/12/magnetism.aes',
      'assets/formulas/12/dual_nature_of_light.aes',
      'assets/formulas/12/atoms.aes',
      'assets/formulas/12/nuclei.aes',
      'assets/formulas/12/x_rays.aes',
      'assets/formulas/12/ray_optics.aes',
      'assets/formulas/12/semiconductors.aes',
      'assets/formulas/12/wave_optics.aes',
      'assets/formulas/full_syllabus_online_play.aes',
      'assets/formulas/12/solid_state.aes',
      'assets/formulas/12/3d_geometry.aes',
      'assets/formulas/11/chemical_equilibrium.aes',
    ];

    for (var filePath in encryptedFiles) {
      String decryptedData = await decryptFile(filePath);
      String keyName = filePath.split('/').last.split('.').first;
      _allQuizData[keyName] = jsonDecode(decryptedData);
    }

    _isLoading = false;
    notifyListeners();
  }
}