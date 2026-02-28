// encrypt_script.dart
import 'dart:io';
import 'package:encrypt/encrypt.dart';

void main() {
  // IMPORTANT: Generate these once and save them securely.
  final key = Key.fromBase64('Iab5jYKlQgdOQYahIR3ufnX6M21LHuAlZw76xXhM9Tc=');
  final iv = IV.fromBase64('xjToKjJYezgw5We19wY9Ow==');

 // print('Your encryption Key: ${key.base64}');
 // print('Your encryption IV: ${iv.base64}');

  // Define the base directory where your JSON files are located
  const String baseDir = 'assets/formulas/';

  // List all your JSON file paths here
  final jsonFiles = [
    '${baseDir}11/center_of_mass.json',
    '${baseDir}11/circular_motion.json',
    '${baseDir}11/elasticity.json',
    '${baseDir}11/fluids.json',
    '${baseDir}11/gravitation.json',
    '${baseDir}11/kinematics.json',
    '${baseDir}11/kinetic_theory.json',
    '${baseDir}11/laws_of_motion.json',
    '${baseDir}11/rotational_motion.json',
    '${baseDir}11/shm.json',
    '${baseDir}11/thermodynamics.json',
    '${baseDir}11/units_and_dimensions.json',
    '${baseDir}11/vectors.json',
    '${baseDir}11/waves.json',
    '${baseDir}11/work_power_energy.json',
    '${baseDir}12/ac.json',
    '${baseDir}12/capacitors.json',
    '${baseDir}12/current_electricity.json',
    '${baseDir}12/electrostatics.json',
    '${baseDir}12/em_waves.json',
    '${baseDir}12/emi.json',
    '${baseDir}12/magnetism.json',
    '${baseDir}12/dual_nature_of_light.json',
    '${baseDir}12/atoms.json',
    '${baseDir}12/nuclei.json',
    '${baseDir}12/x_rays.json',
    '${baseDir}12/ray_optics.json',
    '${baseDir}12/semiconductors.json',
    '${baseDir}12/wave_optics.json',
    '${baseDir}full_syllabus_online_play.json',
    '${baseDir}full_syllabus_online_play_maths.json',
    '${baseDir}full_syllabus_online_play_chemistry.json',
    '${baseDir}12/solid_state.json',
    '${baseDir}12/3d_geometry.json',
    '${baseDir}11/chemical_equilibrium.json',
    '${baseDir}11/ellipse.json',
    '${baseDir}12/definite_integrals.json',
    '${baseDir}12/indefinite_integrals.json',
    '${baseDir}12/electrochemistry.json',
    '${baseDir}11/parabola.json',
    '${baseDir}12/solutions.json',
    '${baseDir}12/probability.json',
    '${baseDir}11/quadratic_equations.json',
    '${baseDir}11/atomic_structure.json',
    '${baseDir}11/circles.json',
    '${baseDir}11/general_organic_chemistry.json',
    '${baseDir}11/permutations_and_combinations.json',
    '${baseDir}11/hydrocarbons.json',
    '${baseDir}11/hyperbola.json',
    '${baseDir}11/sequence_and_series.json',
    '${baseDir}12/haloalkanes_and_haloarenes.json',
    '${baseDir}12/alcohols_phenols_and_ethers.json',
    '${baseDir}12/aldehydes_and_ketones.json',
    '${baseDir}12/carboxylic_acids.json',
    '${baseDir}12/amines.json',
    '${baseDir}12/biomolecules.json',
    '${baseDir}11/basic_concepts_of_chemistry.json',
    '${baseDir}11/classification_of_elements.json',
    '${baseDir}11/chemical_bonding.json',
    '${baseDir}11/thermodynamics_chem.json',
    '${baseDir}11/redox_reactions.json',
    '${baseDir}11/p_block_13_and_14.json',
    '${baseDir}12/p_block_15_to_18.json',
    '${baseDir}12/d_and_f_block.json',
    '${baseDir}12/coordination_compounds.json',
    '${baseDir}12/practical_chemistry.json',
    '${baseDir}12/functions.json',
    '${baseDir}11/complex_numbers.json',
    '${baseDir}11/binomial_theorem.json',
    '${baseDir}11/trigonometry.json',
    '${baseDir}11/straight_lines.json',
    '${baseDir}11/limits.json',
    '${baseDir}11/statistics.json',
    '${baseDir}12/sets_and_relations.json',
    '${baseDir}12/matrices.json',
    '${baseDir}12/determinants.json',
    '${baseDir}12/inverse_trigonometric_functions.json',
    '${baseDir}12/differentiation.json',
    '${baseDir}12/differential_equations.json',
    '${baseDir}12/application_of_derivatives.json',
    '${baseDir}12/area_under_curves.json',
  ];

  final encrypter = Encrypter(AES(key));

  for (var filePath in jsonFiles) {
    try {
      final jsonData = File(filePath).readAsStringSync();
      final encrypted = encrypter.encrypt(jsonData, iv: iv);
      final encryptedFilePath = filePath.replaceAll('.json', '.aes');
      File(encryptedFilePath).writeAsStringSync(encrypted.base64);
      //print('Encryption complete for: $filePath -> $encryptedFilePath');
    } catch (e) {
     /// print('Error encrypting $filePath: $e');
    }
  }
}