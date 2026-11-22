# FBNeo_LS

[English](README.md)

**Fightcade の FBNeo** で対戦を始めると、[Lossless Scaling](https://store.steampowered.com/app/993090/Lossless_Scaling/) を自動でかけます。

- **対戦**：FBNeo がウィンドウ表示なら全画面（Alt+Enter）にし、そのあと Lossless Scaling のホットキーを押します。
- **観戦**：何もしません。
- **トレーニングモード**：何もしません（設定で対象にできます）。

小さな PowerShell スクリプトです。ほかのソフトを入れる必要はありません。

## 必要なもの

- Windows 10 / 11（Windows に入っている Windows PowerShell 5.1 を使います）
- [Fightcade](https://www.fightcade.com/)（FBNeo のゲーム）
- Lossless Scaling（Steam の有料ソフト）。起動しておいてください。
  - Lossless Scaling でホットキーを設定しておきます（初期値は Ctrl+Alt+S）。FBNeo_LS は Lossless Scaling の設定からホットキーを読み取るので、変えてもかまいません。
  - FBNeo で使うプロファイルは、**Auto Scale をオフ**にしておくのがおすすめです。オンだと、Lossless Scaling と FBNeo_LS の両方がスケーリングを始めようとすることがあります。

## 使い始め方

1. このリポジトリをダウンロード（**Code** → **Download ZIP**）して、好きな場所（例：`C:\tools\FBNeo_LS`）に展開します。
2. `start_FBNeo_LS.bat` をダブルクリックします。
3. Fightcade で対戦を始めます。FBNeo のウィンドウが出てから約 3 秒後に Lossless Scaling がかかります。

うまく動いたら、ふだんは次のファイルを使います。

| ファイル | すること |
|---|---|
| `start_FBNeo_LS.bat` | ログが見えるウィンドウを出して起動（動作確認向け） |
| `start_FBNeo_LS_hidden.bat` | ウィンドウを出さずに起動 |
| `stop_FBNeo_LS.bat` | FBNeo_LS を止める |
| `enable_autostart.bat` | Windows にサインインしたとき自動で起動するようにする |
| `disable_autostart.bat` | 自動起動をやめる |

- 同時に動くのは 1 つだけです。もう一度起動しても何も起きません。
- `enable_autostart.bat` は、スタートアップフォルダーにショートカットを置きます（管理者権限は不要）。何度実行しても問題ありません。フォルダーを移動したら、もう一度実行してください。

## 設定

初めて起動したとき、スクリプトと同じフォルダーに `FBNeo_LS.ini` ができます。メモ帳で書き換えて、FBNeo_LS を起動し直してください。

| 設定 | 初期値 | 意味 |
|---|---|---|
| `IncludeTraining` | `false` | トレーニングモードにもかける |
| `DelayMs` | `3000` | FBNeo のウィンドウが出てから、Lossless Scaling のホットキーを押すまでの時間（ミリ秒） |
| `AltEnterOnMatch` | `true` | 対戦で FBNeo が全画面でなければ Alt+Enter を押す |
| `AltEnterWaitMs` | `1000` | FBNeo のウィンドウが出てから Alt+Enter を押すまでの時間（ミリ秒） |
| `AltEnterRetryMs` | `800` | Alt+Enter のあと、この時間たっても全画面でなければもう一度押す（ミリ秒） |
| `FallbackHotkey` / `FallbackModifiers` | `S` / `Control Alt` | Lossless Scaling の設定を読めないときだけ使うホットキー |
| `SpectatePattern` / `MatchPattern` | `*quark:stream*` / `*quark:*` | FBNeo のコマンドラインで、観戦と対戦を見分ける条件 |
| `LogToFile` / `LogMaxKB` | `true` / `1024` | `FBNeo_LS.log` を書くか、と最大サイズ |

## しくみ

1. 1 秒ごとに `fcadefbneo.exe` を探します。
2. コマンドラインで種類を決めます。`quark:stream` は観戦、それ以外の `quark:` は対戦、どちらでもなければトレーニングです。
3. 対戦なら、FBNeo のウィンドウを前面に出し、必要なら Alt+Enter を押してから、Lossless Scaling のホットキーを押します。
4. ホットキーは、押すたびに `%LOCALAPPDATA%\Lossless Scaling\Settings.xml` から読み取ります。Lossless Scaling が起動していなければ、キーは送りません。

キーは実際のキーボードと同じスキャンコード付きで送ります（スキャンコードなしで送ったときは、FBNeo の「Load State」画面が開いてゲームが止まりました）。

## うまく動かないとき

`FBNeo_LS.log` を見るか、`start_FBNeo_LS.bat` で起動してウィンドウのログを見てください。

| ログ | 確認すること |
|---|---|
| `LS hotkey NOT sent (Lossless Scaling is not running)` | 先に Lossless Scaling を起動する |
| `unknown LS hotkey` / `hotkey unknown` | Lossless Scaling でホットキーを設定し直すか、`FallbackHotkey` を設定する |
| `still not fullscreen at ... ms` | `AltEnterRetryMs` か `DelayMs` を増やす |
| `could not bring to front` | ほかのウィンドウが前面に残っています。ほかのウィンドウを触らずにもう一度試す |
| 観戦でかかる、対戦でかからない | Fightcade のコマンドラインが変わった可能性があります。`SpectatePattern` / `MatchPattern` を確認する |

- インターネットから取ってきたスクリプトは、Windows に止められることがあります。`.bat` は `-ExecutionPolicy Bypass` で PowerShell を起動するので、ふつうは問題ありません。それでも起動しないときは、展開する前に ZIP を右クリック →「プロパティ」→「許可する」にチェックを入れてください。
- ウイルス対策ソフトによっては、「ウィンドウを出さない PowerShell がキーを送る」ことを警告する場合があります。このスクリプトがしているのはまさにそれです。気になる場合はスクリプトの中身を確認してください。

## 注意

- Fightcade FBNeo v0.2.97.44-55 の Vampire Savior（vsavj）で確認しています。ほかのゲームも同じしくみで動くはずですが、確認はしていません。
- このプロジェクトは Fightcade、FBNeo、Lossless Scaling とは関係ありません。
- 自己責任でお使いください。

## ライセンス

[MIT](LICENSE)
