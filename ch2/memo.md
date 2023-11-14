# 役に立つ独自クラスを定義する

## いつ独自クラスを定義すべきか（2.1）

独自クラスを定義する利点は 2 つある。
1 つは、状態のカプセル化です。カプセル化することで、オブジェクトの状態の操作を「そのオブジェクトの通りにのっとった方法」だけに限定できます。
もう一つの利点は、「クラスのインスタンスに関連づけられた関数」を呼び出すためのシンプルな方法を提供できることです。

ロジックを独自クラスにカプセル化する。

```
stack.unshift!(2)
のような意図しない挙動をさせない

class Stack
  def initialize
    @stack = []
  end

  def push(value)
    @stack.push(value)
  end

  def pop
    @stack.pop
  end
end
```

## SOLID 原則のトレードオフ（2.2）

### 単一責任の原則（2.2.1）

単一責任の原則に従ってクラスを分割すべきかを判断するには、こう自問すると良いでしょう。
**「新しく分割したクラスには、アプリケーションやライブラリで他にも使い所があるだろうか？」**
答えがイエスなら、クラスを分割しても良さそうです。

**「このクラスを部分的に別の実装で簡単に置き換えたいだろうか」**と自問するのも良い。

### リスコフの置換原則（2.2.3）

リスコフの置換原則の主張は、「型 T のオブジェクトを使っている場所ならどこであっても、型 T のサブクラスで置き換えられるべき」と言うものです。
一般原則としてこれに従うのはいいことです。
以下の Max クラスの over?メソッドは、渡された引数が最大値を超えているかどうかを判定します。

```
class Max
  def initialize(max)
    @max = max
  end

  def over?(n)
    @max < n
  end
end
```

このサブクラスを定義して over?をオーバーライドします。その際に、「最大値を超過しなければならない大きさ」を別の引数として要求すると、リスコフの置換原則を破ることになります。

```
class MaxBy < Max
  def over?(n, by)
    @max + by < n
  end
end
```

Max のインスタンスを受け取って over? を呼び出すコードが渡す引数は 1 つです。
ここに MaxBy のインスタンスが渡されると壊れてしまいます。リスコフの置換原則を満たすためには、引数をオプショナル位置引数かキーワード引数として定義します。

```
class MaxBy < Max
  def over?(n, by: 0)
    @max + by < n
  end
end
```

こうすれば MaxBy のインスタンスを渡しても動作します。

場合によっては、「壊れるなら渡さない」アプローチを考える。2 つの引数が必須である MaxBy#over?を定義して、Max のインスタンスが期待されているところには MaxBy のインスタンスを渡さないようにする。

### 依存関係逆転の原則（2.2.5）

依存関係逆転の原則の主張は「高レイヤのモジュールは低レイヤのモジュールに依存してならず、高レイヤのモジュールも低レイヤのモジュールも抽象に依存すべきである」あるいは、「抽象は実装である具象には依存してはならず、実装である具象は抽象に依存すべきである」と言うものです。

DI（Dependency Injection）は依存関係逆転の原則の具体的な実装の 1 つです。
本日の日付を表す CurrentDay クラスがあるとします。このクラスには、「その日の勤務時間」を返す work_hours メソッドと、「本日が稼働日か非稼働日か」を判定する workday?メソッドがあります。
このアプリケーションには、稼働予定を把握する MonthlySchedule クラスがあり、対象となる年と月で初期化します。これを単純に実装したサンプルコードを示します。

```
class CurrentDay
  def initialize
    @date = Date.today
    @schedule = MonthlySchedule.new(@date.year, @date.month)
  end

  def work_hours
    @schedule.work_hours_for(@date)
  end

  def workday?
    !@schedule.holidays.include?(@date)
  end
end
```

この実装には、「CurrenDay のテストが難しい」と言う問題があります。workday?のテストはどうすればできるでしょうか。テストを実行した当日が稼働日であれば true が返ってきますが、もし非稼働日だと、false が返ってきます。

CurrentDay 自体には手を加えずにこの問題に対処する方法の一つは、テスト実行時に Date.today を上書きすることです。

```
before do
  Date.singleton_class.class_eval do
    alias_method :_today, :today
    define_method(:today) { Date.new(2020, 12, 16) }
  end
end

after do
  Date.singleton_class.class_eval do
    alias_method :today, :_today
    remove_method :_today
  end
end
```

この方法だと、テストをマルチスレッドで実行して速度を向上させることができません。単に instance_variable_set を使うだけでテスト実行時にインスタンス変数に手を加えられる場合もあります。今回は、@date が initialize メソッドで＠schedule を設定するために使われているため無理。

こうした状況では、**特定の日付を引数で指定できるようにするのが順当です。その用途にはキーワード引数が向いています。**キーワード引数にしておけば、後から別の位置引数が必要になっても対応できます。

```
class CurrentDay
  def initialize(date: Date.today)
    @date = date
    @schedule = MonthlySchedule.new(date.year, date.month)
  end
end
```

## 大きなクラスか、多くのクラスか(2.2.3)

クラス設計にあたって求められる判断の一つに、「クラスの数をどれくらいにするか」があります。クラスの数を少なくする利点は、一般的には「コード概念的にシンプルになる」ことです。クラスの数を多くする利点は、「コードがモジュール化されるので部分ごとに変更しやすくなる」ことです。
これらの間でバランスを取る必要があります。

以下で、大きなクラス・多いクラスのバランスを探る。

HTML の表を組み立てるライブラリを作っているとしましょう。このライブラリは、表載せると行を表現する「Enumerable オブジェクト（セル）の Enumerable オブジェクト（行）」を受け取って、HTML 要素の table、tbody、tr、td を使って表を組み立てます。td 要素の内容は HTML エスケープします。

これを単一クラスで設計してみます。このクラスはテーブルの行データで初期化します。

```
class HTMLTable
  def initialize(rows)
    @rows = rows
  end

  # to_s メソッドを定義して、　@rowsをHTML文字列に変換するのが一番単純な実装です。
  def to_s
    html = String.new
    html << '<table><tbody>'

    @rows.each do |rows|
      html << '<tr>'
      rows.each do |cell|
        html << '<td>' << CGI.escapeHTML(cell.to_s) << '</td>'
      end
      html << '</tr>'
    end
    html << '</tbody></table>'
  end
end
```

n こお単一クラスの設計では、すべてのロジックが単一のメソッドに書かれています。実行速度はおそらく最速だが、いちいち文字列を連結しているので、見た目は良くありません。

HTML 要素ごとにクラスを分けることで改善できないでしょうか？
メタプログラングにより、比較的簡単にそのような要素ごとにクラスをわけて書けます。
to_s メソッドを持った基底クラスを用意し、HTML 要素ごとにサブクラスを定義して文字列を整形するようにしましょう。

```

class HTMLTable
  class Element
    def self.set_type(type)
      define_method(:type) { type }
    end

    def initailize(data)
      @data = data
    end
  end

  # 4つのHTML要素それぞれに対応するサブクラスはメタプログラミングで定義できます。
  %i[table tbody tr td].each do |type|
    klass = Class.new(Element)
    klass.set_type(type)
    const_set(type.capitalize, klass)
  end

  # HTML要素に対するElementのサブクラスのインスタンスを、適切な入れ子にして作成します。
  def to_s
    Table.new(
      Tbody.new(
        @rows.map do |row|
          Tr.new(
            row.each do |cell|
              Td.new(CGI.escapeHTML(cell.to_s))
            end.join
          )
        end.join
      )
    ).to_s
  end
end
```

この設計ではクラスを 6 つ使います。HTMLTable クラスと基底クラスである Element、そして、メタプログラミングで定義した Element のサブクラスである Table、Tbody、Tr、Td です。それぞれのクラスが担う責務は 1 つだけなので、単一原則をしっかり守っています。
この設計の見どころは、HTML の生成がすべて 1 箇所に纏まっているところです。一方でこの設計には、複雑すぎることに加えて、実行速度も遅くなりそうと言う問題があります。

生成するオブジェクト数が増えるのはもちろんですが、何かにつけて一時的な文字列を生成しているからです。
例えば、あるセルに巨大なデータが混じると、以下の箇所に巨大なセルデータの文字列が含まれることから、メモリ使用量がそのセルデータの八倍以上になります。

- 巨大なセルデータの文字列
- CGI.escapeHTML で生成される文字列
- HTMLTable::Td#to_s で生成される文字列
- Td インスタンスの配列を結合する際に HTMLTable#to_s で生成される文字列
- HTMLTable::Tr#to_s 　で生成される文字列
- Tr インスタンスの配列を結合する際に HTMLTable#to_s で生成される文字列
- HTMLTable::Tbody#to_s で生成される文字列
- HTMLTable::Table#to_s で生成される文字列

文字列を追記するだけの設計の実行性能を維持しつつ、HTML 文字列を 1 カ所で組み立てるようにすることは可能でしょうか？
wrap メソッドを用意し、「生成対象の HTML 文字列」と「HTML 要素の種類」を受け取るようにします。そして、HTML タグの開始と終了の間でブロックを yield すれば、HTML 文字列の生成を追記専用の設計で実現できます。

```
class HTMLTable
  def wrap(html, type)
    html << '<' << type << '>'
    yield
    html << '<' << type << '>'
  end

  # to_s メソッドではwrapメソッドを入れ子にして呼び出します。
  def to_s
    html = String.new
    wrap(html, 'table') do
      wrap(html, 'tbody') do
        @rows.each do |row|
          wrap(html, 'tr') do
            row.each do |cell|
              wrap(html, 'td') do
                html << CGI.escapeHTML(cell.to_s)
              end
            end
          end
        end
      end
    end
  end
end
```

この設計は当初の設計よりは複雑になりますが、実行性能はほとんど変わりません。後から拡張するのも簡単です。例えば、table、tbody、tr、td それぞれの要素であ HTML 属性が必要になったとしても簡単に対応できます。

クラスを分割する設計が有用なケースもあります。例えばユーザー側で独に HTML 要素を扱えるようにしたくなるかもしれません。HTML の表全体ではなく、table や tbody タグが使われている状況であれば、こうした機能があることが望ましいかもしれません。
