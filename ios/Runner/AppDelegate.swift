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
