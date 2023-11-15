# 変数を適切に扱う

## ローカル変数を追加して実行性能を向上させる（3.1.1）

Ruby の他の種類の変数では、ローカル変数より間接層が多く必要になります。必要な間接層が最低限で済むのがローカル変数です。Ruby でローカル変数を参照するときには、変数を格納しているメモリをすぐに参照できます。

例えばい TimeFilter というクラスを作って、そのインスタンスをフィルタリング用のブロックとして使いたいとします。

```
time_filert = TimeFilter.new(Time.local(2020,10),
                             Time.local(2020,11))
array_of_times.filter!(&time_filter)
```

TimeFilter クラスの目的は Enumerable オブジェクトのフィルタリングです。具体的には、第 1 引数と第 2 引数で与えられた時刻の範囲に含まれるオブジェクトだけを抽出します。引数を片方だけ指定した場合は、一方向のフィルタとして機能します。

この挙動を Enumerable にメソッドを追加して実装することもできますが、他のライブラリと併用しやすいライブラリを書くのであれば、組み込みクラスには手を加えない方が良いでしょう。それに、単なるメソッドではなくブロックとしても使えるクラスとして実装しておくと、さまざまメソッドと組み合わせて使えます。

TimeFilter クラスの実装を考えてみましょう。ブロックとしてる解体ので、Proc オブジェクトを返す to_proc メソッドが必要です。戻り値の Proc オブジェクトは、ブロックパラメーターとして渡されてくる value の時刻が、「始点から終点の範囲内であること」をチェックします。このメソッっどで返すのは lambda ではなく proc なので、現在の繰り返しを終わらせて次の繰り返しへと進むには next を使います。

```
class TimeFilter
  attr_reader :start, :finish

  def initialize(start, finish)
    @start = start
    @finish = finish
  end

  def to_proc
    proc do |value|
      next false if start && value < start
      next false if finish && value > finish

      true
    end
  end
end
```

ただし、この実装には実行効率に課題があります。それは to_proc の実装方法です。proc が呼び出されるたび、start を取得するために毎回 attr_reader が呼ばれます。このとき start が存在すれば、「value が start よりも過去の日付かどうか」を比較するために、再び attr_reader が呼ばれます。finish も同様です。
つまり、start と finish の値を取得するためだけに、繰り返し１回ごとに最大４回のメソッド呼び出しが発生しています。このうち少なくとも２回の呼び出しは冗長です。呼び出し結果をローカル変数にキャッシュすれば、この２回の呼び出しは不要になります。

```
class TimeFilter
  def to_proc
    proc do |value|
      start = self.start
      finish = self.finish

      next false if start && value < start
      next false if finish && value > finish

      true
    end
  end
end
```

self をつけて start メソッドを呼び出した結果をローカル変数に格納するようにしました。finish についても同様です。これで attr_reader の呼び出し回数を半分に抑えることができました。

ここからさらに実行性能を改善できます。注目したい点は、TimeFilter がが始点と終点を変更していないことです。何回呼び出しても結果は同じですから、始点と終点の時刻をブロック呼び出しのたびに取得する必然性はありません。ということは、ローける変数への代入は proc よりも前に移せます。変数は proc の内部からでも参照できます。proc はクロージャーなので、proc を包む環境で定義されているローカル変数も取り込まれるからです。

```

class TimeFilter
  def to_proc
    start = self.start
    finish = self.finish

    proc do |value|
      next false if start && value < start
      next false if finish && value > finish

      true
    end
  end
end
```

生成する proc から attr_reader の呼び出しを全て取り除いたので、更なるスピードアップが期待できます。これで proc 内部に残るメソッドの呼び出しは、value における不等号メソッドの呼び出しだけになりました。

start と finish の値は proc を生成する前に取得して変数に格納してあります。この値を使うことで戻り値の proc をもっと効率的にできます。ここで実際の TimeFilter インスタンスの使われ方を考えると、次の４パターンに分類できることがわかります。

- start と finish の両方が指定される
- start だけ指定され、finish は nil である
- finish だけが指定され、start は nil である
- start と finish の両方が nil である

これを踏まえると、それぞれのケースに応じた最適な proc を生成できます。生成される proc も当初のものよりもずっと単純にできます。proc 自体では start や finish の値のバリデーションは不要になるからです。

```
class TimeFilter
  def to_proc
    start = self.start
    finish = self.finish

    if start && finish
      proc { |value| value >= start && value <= finish }
    elsif start
      proc { |value| value >= start }
    elsif finish
      proc { |value| value <= finish }
    else
      proc { |value| value }
    end
  end
end
```

ローカル変数のこうした使い方は、速い Ruby コードを書くための一般原則の一つです。複数回呼ばれるコードでは、メソッド呼び出しの結果を出来るだけ高レイヤーに置いたローカル変数にキャッシュすることで、速度の向上が見込めます。

## インスタンス変数で実行速度を向上させる（３.２.１）

ローカル変数と同じように、インスタンス変数を追加することで実行性能を向上できます。
例えば Invoice（請求書）クラスを考えましょう。このクラスは「LineItem（購入品目）インスタンスの配列」を受け取るとします。それぞれの LineItem には、購入品目の金額や数量といった情報が含まれています。Invoice のインスタンスには、請求書を発行するための合計税額（total_tax）必要です。合計金額は、購入品目の合計金額に税率をかけて算出します。

```
LineItem = Struct.new(:name, :price, :quantity)

class Invoice
  def initialize(line_items, tax_rate)
    @line_items = line_items
    @tax_rate = tax_rate
  end

  def total_tax
    @tax_rate * @line_items.sum do |item|
      item.price * item.quantity
    end
  end
end
```

もし total_tax が、Invoice インスタンスの平均的な生存期間中に 1 回だけしか呼び出されないなら、この値をキャッシュする意味はありません。しかし、total_tax が Invoice インスタンスの生存期間中に何度も呼び出されるのであれば、値をキャッシュすることで実行性能を大幅に改善できます。
典型的な状況であれば、計算結果を直接インスタンス変数に格納するのが一般的です。

```
class Invoice
  def total_tax
    @total_tax ||= @tax_rate * @line_items.sum do |item|
      item.price * item.quantity
    end
  end
end
```

一方、この手法では不従文なケースも存在します。もし、@total_tax が false や nil を返すと、||= 演算子は式を再計算してしまいます。これに対処するには、defined?を使って明示的にインスタンス変数の存在をチェックします。

```
class Invoice
  def total_tax
    return @total_tax if defined?(@total_tax)

    @total_tax ||= @tax_rate * @line_items.sum do |item|
      item.price * item.quantity
    end
  end
end
```

## インスタンス変数のスコープの問題に対処する（３.２.２）

インスタンス変数を扱う際の主な問題は、メソッドに渡すブロックの中で参照するインスタンス変数のスコープを呼び出し側からは制御できないことです。例えば、前のセクションで例として定義した Invoice に line_item_taxes というメソッドを追加して、購入品目ごとの税額からなる配列を得たいとします。
考えられる実装の一つは、購入品目ごとに「合計金額」と「Invoice インスタンスが保持する税率をかける」というものです。

```
class Invoice
  def line_item_taxes
    @line_items.map do |item|
      @tax_rate * item.price * item.quantity
    end
  end
end
```

大抵はこれで問題ありませんが、うまくいかないケースもあります。
このサンプルコードでは@line_items が LineItem のインスタンスの配列であることを想定していますが、必ずしもそうとは限りません。@line_items を確実に LineItem の配列にするには、line_items に渡す引数を、単純な配列ではなく、次のような独自クラスのインスタンスにします。

```
class LineItemList < array
  def initialize(*line_items)
    super(line_items.map do |name, price, quantity|
      LineItem.nre(name, price, quantity)
    end)
  end

  def map(&block)
    super do |item|
      item.instance_eval(&block)
    end
  end
end

Invoice.new(LineItemList.new(['foo', 3, 5r, 10]), 0.095r)
```

このような独自クラスを定義する動機の 1 つは、リテラルを並べた配列から購入品目を簡単に構築するためです。ユーザーの利便性のために、LineItemList クラスには map メソッドを用意しています。このクラスの map では、渡されたブロックを「ブロックパラメーターとして渡す購入品目のコンテキスト」で評価します。こうすることで、ブロックで使うのがローカル変数と購入品目のメソッドだけの場合の処理を簡潔に書けるようになります。

```
line_item_list.map do
  price * quantity
end

以下は同じコードの冗長なバージョンです。
line_item_list.map do |item|
  item.price * item.quantity
end
```

ここでのトレードオフは、ブロック内のスコープが「ブロックの呼び出し側のスコープ」から「購入品目のスコープ」に変わってしまうことです。そのため、先ほどの line_items_taxes メソッドのコードは動かなくなります。この場合、@tax_rate の参照先が invoice の@tax_rate から LineItem の@tax_rate に変わるのですが、LineItem には@tax_rate というインスタンス変数は定義されていません。結果として NoMethodError 例外が発生してしまいます。

```
class Invoice
  def line_item_taxes
    @line_items.map do |item|
      @tax_rate * item.price * item.quantity
    end
  end
end
```

これを回避することはできます。インスタンス変数を参照するローカル変数をあらかじめ用意しておいて、ブロック内部からはそのローカル変数を参照します。こうしておくと、実行性能が改善去る可能性も高くなるので、基本的には良い考えです。

```
class Invoice
  def line_item_taxes
    tax_rate = @tax_rate
    @line_items.map do |item|
      tax_rate * item.price * item.quantity
    end
  end
end
```
