# QRReader

SwiftUIで作成された広告フリーなQRコードリーダーアプリです

## ビルド

- iOS 17以降に対応。検証環境はXcode 27、XcodeGen 2.46です。依存ライブラリのQuantumLeapは1.0.1に固定しています。
- `brew install xcodegen` 後に `./scripts/generate-project.sh` を実行し、生成された `QRReader.xcodeproj` をXcodeで開きます。
- 実機で起動する場合は、Signingのチームを確認し、Firebaseの [GoogleService-Info.plist](https://console.firebase.google.com/project/qrreader-994fd) を `QRReader/GoogleService-Info.plist` に配置してプロジェクトを再生成してください。設定ファイルはGit管理対象外です。
- Debugでは設定ファイルがなくてもUIを検証できます。ReleaseにはFirebaseの設定ファイルが必要です。

この作業環境には提供されたFirebase設定ファイルを配置済みです。Debug/Releaseの署名ビルドとiPad Air M3でのRelease通常起動を確認しました。設定ファイルはGit管理対象外なので、新しいチェックアウトでは別途配置してください。

`project.yml` と `Config/Xcode-Package.resolved` がプロジェクトと依存関係の管理元です。生成されたXcodeプロジェクトは既存の方針に従ってGit管理対象外にしています。

## 検証

`swift test` でURL判定・履歴の互換性と保存・スキャン状態のテストを実行できます。

`./scripts/validate-ios.sh` は専用のiPhoneシミュレータを作成し、アプリのビルドと単体・UIテストを実行します。終了・失敗・中断時にその端末だけを削除し、ログと結果を `.build/validation/` に残します。既存のSimulatorウィンドウや他の端末には操作しません。

標準はiOS 26.5 / iPhone 16です。別のインストール済みランタイムや端末を使う場合は `QR_SIM_RUNTIME`、`QR_SIM_DEVICE_TYPE` を指定できます。実際のカメラ読み取りは実機で確認してください。

配信前にはFirebase設定とバージョン／ビルド番号を確認してください。既存の配信ワークフローから利用する場合は、ビルド前にプロジェクト生成とFirebase設定の配置が必要です。2026年10月15日に、新UIの1.0.4（ビルド5）と日本語・英語のスクリーンショット32枚をApp Store Connectへ再提出しました。同日にQuantumLeap 1.0.1とiOS 17以降へ更新したビルド6を再提出し、「審査待ち」を確認しました。ビルド5の検証記録は `.build/validation/asc-resubmit/`、ビルド6の署名・テスト・提出結果は `.build/validation/quantumleap-1.0.1/` に保存しています。同日、Guideline 5.1.1(iv)で指摘されたカメラ権限の事前案内を日本語・英語ともに修正し、ビルド7を再提出しました。ビルド7は「審査待ち」です。今回の再現・修正・テスト・提出記録は `.build/validation/rejection-20261015-build6/` に保存しています。実機でのQR読み取りは未確認です。

## デザイン

`design/mockups/qrreader-ui-v2.html` の「カメラ」案を採用しています。画面はネイティブのセーフエリアに合わせて配置し、タブのアイコンは28pt、操作アイコンは24ptです。

実装の見た目の基準は、ユーザー確認済みの[全13画面の一覧](design/screenshots/2026-10-14-camera-ui/all-screens.png)です。この一覧は実際のSwiftUIアプリから撮影して作成しています。個別の原寸PNGと撮影元は同じフォルダに保存しています。

通常のシミュレータ起動では実カメラがないため、カメラ利用不可の案内が表示されます。撮影テストでは背景と読み取り内容だけを検証用データに置き換え、通常起動と共通の画面を使用します。実機では実カメラの映像が表示されます。
