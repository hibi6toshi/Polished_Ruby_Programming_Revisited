# 組み込みクラスを有効に使う

## true, false, nil を活用する（1.3）

### Ruby の組み込みクラスのメソッドの中には、次のように nil をつかって「呼び出したメソッドのレシーバーに変化がなかった」ことを表すものもある。

```
'a'.gsub!('b', '')
# -> nil

[2, 4, 6].select!(&:even?)
# -> nil

%w[a b c].reject!(&:empty?)
# -> nil
```

この挙動のおかげで、条件分岐と組み合わせることができる。

```
string = '...'
if string.gsub!('a', 'b')
  # 文字列が変更された場合
end
```

これにはトレードオフもある。メソッドチェーンが使えない。

```
string.
  gsub!('a', 'b').
  downcase!
```

gsub!は nil を返す可能性がある。

### nil と false を扱う際に注意すること。

nil や　 false を返す式は　||= 演算子を使った単純なメモ化に使えない。

```
@cached_value ||= some_expression
# または
cache[:key] ||= some_expression
```

some_expression が nil や false であった場合、nil や false 以外を返すまでの間、式は繰り返し評価され続ける。(メモ化が行われないということ)
キャッシュの格納先が単一のインスタンス変数であれば、コードは冗長になるが、次のように defined?を使うのが単純です。

```
if defined?(@cached_value)
  @cached_value
else
  @cached_value = some_expression
end
```

ハッシュを使って複数の値をキャッシュするのであれば、ブロック付きの fetch メソッドを使う方式が単純です。

```
cache.fetch(:key) { cache[:key] = some_expression }
```

## 配列、ハッシュ、セット（集合）を使い分ける（１.５）

アルバム名、曲番号、アーティスト名のリストがあり、同一のアルバムや曲には複数のアーティスト名を登録できます。
これを検索できるシステムを設計します。

2 つのハッシュにデータを移す。
アルバム名をキーにしたハッシュと、アルバム名と曲番号の配列をキーにしたハッシュを用意します。

```
album_artists = {}
album_track_artists = {}
album_infos.each do |album, track, artist|
  (album_artists[album] ||= []) << artist
  (album_track_artists[[album, track]] ||= []) << artist
end
album_artists.each_value(&:uniq!)
```

この方式では検索も簡単です。渡されたキーに応じて適切なハッシュを探索するだけです。

```
lookup = -> (album, track = nil) do
  if track
    album_track_artists[[album, track]]
  else
    album_artists[album]
  end
end
```

別の実装として、ハッシュをネストさせるという方式も考えられます。その場合は、アルバムごとに曲番号ををハッシュとして持たせます。

```
albums = {}
album_infos.each do |album, track, artist|
  ((albums[album] ||= {})[track] ||= []) << artist
end
```

この実装は検索が複雑になります。曲番号が指定されていない場合には、アーティスト名のリストを動的に生成しなければなりません。

```
lookup = lambda do |album, track = nil|
  if track
    albums.dig(album, track)
  else
    a = albums[album].each_value.to_a
    a.flatten!
    a.uniq!
    a
  end
end
```

別の実装。
ここではハッシュの値を「配列の配列」とし、曲を表す配列の要素それぞれに、各曲のアーティスト名の配列を格納します。そして曲番号は 1 から 99 までとわかっているので、曲を表す配列 0 番目にはそのアルバムに関係する全アーティスト名を格納します。

```
albums = {}
album_infos.each do |album, track, artist|
  album_array = albums[album] ||= [[]]
  album_array[0] << artist
  (album_array[track] ||= []) << artist
end
albums.each_value do |array|
  array[0].uniq!
end
```

この実装は先ほどの二番目の実装よりもさらにメモリ効率が向上します。

```
lookup = -> (album, track=0) do
  albums.dig(album, track)
end
```

新機能として、ユーザーがアーティスト名の配列を渡すと、アプリケーションに登録されているアルバムに含まれる収録曲に関わっているアーティスト名と一致する配列を返します。

実装方法の 1 つはアーティスト名を配列に格納しておく方法です。

```
album_artists = album_infos.flat_map(&:last)
album_artists.uniq!
```

検索では、配列同士の積演算により結果が得られます。

```
lookup = -> (artist) do
  album_artists & artist
end
```

検索速度を向上させるには、アーティストをキーにしたハッシュを使います。

```
album_artists = {}
album_infos.each do |_, _, artist|
  album_artists[artist] ||= true
end
```

検索では渡された配列の値を使ってハッシュをフィルタします。

```
lookup = -> (artists) do
  artists.each do |artist|
    album_artists[artist]
  end
end
```

Set を使う。
使い方は、配列からデータ構造を移すだけ。

```
album_artists = Set.new(album_infos.flat_map(&:last))
```

Set は重複した値を無視するので、配列の要素をユニークにしておく必要はありません。検索のコードは配列の場合と全く同じです。

```
lookup = -> (artists) do
  album_artist & artists
end
```

## Struct を活用する（1.7)

一般的に Struct はデータの格納を目的としたシンプルなクラスを作成する用途で用います。Struct の問題点は、その設計がミュータブルなデータ利用を推奨しており、関数的なアプローチを推奨していないことです。
ユーザーにイミュータブルな Struct の使用を強制するのは簡単です。オブジェクトの初期化時に freeze すれば良いのです。

```
A = Struct.new(:a, :b) do
  def initialize(...)
    super
    freeze
  end
end
```
