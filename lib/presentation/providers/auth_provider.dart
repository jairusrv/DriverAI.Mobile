import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/remote/api_client.dart';
import '../../data/datasources/remote/auth_api.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/auth/register_usecase.dart';
import '../../domain/usecases/auth/verify_code_usecase.dart';
import '../../domain/usecases/auth/resend_code_usecase.dart';
import '../../domain/usecases/auth/verify_email_usecase.dart';
import '../../domain/usecases/auth/resend_email_code_usecase.dart';

// Dependencias base
final apiClientProvider = Provider((ref) => ApiClient());
final authApiProvider = Provider((ref) => AuthApi(ref.read(apiClientProvider).dio));
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(ref.read(authApiProvider)));

// UseCases
final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.read(authRepositoryProvider)));
final registerUseCaseProvider = Provider((ref) => RegisterUseCase(ref.read(authRepositoryProvider)));
final verifyCodeUseCaseProvider = Provider((ref) => VerifyCodeUseCase(ref.read(authRepositoryProvider)));
final resendCodeUseCaseProvider = Provider((ref) => ResendCodeUseCase(ref.read(authRepositoryProvider)));
final verifyEmailUseCaseProvider = Provider((ref) => VerifyEmailUseCase(ref.read(authRepositoryProvider)));
final resendEmailCodeUseCaseProvider = Provider((ref) => ResendEmailCodeUseCase(ref.read(authRepositoryProvider)));

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

// Estado de autenticación
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isUnverified;
  final String? errorMessage;
  final Map<String, dynamic>? userData;
  final String? pendingPhoneNumber; // útil para guardar el teléfono temporalmente

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.isUnverified = false,
    this.errorMessage,
    this.userData,
    this.pendingPhoneNumber,
  });

  const AuthState.initial() : this(isLoading: false, isAuthenticated: false);
  const AuthState.loading() : this(isLoading: true, isAuthenticated: false);
  const AuthState.unverified(String phoneNumber) : this(isLoading: false, isAuthenticated: false, isUnverified: true, pendingPhoneNumber: phoneNumber);
  const AuthState.authenticated(Map<String, dynamic> data) : this(isLoading: false, isAuthenticated: true, userData: data);
  const AuthState.error(String message) : this(isLoading: false, isAuthenticated: false, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final VerifyCodeUseCase _verifyCodeUseCase;
  final ResendCodeUseCase _resendCodeUseCase;
  final VerifyEmailUseCase _verifyEmailUseCase;
  final ResendEmailCodeUseCase _resendEmailCodeUseCase;
  final FlutterSecureStorage _secureStorage;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required VerifyCodeUseCase verifyCodeUseCase,
    required ResendCodeUseCase resendCodeUseCase,
    required VerifyEmailUseCase verifyEmailUseCase,
    required ResendEmailCodeUseCase resendEmailCodeUseCase,
    required FlutterSecureStorage secureStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _verifyCodeUseCase = verifyCodeUseCase,
        _resendCodeUseCase = resendCodeUseCase,
        _verifyEmailUseCase = verifyEmailUseCase,
        _resendEmailCodeUseCase = resendEmailCodeUseCase,
        _secureStorage = secureStorage,
        super(const AuthState.initial());

  // Registro
  Future<Map<String, dynamic>?> register({
    required String phoneNumber,
    required String email,
    required String username,
    required String password,
  }) async {
    state = const AuthState.loading();
    final result = await _registerUseCase(
      phoneNumber: phoneNumber,
      email: email,
      username: username,
      password: password,
    );
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return null;
      },
      (data) {
        // data contiene: phoneNumber, email, trialEndDate, etc.
        state = AuthState.unverified(phoneNumber);
        return data;
      },
    );
  }

  // Verificación de email
  Future<bool> verifyEmail(String email, String code) async {
    state = const AuthState.loading();
    final result = await _verifyEmailUseCase(email: email, code: code);
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (data) async {
        // Si la verificación de email completa el proceso (ya no requiere SMS), aquí se guarda el token
        if (data.containsKey('token')) {
          final token = data['token'] as String;
          final user = data['user'] as Map<String, dynamic>;
          await _secureStorage.write(key: 'auth_token', value: token);
          await _secureStorage.write(key: 'user_id', value: user['id'].toString());
          await _secureStorage.write(key: 'phone_number', value: user['phoneNumber']);
          await _secureStorage.write(key: 'email', value: user['email']);
          await _secureStorage.write(key: 'username', value: user['username']);
          state = AuthState.authenticated(data);
          return true;
        } else {
          // Solo se verificó email, falta SMS
          state = AuthState.unverified(state.pendingPhoneNumber ?? '');
          return true;
        }
      },
    );
  }

  // Reenviar código de email
  Future<bool> resendEmailCode(String email) async {
    final result = await _resendEmailCodeUseCase(email);
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (_) => true,
    );
  }

  // Verificación de SMS
  Future<bool> verifyCode(String phoneNumber, String code) async {
    state = const AuthState.loading();
    final result = await _verifyCodeUseCase(phoneNumber: phoneNumber, code: code);
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (data) async {
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        await _secureStorage.write(key: 'auth_token', value: token);
        await _secureStorage.write(key: 'user_id', value: user['id'].toString());
        await _secureStorage.write(key: 'phone_number', value: user['phoneNumber']);
        await _secureStorage.write(key: 'email', value: user['email']);
        await _secureStorage.write(key: 'username', value: user['username']);
        state = AuthState.authenticated(data);
        return true;
      },
    );
  }

  // Reenviar código SMS
  Future<bool> resendCode(String phoneNumber) async {
    final result = await _resendCodeUseCase(phoneNumber);
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (_) => true,
    );
  }

  // Login
  Future<bool> login(String phoneNumber, String password) async {
    state = const AuthState.loading();
    final result = await _loginUseCase(phoneNumber: phoneNumber, password: password);
    return result.fold(
      (failure) {
        state = AuthState.error(failure.message);
        return false;
      },
      (data) async {
        final token = data['token'] as String;
        final user = data['user'] as Map<String, dynamic>;
        await _secureStorage.write(key: 'auth_token', value: token);
        await _secureStorage.write(key: 'user_id', value: user['id'].toString());
        await _secureStorage.write(key: 'phone_number', value: user['phoneNumber']);
        await _secureStorage.write(key: 'email', value: user['email']);
        await _secureStorage.write(key: 'username', value: user['username']);
        state = AuthState.authenticated(data);
        return true;
      },
    );
  }

  // Cierre de sesión
  Future<void> logout() async {
    await _secureStorage.deleteAll();
    state = const AuthState.initial();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.read(loginUseCaseProvider),
    registerUseCase: ref.read(registerUseCaseProvider),
    verifyCodeUseCase: ref.read(verifyCodeUseCaseProvider),
    resendCodeUseCase: ref.read(resendCodeUseCaseProvider),
    verifyEmailUseCase: ref.read(verifyEmailUseCaseProvider),
    resendEmailCodeUseCase: ref.read(resendEmailCodeUseCaseProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});