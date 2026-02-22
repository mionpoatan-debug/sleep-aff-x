# sleep-aff-x

X睡眠グッズ比較（キュレーション型）

## 楽天アフィリンク自動運用

1. `data/rakuten_links.csv` の `rakuten_url` 列に `https://hb.afl.rakuten.co.jp/...` を貼る
2. `bash scripts/publish_rakuten.sh "message"` を実行する

`scripts/publish_rakuten.sh` は次を順に実行します。
- `site/index.html` の `data-rakuten-key` を使って楽天リンクを一括反映
- `site/index.html` を `index.html` に同期
- URL検証（失敗時は終了コード1で停止）
- 検証成功時のみ commit / push
