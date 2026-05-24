class Validators {
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    if (value.length != 8) return '8 dígitos';
    if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) return 'Solo números';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email inválido';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    if (value.length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}