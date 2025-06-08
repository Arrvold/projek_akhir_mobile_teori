import 'package:flutter/material.dart';
import '../../../data/sources/local/database_helper.dart'; 
import '../../../data/sources/local/preferences_helper.dart'; 
import '../../../core/utils/encryption_helper.dart'; 
import '../../../data/models/user_model.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  // Fungsi "Remember Me" dan username
  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    bool rememberedStatus = prefs.getBool('rememberMeStatus') ?? false;
    String rememberedUsername = prefs.getString('rememberedUsername') ?? '';

    if (rememberedStatus && rememberedUsername.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _usernameController.text = rememberedUsername;
      });
    }
  }

  // Fungsi menyimpan status "Remember Me"
  Future<void> _saveRememberMeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMeStatus', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('rememberedUsername', _usernameController.text.trim());
    } else {
      await prefs.remove('rememberedUsername'); 
    }
  }


  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      String username = _usernameController.text.trim();
      String password = _passwordController.text;
      UserModel? user = await DatabaseHelper.instance.getUserByUsername(username);
      if (!mounted) return;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Username tidak ditemukan.'),
              backgroundColor: Colors.redAccent),
        );
        setState(() { _isLoading = false; });
        return;
      }
      bool isPasswordCorrect = await EncryptionHelper.verifyPassword(password, user.passwordHash);
      if (!mounted) return;
      if (!isPasswordCorrect) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password salah.'), backgroundColor: Colors.redAccent),
        );
        setState(() { _isLoading = false; });
        return;
      }
      if (user.id == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Terjadi kesalahan: ID pengguna tidak ditemukan.'), backgroundColor: Colors.redAccent),
          );
          setState(() { _isLoading = false; });
          return;
      }
      await PreferencesHelper.saveUserSession(user.id!, user.username);
      await _saveRememberMeStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Login berhasil! Selamat datang, ${user.username}.'),
            backgroundColor: Colors.green),
      );
      
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
    if (mounted && _isLoading && Navigator.canPop(context) == false ) {
         setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // FlutterLogo(size: 80),
                  // SizedBox(height: 30),
                  Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please Sign in to continue.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _rememberMe = value;
                                });
                              }
                            },
                            activeColor: Theme.of(context).primaryColor,
                            visualDensity: VisualDensity.compact,
                          ),
                          GestureDetector(
                            onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                            },
                            child: const Text('Remember me')
                          ),
                        ],
                      ),
                      // TextButton(
                      //   onPressed: () {
                      //     // Logika Lupa Password (jika ada)
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('Fitur Lupa Password belum tersedia.')),
                      //     );
                      //   },
                      //   child: const Text('Forgot Password?'),
                      // ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text('Sign In'),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}