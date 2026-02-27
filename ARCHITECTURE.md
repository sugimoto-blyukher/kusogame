# ARCHITECTURE

このドキュメントは、現行実装（リポジトリ直下の `.rb`）の役割を**関数単位**で整理したものです。
`backup/v1/*.rb` は旧実装のため、ここでは概要のみ扱います。

## 全体構成
- `main.rb`: 起動エントリポイント
- `game_window.rb`: シーン管理、入力/描画の統合
- `battle_scene.rb`: 戦闘の状態遷移とUI
- `world_map_manager.rb`: マップ定義の読み込み・遷移/当たり判定マップ構築
- `map.rb`: マップデータ構造と描画
- `player.rb`: プレイヤー移動と描画
- `hero.rb`: 勇者のステータス/成長/盟友管理
- `enemy.rb`: 敵ロールと戦闘用ステータス
- `story_manager.rb`: 章進行と会話/エンディング分岐
- `save_data.rb`: セーブ/ロードI/O
- `npc.rb`: NPCの表示モデル
- `test_map_factory.rb`: テスト用マップ生成
- `game_config.rb`: 定数・データ定義
- `imgset.rb`: 旧DXRuby由来の未使用コード（現行Gosu構成では非使用）

## ファイル別詳細

### `main.rb`
- `GameWindow.new.show`
  - Gosuウィンドウを生成してメインループを開始する。

### `game_config.rb`
- `module GameConfig`
  - ゲーム全体の設定値を集中管理する。
- 主要定数群
  - パス系: 画像/マップの参照先。
  - 画面系: タイルサイズ、ウィンドウサイズ、表示領域。
  - マップ系: マップID、ワープ、NPC配置、開始地点。
  - 衝突系: 通行不可タイル、境界ブロック。
  - 進行系: コア座標、ランダムエンカウント設定。

### `map.rb` (`class Map`)
- `initialize(source)`
  - ファイルまたは2次元配列からマップを読み込み、サイズを確定する。
- `self.from_rows(rows)`
  - 配列から生成する簡易ファクトリ。
- `in_bounds?(x, y)`
  - 座標の範囲チェック。
- `[](x, y)`
  - 範囲内セルの取得。
- `[]=(x, y, value)`
  - 範囲内セルの更新。
- `draw(tiles, camera_x, camera_y, viewport_x, viewport_y, viewport_w, viewport_h, z)`
  - ビューポート内に入るタイルのみを描画する。
- `read_from_file(filename)`
  - `.dat` を行単位で読み込み、行パース後に正規化する。
- `parse_row(line)`
  - カンマ区切り/文字列連続の両形式をセル配列に変換。
- `parse_cell(cell)`
  - セル文字列を整数タイル番号または `nil` に変換。
- `normalize_rows(rows)`
  - 行データを整数/`nil` へ統一。
- `finalize_size`
  - `size_x`, `size_y` を確定。

### `player.rb` (`class Player`)
- `initialize(x, y, image_path, tile_size:)`
  - プレイヤー座標、移動ステップ、画像を初期化。
- `update(input_x, input_y, map, collision_map)`
  - 入力に応じて1タイル移動を開始/継続し、当たり判定で移動可否を決める。
- `draw(screen_x, screen_y, z = 30)`
  - プレイヤースプライトを画面座標へ描画。
- `warp_to(tile_x, tile_y)`
  - タイル座標へ即時ワープし、移動中状態をリセット。
- `advance_step`
  - 分割移動の1ステップ進行。

### `npc.rb` (`class Npc`)
- `initialize(name:, tile_x:, tile_y:, image:, tile_size: 32)`
  - 表示用NPCの属性を保持。
- `draw(camera_x, camera_y, viewport_x, viewport_y, z = 6)`
  - カメラ考慮で描画し、軽い上下アニメーションを付与。

### `enemy.rb` (`class Enemy`)
- `initialize(image_path)`
  - フォールバック画像と敵画像セットを準備し、初回 `roll!` を実行。
- `roll!`
  - 敵テンプレートをランダム選択して戦闘ステータスへ反映。
- `alive?`
  - 生存判定。
- `take_damage(amount)`
  - ダメージ適用（0未満にならない）。
- `hp_ratio`
  - 現HP比率（契約判定に利用）。
- `pact_profile`
  - 盟友化用プロフィールを返す。
- `battle_intro`
  - 戦闘開始メッセージを生成。
- `draw(z = 40)`
  - 敵スプライトを戦闘画面へ描画。
- `load_monster_images`
  - 設定された敵画像を事前ロード。

### `hero.rb` (`class Hero`)
- `initialize(name: "ゆうしゃ")`
  - 勇者ステータス/所持金/盟友情報の初期化。
- `alive?`
  - 生存判定。
- `exp_to_next`
  - 次レベル必要経験値を算出。
- `gain_exp(amount)`
  - 経験値加算、必要なら複数回レベルアップ。
- `gain_gold(amount)`
  - 所持金加算。
- `companion_count`
  - 盟友人数を返す。
- `companion_limit`
  - 最大盟友数を返す。
- `companion_full?`
  - 盟友枠満杯判定。
- `companion_attack_bonus`
  - 盟友の攻撃加算値合計。
- `active_companion`
  - 戦闘支援対象（先頭盟友）を返す。
- `companion_skill_name(companion)`
  - スキル識別子を表示名へ変換。
- `swap_companions(index_a, index_b)`
  - 盟友並び替え。
- `form_pact(profile)`
  - 盟友追加と共鳴値増加。
- `to_save_data`
  - セーブ用ハッシュへ変換。
- `load_from_save_data(data)`
  - セーブデータを安全に復元。
- `take_damage(amount)`
  - 被ダメージ処理。
- `heal(amount)`
  - 回復処理（上限超過なし）。
- `use_mp(cost)`
  - MP消費可否判定と消費。
- `use_herb`
  - 薬草消費可否判定と消費。
- `full_recover`
  - HP/MP全回復。
- `integer_or_default(value, fallback)`
  - 数値パース失敗時のフォールバック。
- `build_companion(profile)`
  - 盟友プロフィールを内部形式に正規化。
- `level_up`
  - レベル上昇と能力値成長、メッセージ生成。

### `battle_scene.rb` (`class BattleScene`)
- `initialize(window, hero, enemy)`
  - 戦闘UI資源とコマンド定義を初期化。
- `start_encounter`
  - 敵再ロール、戦闘状態初期化、開幕メッセージ投入。
- `active?`
  - 戦闘有効状態の確認。
- `update`
  - 戦闘継続/終了タイミングを更新し、次シーンを返す。
- `draw`
  - 戦闘背景、ステータス、敵、下部UIを描画。
- `button_down(id)`
  - 戦闘中入力を処理（コマンド選択/メッセージ送り）。
- `reset_state`
  - 戦闘内部状態を初期値へ戻す。
- `perform_command(action)`
  - コマンド種別に応じた処理へ分岐。
- `player_attack_turn`
  - 通常攻撃の計算、撃破判定、敵ターン連結。
- `cast_heal`
  - MP消費回復、必要なら敵ターン連結。
- `attempt_pact`
  - 契約可能判定、確率判定、成功/失敗分岐。
- `try_run`
  - 逃走成功/失敗分岐。
- `enemy_turn_messages`
  - 敵行動のダメージ計算と結果メッセージ生成。
- `victory_messages`
  - 経験値/ゴールド付与と勝利メッセージ生成。
- `pact_success_rate`
  - 契約成功率をHP/共鳴/補正値から算出。
- `companion_support_messages(_trigger)`
  - 盟友スキルの追撃/補助効果を抽選して適用。
- `queue_with_enemy_turn(messages)`
  - プレイヤー行動メッセージに敵ターン結果を連結。
- `calc_damage(atk, dfs, variance: 2)`
  - 共通ダメージ式。
- `queue_messages(messages, next_state: :command)`
  - メッセージキュー投入と次状態設定。
- `handle_message_input(id)`
  - メッセージ送り入力処理。
- `on_message_end`
  - メッセージ完了後の状態遷移。
- `draw_battle_field`
  - 戦闘背景レイヤ描画。
- `draw_status_panels`
  - 敵/味方ステータスパネル描画。
- `draw_bottom_ui`
  - メッセージ欄とコマンド欄描画。
- `draw_command_grid`
  - 2x2コマンドボタン描画。
- `draw_panel(x, y, w, h)`
  - 共通パネル枠描画。
- `draw_hp_bar(x, y, w, hp, max_hp)`
  - HPバー描画。
- `move_selection(dx, dy)`
  - カーソル移動（循環）。
- `command_index_from_mouse`
  - マウス座標からコマンド番号を逆算。

### `world_map_manager.rb` (`class WorldMapManager`)
- `initialize(world_maps)`
  - ワールド定義を保持し、現在マップ情報を初期化。
- `load!(map_key, spawn_override = nil)`
  - マップ読込、サブマップ/衝突マップ生成、ワープ/NPC設定。
- `spawn_tile`
  - 現在のスポーン位置を返す。
- `transition_for(tile_x, tile_y)`
  - 指定タイルがワープなら遷移先情報を返す。
- `build_empty_sub_map(base_map)`
  - 前景レイヤ用の空マップを生成。
- `build_collision_map(base_map, warps)`
  - 通行可否マップを生成（境界・不可侵タイル・ワープ補正）。
- `border_tile?(x, y, map)`
  - 境界タイル判定。

### `story_manager.rb` (`class StoryManager`)
- `initialize`
  - 章進行、コア復旧状態、エンディング状態を初期化。
- `chapter`
  - 現在章を返す。
- `objective_text`
  - HUD表示用の現在目的文を返す。
- `core_restored?(map_key)`
  - 指定マップの街核復旧状態を返す。
- `target_map_key`
  - 現章の対象マップIDを返す。
- `target_map_title`
  - 現章の対象マップ名を返す。
- `npc_dialog(map_key, npc_name)`
  - 状態に応じたNPC会話文を返す。
- `interact_core(map_key, hero)`
  - 街核調査時の反応と進行可否判定。
- `to_save_data`
  - ストーリー状態をセーブ形式へ変換。
- `load_from_save_data(data)`
  - セーブ形式からストーリー状態を復元。
- `finished?`
  - 全章完了判定。
- `restore_core!(map_key, hero)`
  - 街核復旧処理、章進行、分岐エンド決定。
- `ending_lines`
  - エンディング種別の表示文を返す。
- `integer_or_default(value, fallback)`
  - 数値パースの安全化。

### `save_data.rb` (`module SaveData`)
- `exists?`
  - セーブファイル存在確認。
- `save(hero:, map_key:, tile_x:, tile_y:, story: nil)`
  - JSON形式でセーブデータを書き出す。
- `load`
  - セーブJSONを読み込み、妥当ならハッシュで返す。

### `game_window.rb` (`class GameWindow < Gosu::Window`)
- `initialize`
  - 全リソース/状態/シーンを初期化し、初期マップ読込。
- `update`
  - 現シーンごとの更新処理を呼び分け。
- `draw`
  - 現シーンに応じた描画。
- `button_down(id)`
  - シーン別の入力ハンドラへ分岐。
- `needs_cursor?`
  - マウスカーソル表示の要否を返す。
- `update_game_map`
  - フィールド移動、カメラ追従、遷移、ランダム戦闘判定。
- `draw_game_map`
  - マップ、プレイヤー、NPC、HUD、ダイアログを描画。
- `draw_map_chrome`
  - マップ表示領域の枠装飾を描画。
- `draw_hud`
  - ステータス・操作ガイド・目的文を描画。
- `draw_companion_menu`
  - 盟友メニューUIを描画。
- `input_x`
  - 左右入力を -1/0/1 で返す。
- `input_y`
  - 上下入力を -1/0/1 で返す。
- `load_all_map_tiles`
  - タイルセット画像をロード。
- `load_map(map_key, spawn_tile = nil)`
  - マップ一式を更新し、プレイヤー配置・カメラ初期化。
- `load_npc_images`
  - NPC画像辞書を構築。
- `build_map_npcs(npc_entries)`
  - 定義データから `Npc` 配列を生成。
- `draw_npcs`
  - NPCを描画。
- `handle_map_transition`
  - 現在タイルに応じてワープ遷移。
- `reset_camera`
  - カメラ位置をプレイヤー基準で初期化。
- `draw_warp_marker`
  - ワープ床を可視化描画。
- `draw_core_marker`
  - ストーリー対象の街核マーカー描画。
- `draw_map_dialog`
  - マップ会話パネル描画。
- `handle_map_button(id)`
  - フィールド中の決定/メニュー/セーブ/ロード入力処理。
- `handle_companion_menu_input(id)`
  - 盟友メニュー中の入力処理。
- `save_progress`
  - 現在状態を保存。
- `load_progress`
  - 保存状態を復元。
- `integer_or_default(value, fallback)`
  - 数値変換の安全化。
- `show_notice(text)`
  - 一時通知を設定。
- `notice_active?`
  - 通知表示中か判定。
- `map_dialog_active?`
  - 会話表示中か判定。
- `start_map_dialog(lines)`
  - 会話キューを開始。
- `advance_map_dialog`
  - 次の会話行へ進める。
- `start_world_interaction`
  - 決定キー時の調査対象（NPC/街核）判定と反応開始。
- `nearby_npc(tile_x, tile_y)`
  - 近傍NPCを探索。
- `tile_near?(x1, y1, x2, y2, range:)`
  - タイル距離判定。
- `confirm_button?(id)`
  - 決定キー判定。
- `player_tile_position`
  - プレイヤーのタイル座標を返す。
- `clamp_camera_target(target_x, target_y)`
  - カメラ座標をマップ範囲に収める。

### `test_map_factory.rb` (`module TestMapFactory`)
- `build(tile_count, tile_offset)`
  - ベース/サブ/衝突の3マップをテスト用に生成。
- `carve_passages(rows)`
  - 衝突マップに縦通路を開ける。

### `imgset.rb`（旧実装・非推奨）
- `BattleSceane`
  - 空クラス。コメント上、再定義済みで不要。
- `Bottun#initialize(x, y, image_path=...)`
  - DXRuby前提のボタン初期化（現行構成では未使用）。
- `Bottun#draw(text)`
  - DXRuby前提の文字付きボタン描画（現行構成では未使用）。
- `Sceane`
  - 空クラス。コメント上、再定義済みで不要。

## 補足: `backup/v1/*.rb`
- 旧世代コードの保管場所。
- 現行フロー（`main.rb` → `GameWindow`）からは読み込まれない。
- 参照は「仕様比較・退避目的」に限定するのが安全。
