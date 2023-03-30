import 'dart:io';
import 'controllers/app_auth_controller.dart';
import 'controllers/app_token_controller.dart';
import 'controllers/app_user_controller.dart';
import 'model/author.dart';
import 'model/post.dart';
import 'package:conduit_core/conduit_core.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  //подготовка к запуску
  @override
  Future prepare() {
    final persistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('tiken/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user')
        .link(AppTokenContoller.new)!
        .link(() => AppUserConttolelr(managedContext));

  //подключение к бд
  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ??
        'a0a65e9085b36e6b3f86fe9cf5401f6d03b9880f';
    final host = Platform.environment['DB_HOST'] ?? '127.0.0.1';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'dartback';
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
