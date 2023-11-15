class Screen
  def draw_box(x1:, y1:, x2:, y2:); end
end

class Screen
  def draw_box(_x1 = nil, _y1 = nil, _x2 = nil, _y2 = nil,
               x1: _x1, y1: _y1, x2: _x2, y2: _y2)
    raise ArgmentError unless x1 && y1 && x2 && y2
  end
end

def a(x, y = 2, z)
  [x, y, z]
end
a(1, 3)
# -> [1, 2, 3]

eval(<<END)
  def a(x=1 , y, z=2)
  end
END
# 構文エラー

def a(x, y = nil); end

def a(x = nil, y); end

def identifier(column, table = nil); end

def identifier(table = nil, column); end

def foo(bar, *); end

def foo(bar, *)
  bar = 2
  super
end

def a(x, *y); end

def a(x, y = nil, *z); end

def a(*y, z); end

def mv(source, *sources, dir)
  sources.unshift(source)
  sources.each do |source|
    move_into(source, dir)
  end
end

def foo(options = {}); end

def foo(bar: nil); end

# ハッシュは生成されない
foo
foo(bar: 1)

# これはハッシュが生成される
hash = { bar: 1 }

# Ruby3.0 では、キーワード変数を展開してもハッシュは生成されない
foo(**hash)

foo(baz: 1)
# unknown keyword: :baz (ArgumentError)

def foo(*args, **kwargs)
  [args, kwargs]
end

# キーワードがキーワードとして扱われている。
foo(bar: 1)
# -> [[], [bar: 1]]

# ハッシュは位置引数として扱われる
foo({ bar: 1 })
# -> [[{:bar=>1}], {}]

def foo(bar, **nil); end

def foo(bar)
  yield(bar, @baz)
end

foo(1) do |bar, baz|
  bar + baz
end

def foo(bar)
  yield(bar, @baz, @initial || 0)
end

foo(1) do |bar, baz|
  bar + baz
end

foo(1) do |bar, baz, _initial|
  bar + baz
end

adder = lambda do |bar, baz|
  bar + baz
end

# 以前は動いていたが、壊れてしまう。
foo(1, &adder)

def foo(bar, include_initial: false)
  if include_initial
    yield(bar, @baz, @initial || 0)
  else
    yield(bar, @baz)
  end
end

def foo(bar, &block)
  case block.arity
  when 2, -1, -2
    yield(bar, @baz)
  else
    yield(bar, @baz, @initial || 0)
  end
end

require 'forwardable'

class A
  extend Forwardable
  def_delegators :b, :foo
end

class A
  extend Forwardable
  def_delegators :@b, :foo
  def_delegators 'A::B', :foo
end

class A
  extend Forwardable
  def_delegators :b, :foo, :bar, :baz
end
