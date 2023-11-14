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

class Max
  def initialize(max)
    @max = max
  end

  def over?(n)
    @max < n
  end
end

class MaxBy < Max
  def over?(n, by)
    @max + by < n
  end
end

class Maxby < Max
  def over?(n, by: 0)
    @max + by < n
  end
end

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

class CurrentDay
  def initialize(date: Date.today)
    @date = date
    @schedule = MonthlySchedule.new(date.year, date.month)
  end
end

require 'cgi/escape'

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
