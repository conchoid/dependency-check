# NVD データベース(odc.mv.db)をイメージに注入する手順

APIキーをイメージ・ビルド履歴・リポジトリに残さずに、NVD データ入りの `odc.mv.db` を
`conchoid/dependency-check` イメージへ入れるための手順メモ。

## 背景

- 12.2.0 までのイメージには、NVD データ入りの `odc.mv.db`(約245MB)が入っていた。
  利用側はフルダウンロードをせず、差分更新だけで済む。
- 13.0.0 では `setup.sh` が `--noupdate || true` でスキャンしていたため、
  DB が作られず、空のままイメージが出来ていた(`|| true` で失敗も隠れていた)。
- NVD の API キーは Dockerfile / setup.sh には書かない。
  キーなしのフルダウンロードはレート制限で実用的でないため、
  **ビルドの外(ローカル)で DB を作り、完成した DB だけをイメージに COPY する**。

## 方針

| 項目 | 内容 |
|---|---|
| キーを使う場所 | ローカルの `docker run` だけ(環境変数 `NVD_API_KEY` で渡す) |
| イメージに入るもの | `data/`(DB 本体と関連ファイル)だけ。キーは入らない |
| ビルドで使う値 | キーは不要。`Dockerfile` の `COPY` だけ |
| リポジトリ | `data/` は `.gitignore` 済み(約250MB以上のため commit しない) |

キーを `ARG` / `ENV` / `setup.sh` に書くと、`docker history` やレイヤーから読み取れるため禁止。

## 手順

### 1. 作業用ディレクトリを空にする

root 所有のファイルが残るため、コンテナ経由で消す。

```sh
cd <このリポジトリ>
mkdir -p data
docker run --rm -v "$PWD/data:/d" conchoid/dependency-check:<現行タグ> \
  sh -c 'rm -rf /d/* /d/.[!.]*'
```

### 2. ローカルで NVD データを取得する

キーはシェルの環境変数で渡し、コマンドラインには書かない。
**ビルドに使うのと同じバージョン**のイメージで作ること(DB のスキーマはバージョン依存)。

```sh
export NVD_API_KEY=<キー>
docker run --rm -e NVD_API_KEY \
  -v "$PWD/data:/opt/dependency-check/data" \
  conchoid/dependency-check:<現行タグ> \
  sh -c 'dependency-check --updateonly --nvdApiKey "$NVD_API_KEY"'
```

- `--updateonly` は `dependency-check --advancedHelp` に載っている(通常の `--help` には出ない)。
- 初回のフルダウンロードは約40万件。2026-10-06 の実行では、21分で17%だった。
  完了まで1.5〜2時間以上かかる見込み。
- 完了すると `data/odc.mv.db` ができる。サイズは実行終了後に確認すること。

### 3. 取得結果を確認する

```sh
ls -la data
# 更新なしでスキャンし、脆弱性が検出されれば NVD データが入っている
docker run --rm -v "$PWD/data:/opt/dependency-check/data" conchoid/dependency-check:<現行タグ> \
  sh -c 'cd /tmp && dependency-check --project t --disableCentral --disableAssembly \
    --format JSON --scan /opt/dependency-check/lib --noupdate'
```

`Autoupdate is disabled and the database does not exist` が出たら、DB が作られていない。

### 4. イメージに入れる

`Dockerfile` / `Dockerfile-arm64` で、`setup.sh` の実行後に `data/` を COPY する。
`COPY` と `chmod -R` を別レイヤーにすると DB が二重に保持されて約250MB以上膨らむため、
`--chmod` で1レイヤーにまとめる。

```dockerfile
COPY --chmod=777 data/ /opt/dependency-check/data/
```

あわせて `setup.sh` の次の行は不要になる(スキャンで DB を作らないため)。

```sh
dependency-check ... --noupdate || true
chmod -R 777 /opt/dependency-check/data
rm -f dependency-check-report.json
```

### 5. 後始末

- キーはシェルの環境変数にだけ存在する。作業後は `unset NVD_API_KEY`。
- キーを会話やログに貼った場合は、NVD 側で再発行する。
- `data/` は commit しない。

## 注意

- バージョンを上げるたびに、手順1〜4をやり直す。古い DB は使い回さない。
- arm64 版にも同じ `data/` を使える(QEMU 上で確認済み)。
  H2 のファイル形式は CPU アーキテクチャに依存しないはず。
- `|| true` で失敗を隠さない。DB なしのイメージが成功扱いで出来るため。
- 2026-10-06 に手順1〜4を実行し、x64 版で検証済み。
  取得は約3時間、`odc.mv.db` は 239MB(defrag 後)。
  ビルドしたイメージでは、キーなし・`--noupdate` でスキャンが完了し、26件を検出した。
  `docker history` と環境変数にキーは残っていない。イメージサイズは 1.46GB。
- arm64 版も同じ `data/` で検証済み(QEMU 上でビルド・スキャン。26件検出、キー残留なし)。実機の arm64 では未確認。

## 失敗例(参考)

| エラー | 原因 |
|---|---|
| `Autoupdate is disabled and the database does not exist` | `--noupdate` で DB が無い |
| `Invalid API Key, length of 0 too short ...` | キーが空文字で渡された |
| `Invalid API Key: xxxxx-*****-xxxxx` | NVD がキーを拒否した(未有効化・誤り・失効など) |
| `No documents exist` | NVD の更新に失敗し、DB が空のまま |
