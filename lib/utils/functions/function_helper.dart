import 'package:do_not_disturb/do_not_disturb.dart';


bool isPasswordValid(String password) {
  // Check if password is at least 6 characters long
  if (password.length < 6) {
    return false;
  }

  // Check for at least one letter
  if (!password.contains(RegExp(r'[a-zA-Z]'))) {
    return false;
  }

  // Check for at least one digit
  if (!password.contains(RegExp(r'\d'))) {
    return false;
  }

  // Check for at least one special character
  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    return false;
  }

  // If all checks pass, the password is valid
  return true;
}

bool isValidEmail(String email) {
  const pattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
  final regex = RegExp(pattern);
  return regex.hasMatch(email);
}

