class UiVerification {
  UiVerification._();

  static const String _routeFromEnvironment =
      String.fromEnvironment('KAZUMI_UI_VERIFICATION_ROUTE');
  static String _routeFromArguments = '';

  static void configure(List<String> args) {
    const prefix = '--kazumi-ui-verification-route=';
    for (final arg in args) {
      if (arg.startsWith(prefix)) {
        _routeFromArguments = arg.substring(prefix.length).trim();
        return;
      }
    }
    _routeFromArguments = '';
  }

  static String get route => _routeFromArguments.isNotEmpty
      ? _routeFromArguments
      : _routeFromEnvironment;

  static bool get isEnabled => route.isNotEmpty;
}
