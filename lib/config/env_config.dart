enum Environment { dev, staging, prod }

class EnvConfig {
  final Environment environment;
  final String apiUrl;
  final bool enableLogging;

  EnvConfig({
    required this.environment,
    required this.apiUrl,
    required this.enableLogging,
  });

  static EnvConfig? _instance;

  static EnvConfig get instance {
    _instance ??= EnvConfig._getConfig(Environment.dev);
    return _instance!;
  }

  static void initialize(Environment env) {
    _instance = EnvConfig._getConfig(env);
  }

  factory EnvConfig._getConfig(Environment env) {
    switch (env) {
      case Environment.dev:
        return EnvConfig(
          environment: env,
          apiUrl: 'https://dev-api.example.com',
          enableLogging: true,
        );
      case Environment.staging:
        return EnvConfig(
          environment: env,
          apiUrl: 'https://staging-api.example.com',
          enableLogging: true,
        );
      case Environment.prod:
        return EnvConfig(
          environment: env,
          apiUrl: 'https://api.example.com',
          enableLogging: false,
        );
    }
  }

  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;
}