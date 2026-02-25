# Repository Guidelines

## プロジェクト構成とモジュール配置
このリポジトリは Ruby + Gosu 製の小規模ゲームで、主要コードはルート直下に配置されています。
- 実行系: `main.rb`（エントリポイント）、`game_window.rb`、`battle_scene.rb`、`world_map_manager.rb`
- ドメイン: `hero.rb`、`enemy.rb`、`player.rb`、`map.rb`、`game_config.rb`
- データ/アセット: `mdat/`（マップ `.dat`）、`image/`（スプライト・背景・タイル）
- 参考実装: `backup/v1/`（旧バージョン）
- 補助モジュール: `test_map_factory.rb`（テスト用マップ生成）

新しいゲームロジックは `snake_case.rb` の単位で追加し、パスや定数の変更は `GameConfig` に集約してください。

## ビルド・テスト・開発コマンド
- `ruby main.rb`: ゲームを起動する。
- `ruby -c *.rb`: 全 Ruby ファイルの構文チェックを行う。
- `ruby -e "require_relative 'test_map_factory'; p TestMapFactory.build(16,0).size"`: マップ生成の簡易スモークチェック。

前提: Gosu のインストール（`gem install gosu`）。

## コーディング規約と命名
- インデントは 2 スペース、Ruby の標準的な書き方を優先。
- ファイル名は `snake_case.rb`、クラス/モジュールは `CamelCase`、定数は `ALL_CAPS`。
- 共有設定（タイルサイズ、アセットパス、マップ ID）は `game_config.rb` に置く。
- ローカル参照は `require_relative` を使用する。
- 描画・移動・遷移処理は責務ごとに小さなメソッドへ分割する。

## テスト方針
現状は専用テストフレームワーク未導入のため、手動確認を基本とします。
- コミット前に `ruby -c *.rb` を実行する。
- `ruby main.rb` で移動、ワープ遷移、戦闘画面の基本フローを確認する。
- マップ関連変更時は `TestMapFactory.build(...)` を使って生成結果を確認する。

自動テストを追加する場合は Minitest を採用し、`test/` 配下に `test_player.rb` のような名前で配置してください。

## コミットとプルリクエスト
履歴には短い日本語コミット（例: `修正`、`大規模修正`）が多いため、同じ簡潔さを保ちつつ変更点が分かる件名にします（例: `戦闘UIの入力処理を修正`）。

プルリクエストでは以下を明記してください。
- 変更内容とゲーム上の影響範囲
- 関連 Issue / タスク
- 見た目変更がある場合のスクリーンショットや GIF
- 実施した確認手順（`ruby -c *.rb`、ゲーム内動作確認）
