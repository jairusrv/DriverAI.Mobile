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

// ==========================================
// Dependencias base (exportadas para otros providers)
// ==========================================
final apiClientProvider = Provider((ref) => ApiClient());
final authApiProvider = Provider((ref) => AuthApi(ref.read(apiClientProvider).dio));
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(ref.read(authApiProvider)));

// UseCases
final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.read(authRepositoryProvider)));
final registerUseCaseProvider = Provider((ref) => RegisterUseCase(ref.read(authRepositoryProvider)));
final verifyCodeUseCaseProvider = Provider((ref) => VerifyCodeUseCase(ref.read(authRepositoryProvider)));
final resendCodeUseCaseProvider = Provider((ref) => ResendCodeUseCase(ref.read(authRepositoryProvider)));

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

// ==========================================
// Estado de autenticación
// ==========================================
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isUnverified;
  final String? errorMessage;
  final Map<String, dynamic>? userData;

  const AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.isUnverified = false,
    this.errorMessage,
    this.userData,
  });

  const AuthState.initial() : this(isLoading: false, isAuthenticated: false);
  const AuthState.loading() : this(isLoading: true, isAuthenticated: false);
  const AuthState.unverified() : this(isLoading: false, isAuthenticated: false, isUnverified: true);
  const AuthState.authenticated(Map<String, dynamic> data) : this(isLoading: false, isAuthenticated: true, userData: data);
  const AuthState.error(String message) : this(isLoading: false, isAuthenticated: false, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final VerifyCodeUseCase _verifyCodeUseCase;
  final ResendCodeUseCase _resendCodeUseCase;
  final FlutterSecureStorage _secureStorage;

  AuthNotifier({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required VerifyCodeUseCase verifyCodeUseCase,
    required ResendCodeUseCase resendCodeUseCase,
    required FlutterSecureStorage secureStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _verifyCodeUseCase = verifyCodeUseCase,
        _resendCodeUseCase = resendCodeUseCase,
        _secureStorage = secureStorage,
        super(const AuthState.initial());

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
        state = const AuthState.unverified();
        return data;
      },
    );
  }

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
    secureStorage: ref.read(secureStorageProvider),
  );
});