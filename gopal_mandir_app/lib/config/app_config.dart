/// App-wide compile-time configuration flags.
class AppConfig {
  const AppConfig._();

  /// Gates every in-app payment entry point (online donations and online
  /// seva/pooja payment via Razorpay).
  ///
  /// Set to `false` for the initial Play Store release because Razorpay is
  /// not yet configured on the backend. Flip to `true` — and set
  /// `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` on the API — to re-enable
  /// donations and online payments.
  static const bool paymentsEnabled = false;
}
