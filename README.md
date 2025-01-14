# Flutter Riverpod HTTP Cache App

- Flutter Riverpod HTTP Cache Appは、Riverpodを使用した状態管理とHiveによるHTTPキャッシュ機能を組み合わせたFlutterアプリケーションです。
- ReactのSWRのように、HTTPリクエストのキャッシュと有効期限管理、エラーハンドリングを実装しています。
- JSONPlaceholderを使用してフェイクのオンラインREST APIからデータを取得します。

## 特徴

- Riverpodによる状態管理: 効率的でスケーラブルな状態管理を実現。
- HTTPキャッシュ: DioとHiveを使用してHTTPレスポンスをキャッシュ。
- キャッシュの有効期限: キャッシュデータの有効期限を設定し、データの新鮮さを保つ。
- エラーハンドリング: ネットワークエラー発生時に、キャッシュデータが存在すればそれを表示。
- ユニットテスト: 高いカバレッジ率を持つテストを実装。
- FVMによるFlutterバージョン管理: プロジェクトごとにFlutterのバージョンを管理。

## 前提条件

- Flutter SDK: FVMを使用して管理します。
- FVM: Flutterのバージョン管理ツール。

### インストール手順

1. FVMのインストール

   ```bash
   # Homebrewを使用してインストール（macOS/Linuxの場合）
   brew tap leoafarias/fvm
   brew install fvm

   # または、Pub経由でインストール
   dart pub global activate fvm
   ```

2. リポジトリのクローン

   ```bash
   git clone https://github.com/okamyuji/flutter_riverpod_http_cache_app.git
   cd flutter_riverpod_http_cache_app
   ```

3. Flutter SDKのインストール

   ```bash
   fvm use 3.27.1
   ```

4. 依存関係のインストール

    ```bash
    fvm flutter pub get
    ```

5. Hiveの型アダプターの生成

    ```bash
    fvm dart run build_runner build
    ```

6. アプリケーションの実行

    ```bash
    fvm flutter run
    ```

7. テスト用のモックファイルの生成

   - テストを実行する前に、必ずモックファイルを生成してください

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

8. テストの実行

    ```bash
    fvm flutter test
    ```

## プロジェクト構造

```shell
flutter_riverpod_http_cache_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── constants/
│   │   ├── api_config.dart
│   │   └── strings.dart
│   ├── services/
│   │   └── api_service.dart
│   ├── providers/
│   │   ├── api_provider.dart
│   │   └── posts_provider.dart
├── test/
│   ├── api_service_test.dart
│   ├── posts_provider_test.dart
│   └── posts_list_widget_test.dart
├── pubspec.yaml
└── README.md
```

- キーコンポーネント
    - main.dart: アプリケーションのエントリーポイント。Hiveの初期化とProviderScopeの設定。
    - app.dart: アプリのUIを定義しているルートウィジェット。
    - constants/api_config.dart: APIの設定を管理。
    - constants/strings.dart: アプリの文字列を管理。
    - services/api_service.dart: HTTPリクエストとキャッシュロジックを管理。
    - providers/api_provider.dart: Dio、Hive Box、ApiServiceのプロバイダーを提供。
    - providers/posts_provider.dart: 投稿データを非同期にフェッチするFutureProvider。
    - test/: サービス、プロバイダー、UIコンポーネントのユニットテスト。

## 使用方法

- アプリを起動すると、JSONPlaceholder APIから投稿データを取得し、リストとして表示します。
- データはHiveを使用してキャッシュされ、キャッシュの有効期限内であればキャッシュからデータが読み込まれます。
- キャッシュが期限切れの場合、新たにAPIからデータを取得し、キャッシュを更新します。

1. データのリフレッシュ

    - リストを下にスワイプすると、データを手動でリフレッシュできます。
    - これにより、新しいデータがAPIから取得され、キャッシュが更新されます。

2. キャッシュの有効期限

    - デフォルトでは、キャッシュの有効期限は10分に設定されています。
    - 有効期限を過ぎると、次回データを取得する際に新しいデータがAPIから取得されます。

3. エラーハンドリング

    - ネットワークエラーが発生した場合
        - キャッシュが存在する場合: 古いキャッシュデータを表示し、エラーメッセージを表示します。
        - キャッシュが存在しない場合: エラーメッセージを表示します。

## 注意点

1. キャッシュの有効期限
   - デフォルトで10分に設定
   - `ApiService`のコンストラクタで変更可能

2. エラーハンドリング
   - ネットワークエラー時はキャッシュデータを返却
   - キャッシュが無い場合はエラーを表示

3. テスト実行時の注意
   - モックファイルの生成が必要
   - 非同期処理の待機が必要
   - Boxのメソッド（get, containsKey）には適切なスタブが必要

## テストの構造

テストは以下の3つのカテゴリーに分かれています

1. APIサービステスト (`test/api_service_test.dart`)
   - キャッシュの有効性チェック
   - APIからのデータ取得
   - エラーハンドリング
   - キャッシュの更新

2. プロバイダーテスト (`test/posts_provider_test.dart`)
   - Riverpodプロバイダーの動作確認
   - 非同期データ取得
   - エラー状態の処理

3. ウィジェットテスト (`test/posts_list_widget_test.dart`)
   - UIの表示確認
   - ローディング状態
   - エラー表示
   - キャッシュデータの表示

### テストでのモックの使用

テストでは`mockito`パッケージを使用してモックを作成しています
テストファイルごとに個別のモックファイルが生成されます

- `test/api_service_test.mocks.dart`
- `test/posts_provider_test.mocks.dart`
- `test/posts_list_widget_test.mocks.dart`

## テストカバレッジ

テストカバレッジを確認し、視覚的に分析するための手順です。

### 準備

1. lcovのインストール（macOSの場合）:

    ```bash
    brew install lcov
    ```

### カバレッジの取得と表示

1. カバレッジデータの生成:

    ```bash
    fvm flutter test --coverage
    ```

2. HTMLレポートの生成:

    ```bash
    genhtml coverage/lcov.info -o coverage/index.html
    ```

3. カバレッジレポートの表示:

    ```bash
    open coverage/index.html
    ```

4. コマンドラインで簡易サマリーを表示:

    ```bash
    lcov --summary coverage/lcov.info
    ```

## カバレッジレポートの見方

1. HTMLレポートでは以下の情報が確認できます：
    - Line Coverage: コードの行がテストで実行された割合
    - Function Coverage: 関数がテストで呼び出された割合
    - Branch Coverage: 条件分岐がテストでカバーされた割合

2. 色による表示
    - 🟩 緑: テストでカバーされている行
    - 🟥 赤: テストでカバーされていない行
    - 🟨 黄: 部分的にカバーされている分岐

### カバレッジの注意点

- `lib/`ディレクトリ配下のコードのみがカバレッジ計測の対象となります
- テストファイル自体はカバレッジ計測の対象外です
- UIウィジェットのテストは、ユーザーの操作をシミュレートする部分のカバレッジが重要です

## 今後の改善点

- [ ] キャッシュの有効期限をユーザーが設定できるようにする
- [ ] オフライン時の表示をより分かりやすくする
- [ ] キャッシュのクリア機能の追加
- [ ] ユニットテストのカバレッジ向上
