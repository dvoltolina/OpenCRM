import 'bootstrap.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  await bootstrap(loadConfig: AppConfig.defaultClinic);
}
