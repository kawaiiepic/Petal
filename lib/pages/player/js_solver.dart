import "package:flutter_js/flutter_js.dart";
import "package:youtube_explode_dart/js_challenge.dart";

class FlutterJsSolver extends BaseEJSSolver {
  final JavascriptRuntime _js = QuickJsRuntime2();

  @override
  Future<String> executeJavaScript(String jsCode) async => _js.evaluate(jsCode).stringResult;
}
