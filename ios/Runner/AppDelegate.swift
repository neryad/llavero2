import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerSecureFileChannel(with: engineBridge.pluginRegistry)
    registerScreenSecurityChannel(with: engineBridge.pluginRegistry)
    registerDeviceIntegrityChannel(with: engineBridge.pluginRegistry)
  }

  /// Señales informativas de jailbreak. Un atacante puede ocultarlas,
  /// así que solo sirve para avisar al usuario, nunca como barrera.
  private func registerDeviceIntegrityChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "LlaveroDeviceIntegrity") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "llavero/device_integrity",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "isCompromised":
        result(Self.isJailbroken())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func isJailbroken() -> Bool {
    let suspiciousPaths = [
      "/Applications/Cydia.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib",
      "/bin/bash",
      "/usr/sbin/sshd",
      "/etc/apt",
      "/private/var/lib/apt/"
    ]
    for path in suspiciousPaths where FileManager.default.fileExists(atPath: path) {
      return true
    }
    // Si la app puede escribir fuera de su sandbox, el sandbox está roto.
    let probe = "/private/llavero_jb_probe_\(UUID().uuidString)"
    do {
      try "probe".write(toFile: probe, atomically: true, encoding: .utf8)
      try FileManager.default.removeItem(atPath: probe)
      return true
    } catch {
      return false
    }
  }

  /// Canal nativo que oculta la interfaz cuando se detecta una captura o una
  /// grabación de pantalla (iOS no permite bloquearlas como Android con
  /// FLAG_SECURE, pero sí oscurecer la ventana en cuanto ocurren).
  private func registerScreenSecurityChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "LlaveroScreenSecurity") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "llavero/screen_security",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "setScreenshotsBlocked":
        let args = call.arguments as? [String: Any]
        let blocked = args?["blocked"] as? Bool ?? true
        self?.setScreenshotsBlocked(blocked)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private var securityOverlay: UIView?
  private var screenshotObserver: NSObjectProtocol?
  private var captureObserver: NSObjectProtocol?

  private func keyWindow() -> UIWindow? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }
    }
    return UIApplication.shared.keyWindow
  }

  private func setScreenshotsBlocked(_ blocked: Bool) {
    guard let window = keyWindow() else { return }

    if !blocked {
      securityOverlay?.removeFromSuperview()
      securityOverlay = nil
      if let screenshotObserver { NotificationCenter.default.removeObserver(screenshotObserver) }
      if let captureObserver { NotificationCenter.default.removeObserver(captureObserver) }
      screenshotObserver = nil
      captureObserver = nil
      return
    }

    guard securityOverlay == nil else { return }

    let overlay = UIView(frame: window.bounds)
    overlay.backgroundColor = UIColor.black
    overlay.autoresizingMask = [
      UIView.AutoresizingMask.flexibleWidth,
      UIView.AutoresizingMask.flexibleHeight,
    ]
    overlay.isHidden = true
    window.addSubview(overlay)
    securityOverlay = overlay

    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.flashOverlay()
    }
    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      guard let screen = notification.object as? UIScreen else { return }
      self?.securityOverlay?.isHidden = !screen.isCaptured
    }
  }

  private func flashOverlay() {
    securityOverlay?.isHidden = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.securityOverlay?.isHidden = true
    }
  }

  /// Canal nativo para los detalles de seguridad del archivo de la bóveda.
  ///
  /// Ahora mismo solo hace una cosa: decirle a iOS que el archivo de la
  /// bóveda NO se copie a iCloud. (En Android esto ya está resuelto en el
  /// manifiesto con `android:allowBackup="false"`.)
  private func registerSecureFileChannel(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "LlaveroSecureFile") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "llavero/secure_file",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "excludeFromBackup":
        guard let path = call.arguments as? String else {
          result(
            FlutterError(
              code: "bad_arguments",
              message: "Falta la ruta del archivo.",
              details: nil
            )
          )
          return
        }
        do {
          try Self.excludeFromBackup(path: path)
          result(nil)
        } catch {
          result(
            FlutterError(
              code: "exclude_failed",
              message: "No se pudo excluir el archivo de la copia de seguridad.",
              details: nil
            )
          )
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Marca el archivo para que iCloud no lo copie.
  ///
  /// En iOS, por defecto, TODO lo que hay en la carpeta de la app se guarda
  /// en la copia de iCloud. Con esta bandera, el archivo queda excluido.
  private static func excludeFromBackup(path: String) throws {
    var url = URL(fileURLWithPath: path)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try url.setResourceValues(values)
  }
}
