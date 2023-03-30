import 'dart:io';

import 'package:bbback/model/response.dart';
import 'package:bbback/utils/app_response.dart';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../model/user.dart';
import '../utils/app_utils.dart';

// class AppAuthController extends ResourceController {
//   AppAuthController(this.managedContext);
//   final ManagedContext managedContext;
//   @Operation.post()
//   Future<Response> signIn(@Bind.body() User user) async {
//     if (user.password == null || user.userName == null) {
//       return Response.badRequest(
//         body: ModelResponse(message: 'Поля PASSWORD и USERNAME обязательны'),
//       );
//     }
//     //поиск юзера по имени
//     try {
//       final qFindUser = Query<User>(managedContext)
//         ..where((element) => element.userName).equalTo(user.userName)
//         ..returningProperties(
//             (element) => [element.id, element.salt, element.hashPassword]);
//       //
//       //получаем первый элемент из списка поиска
//       final findUser = await qFindUser.fetchOne();
//       if (findUser == null) {
//         throw QueryException.input('Пользователь не найден', []);
//       }
//       //генеринг хэша пароля
//       final requestHashPassword =
//           generatePasswordHash(user.password ?? '', findUser.salt ?? '');
//       //проверка пароля
//       if (requestHashPassword == user.hashPassword) {
//         //обновляем token пароля
//         _updateTokens(findUser.id ?? -1, managedContext);
//         //получаем data пользователя
//         final newUser =
//             await managedContext.fetchObjectWithID<User>(findUser.id);
//         return Response.ok(
//           ModelResponse(
//               data: newUser!.backing.contents, message: 'Успешная авторизация'),
//         );
//       } else {
//         throw QueryException.input('Неправильный пароль', []);
//       }
//     } catch (e) {
//       return AppResponse.serverError(e);
//     }
//   }
//   @Operation.put()
//   Future<Response> signUp(@Bind.body() User user) async {
//     if (user.password == null || user.userName == null || user.email == null) {
//       return Response.badRequest(
//         body: ModelResponse(
//             message: 'Поля PASSWORD, USERNAME и EMAIL обязательны'),
//       );
//     }
//     //генерация соли
//     final salt = generateRandomSalt();
//     //генерация хэша пароля
//     final hashPassword = generatePasswordHash(user.password!, salt);
//     try {
//       late final int id;
//       //создаем транзакцию
//       await managedContext.transaction((transaction) async {
//         //создаем запрос для создания пользователя
//         final qCreateUser = Query<User>(transaction)
//           ..values.userName = user.userName
//           ..values.email = user.email
//           ..values.salt = salt
//           ..values.hashPassword = hashPassword;
//         //добавления пользователя в бд
//         final createdUser = await qCreateUser.insert();
//         //сохраняем id пользователя
//         id = createdUser.id!;
//         //обновление токена
//         _updateTokens(id, transaction);
//       });
//       //получаем данные пользователя по id
//       final userData = await managedContext.fetchObjectWithID<User>(id);
//       return AppResponse.ok(
//           body: userData!.backing.contents,
//           message: 'Пользователь успешно зарегистрировался');
//     } catch (e) {
//       return AppResponse.serverError(e);
//     }
//   }
//   @Operation.post('refresh')
//   Future<Response> refreshToken(
//       @Bind.path('refresh') String refreshToken) async {
//     try {
//       //получаем id пользователя через jwt token
//       final id = AppUtils.getIdFromToken(refreshToken);
//       //получаем данные пользователя по id
//       final user = await managedContext.fetchObjectWithID<User>(id);
//       if (user!.refreshToken != refreshToken) {
//         return Response.unauthorized(body: 'Token не валидный');
//       }
//       //обновление Token
//       _updateTokens(id, managedContext);
//       return Response.ok(ModelResponse(
//           data: user.backing.contents, message: 'Token успешно обновлен '));
//     } catch (e) {
//       return AppResponse.serverError(e);
//     }
//   }
//   void _updateTokens(int id, ManagedContext transaction) async {
//     final Map<String, dynamic> tokens = _getTokens(id);
//     final qUpdateTokens = Query<User>(transaction)
//       ..where((element) => element.id).equalTo(id)
//       ..values.accessToken
//       ..values.accessToken = tokens['access']
//       ..values.refreshToken = tokens['refresh'];
//     await qUpdateTokens.updateOne();
//   }
//   //генеринг jwt token
//   Map<String, dynamic> _getTokens(int id) {
//     final key = Platform.environment['SECRET_KEY'] ?? 'SECRET_KEY';
//     final accessClaimSet = JwtClaim(
//       maxAge: const Duration(hours: 1),
//       otherClaims: {'id': id},
//     );
//     final refreshClaimSet = JwtClaim(otherClaims: {'id': id});
//     final tokens = <String, dynamic>{};
//     tokens['access'] = issueJwtHS256(accessClaimSet, key);
//     tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);
//     return tokens;
//   }
// }

class AppAuthController extends ResourceController {
  AppAuthController(this.managedContext);
  final ManagedContext managedContext;
  @Operation.post()
  Future<Response> signIn(@Bind.body() User user) async {
    if (user.password == null || user.userName == null) {
      return Response.badRequest(
          body: ModelResponse(message: 'Поля password и username обязательны'));
    }
    try {
      final qFindUser = Query<User>(managedContext)
        ..where((element) => element.userName).equalTo(user.userName)
        ..returningProperties(
          (element) => [element.id, element.salt, element.hashPassword],
        );

      final findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.input("Пользователь не найден", []);
      }
      final requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');
      if (requestHashPassword == findUser.hashPassword) {
        _updateTokens(findUser.id ?? -1, managedContext);

        final newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);
        return Response.ok(ModelResponse(
          data: newUser!.backing.contents,
          message: 'Успешная авторизация',
        ));
      } else {
        return Response.badRequest(body: 'Неверный пароль');
      }
    } catch (e) {
      return Response.serverError(body: e);
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() User user) async {
    if (user.password == null || user.userName == null || user.email == null) {
      return Response.badRequest(
        body: ModelResponse(
            message: 'Поля password, username и email обязательны'),
      );
    }
    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password!, salt);
    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.userName = user.userName
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();
        id = createdUser.id!;
        _updateTokens(id, transaction);
      });
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(ModelResponse(
        data: userData!.backing.contents,
        message: 'Пользователь успешно зарегистрировался',
      ));
    } catch (e) {
      return AppResponse.serverError(e);
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<User>(id);

      if (user!.refreshToken != refreshToken) {
        return Response.unauthorized(body: 'Token не валидный');
      }

      _updateTokens(id, managedContext);

      return Response.ok(
        ModelResponse(
          data: user.backing.contents,
          message: 'Токен успешно обновлен',
        ),
      );
    } on QueryException catch (e) {
      return Response.serverError(body: ModelResponse(message: e.message));
    }
  }

  void _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, String> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((element) => element.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];

    await qUpdateTokens.updateOne();
  }

  Map<String, String> _getTokens(int id) {
    final key = Platform.environment['SECRET_KEY'] ?? "SECRET_KEY";
    final accessClaimSet = JwtClaim(
      maxAge: const Duration(hours: 1),
      otherClaims: {'id': id},
    );
    final refreshClaimSet = JwtClaim(
      otherClaims: {'id': id},
    );
    final tokens = <String, String>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);

    return tokens;
  }
}
