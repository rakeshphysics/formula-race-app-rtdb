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
      'assets/formulas/full_syllabus_online_play_chemistry.aes',
      'assets/formulas/full_syllabus_online_play_maths.aes',
      'assets/formulas/12/solid_state.aes',
      'assets/formulas/12/3d_geometry.aes',
      'assets/formulas/11/chemical_equilibrium.aes',
      'assets/formulas/11/ellipse.aes',
      'assets/formulas/12/definite_integrals.aes',
      'assets/formulas/12/indefinite_integrals.aes',
      'assets/formulas/12/electrochemistry.aes',
      'assets/formulas/11/parabola.aes',
      'assets/formulas/12/solutions.aes',
      'assets/formulas/12/probability.aes',
      'assets/formulas/11/quadratic_equations.aes',
      'assets/formulas/11/atomic_structure.aes',
      'assets/formulas/11/circles.aes',
      'assets/formulas/11/general_organic_chemistry.aes',
      'assets/formulas/11/permutations_and_combinations.aes',
      'assets/formulas/11/hydrocarbons.aes',
      'assets/formulas/11/hyperbola.aes',
      'assets/formulas/11/sequence_and_series.aes',
      'assets/formulas/12/haloalkanes_and_haloarenes.aes',
      'assets/formulas/12/alcohols_phenols_and_ethers.aes',
      'assets/formulas/12/aldehydes_and_ketones.aes',
      'assets/formulas/12/carboxylic_acids.aes',
      'assets/formulas/12/amines.aes',
      'assets/formulas/12/biomolecules.aes',
      'assets/formulas/11/basic_concepts_of_chemistry.aes',
      'assets/formulas/11/classification_of_elements.aes',
      'assets/formulas/11/chemical_bonding.aes',
      'assets/formulas/11/thermodynamics_chem.aes',
      'assets/formulas/11/redox_reactions.aes',
      'assets/formulas/11/p_block_13_and_14.aes',
      'assets/formulas/12/p_block_15_to_18.aes',
      'assets/formulas/12/d_and_f_block.aes',
      'assets/formulas/12/coordination_compounds.aes',
      'assets/formulas/12/practical_chemistry.aes',
      'assets/formulas/12/functions.aes',
      'assets/formulas/11/complex_numbers.aes',
      'assets/formulas/11/binomial_theorem.aes',

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