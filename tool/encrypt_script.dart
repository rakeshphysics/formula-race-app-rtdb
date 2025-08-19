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
    '${baseDir}12/ray_optics.json',
    '${baseDir}12/semiconductors.json',
    '${baseDir}12/wave_optics.json',
    '${baseDir}full_syllabus_online_play.json',
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