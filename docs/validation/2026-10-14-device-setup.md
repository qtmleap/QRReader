# Firebase設定と実機起動の確認

提供された `GoogleService-Info.plist` を `QRReader/GoogleService-Info.plist` に配置し、プロジェクトを再生成しました。Firebaseコンソールへのログインは今回の設定作業には不要になりました。新しいプロジェクト、アプリ登録、ダミー設定は作成していません。

## 設定ファイルとビルド

- `PROJECT_ID` は `qrreader-994fd`、`BUNDLE_ID` は `jp.qleap.qrreader` と一致しています。iOSアプリIDと数値の送信者IDも確認しました。APIキーは出力していません。
- ファイルは既存のgitignore対象で、Gitには追加していません。ローカルのアクセス権は600です。
- XcodeGen再生成後、アプリのResourcesに設定ファイルが追加されました。XcodeがXMLをバイナリplistに変換するため原本とのバイト列は異なりますが、Debug/Release双方で全設定値の一致を確認しました。
- 既存のチーム `5Q94QJ7G98` の開発証明書と有効なiOSプロファイルを使い、Debug/Releaseの実機向け自動署名ビルドが成功しました。双方の `.app` を `codesign --verify --deep --strict` で検証しました。
- 証明書CN末尾の `AN8PD7D7BF` はユーザーIDです。証明書OUのチームIDは `5Q94QJ7G98` と一致しており、前段の独立レビューにあったチーム不一致の推測は解消しています。

## 実機確認

- iPad Air 13-inch (M3)、iOS 26.3.1にFirebase設定入りDebug版を更新インストールし、通常起動を確認しました。
- 続いてRelease版を更新インストールし、UIテスト引数・検証用カメラ引数なしで通常起動しました。ReleaseのFirebase初期化処理にはスキップ経路がありません。起動後のプロセス一覧でもアプリの実行継続を確認しました。
- 既存アプリのデータを削除せず、更新インストールしました。実機にはRelease版を残しています。
- デバッガによる実行時Firebaseオプションの読み取りは完了していません。接続確認でアプリが終了したため、デバッガなしで通常起動し直し、プロセス継続を確認しました。この確認はバンドルの全設定値、署名、通常Release起動とプロセス継続に基づきます。
- 実カメラでのQR読み取りとFirebaseバックエンドへの通信は未確認です。現在のアプリにはFirebaseバックエンド呼び出しがありません。
- iPhoneへのインストールは今回行っていません。接続とロック解除後に同じ署名ビルドをインストールできます。

ビルド成果物は `.build/DeviceDerivedData/Build/Products/{Debug,Release}-iphoneos/QRReader.app`、ログと実機操作結果は `.build/validation/firebase-device/` に保存しています。`verification-summary.json` に確認結果をまとめました。Simulatorは作成・起動していません。新しい証明書の発行や端末登録、App Store/TestFlightへの配信、App Checkの検証設定変更も行っていません。

Claude Codeの読み取り専用確認では、設定の整合性、リソースへの組み込み、通常Debug/Releaseの初期化経路に問題は指摘されませんでした。新しいEntitlementsやFirebaseプロバイダーの変更は不要です。
