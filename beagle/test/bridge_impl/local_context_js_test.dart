/*
 * Copyright 2020, 2022 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:convert';

import 'package:beagle/src/bridge_impl/beagle_js_engine.dart';
import 'package:beagle/src/bridge_impl/local_context_js.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBeagleJSEngine extends Mock implements BeagleJSEngine {}

class User {
  User(this.name, this.age);

  String name;
  int age;
}

void main() {
  final beagleJSEngineMock = MockBeagleJSEngine();
  final defaultLocalContextId = 'myLocalContext';
  final viewId = 'testViewId';

  group('Given a LocalContextJS object', () {
    group('When I call set method passing an encodable value', () {
      test('Then it should set value in local context', () {
        final value = {
          'abc': 1,
          'def': false,
          'ghi': 'test',
          'jkl': [1, '2', true]
        };
        final valueEncoded = json.encode(value);
        LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).set(value);
        expect(verify(() => beagleJSEngineMock.evaluateJsCode(captureAny<String>())).captured.single,
            'global.beagle.getViewById("$viewId").getLocalContexts().getContext("$defaultLocalContextId").set($valueEncoded)');
      });
    });

    group('When I call set method passing a value to a specific path', () {
      test('Then it should set value in local context at specific path', () {
        final value = 'test';
        final path = 'order.cart.name';
        final valueEncoded = json.encode(value);

        LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).set('test', 'order.cart.name');
        expect(verify(() => beagleJSEngineMock.evaluateJsCode(captureAny<String>())).captured.single,
            'global.beagle.getViewById("$viewId").getLocalContexts().getContext("$defaultLocalContextId").set($valueEncoded, "$path")');
      });
    });

    group('When I call set method passing a uncodable value', () {
      test('Then it should throw LocalContextSerializationError exception', () {
        final user = User('Fulano', 30);
        expect(() => LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).set(user, 'user'),
            throwsA(isInstanceOf<LocalContextSerializationError>()));
        verifyNever(() => beagleJSEngineMock.evaluateJsCode(captureAny<String>()));
      });
    });

    group('When I call get method', () {
      test('Then it should get local context value', () {
        final value = {
          'account': {'number': 1, 'name': 'Fulano', 'email': 'fulano@beagle.com'},
          'order': {
            'cart': {
              'name': 'Flutter test',
              'items': [
                {'name': 'keyboard', 'price': 39.9},
                {'name': 'mouse', 'price': 28.45}
              ]
            }
          }
        };
        when(() => beagleJSEngineMock.evaluateJsCode(
                'global.beagle.getViewById("$viewId").getLocalContexts().getContext("$defaultLocalContextId").get()'))
            .thenReturn(JsEvalResult(value.toString(), value));
        // ignore: inference_failure_on_function_invocation
        final result = LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).get();
        expect(result, value);
      });
    });

    group('When I call get method for a specific path', () {
      test('Then it should get value in local context at specific path', () {
        const value = 'Flutter test';
        const path = 'order.cart.name';

        when(() => beagleJSEngineMock.evaluateJsCode(
                'global.beagle.getViewById("$viewId").getLocalContexts().getContext("$defaultLocalContextId").get("$path")'))
            .thenReturn(JsEvalResult(value, value));
        final result =
            // ignore: inference_failure_on_function_invocation
            LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).get('order.cart.name');
        expect(result, value);
      });
    });

    group('When I call clear method', () {
      test('Then it should clear local context', () {
        clearInteractions(beagleJSEngineMock);
        LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).clear();
        expect(verify(() => beagleJSEngineMock.evaluateJsCode(captureAny<String>())).captured.single,
            'global.beagle.getViewById("$viewId").getLocalContexts().getContext("$defaultLocalContextId").clear()');
      });
    });

    group('When I call clear method for a specific path', () {
      test('Then it should clear local context at specific path', () {
        final path = 'order.cart.name';
        LocalContextJS(beagleJSEngineMock, viewId, defaultLocalContextId).clear(path);
        expect(verify(() => beagleJSEngineMock.evaluateJsCode(captureAny<String>())).captured.single,
            'global.beagle.getViewById("$viewId").getLocalContexts().getContext("$defaultLocalContextId").clear("$path")');
      });
    });
  });
}
