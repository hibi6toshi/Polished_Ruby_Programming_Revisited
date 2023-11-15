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

class Invoice
  def total_tax
    @total_tax ||= @tax_rate * @line_items.sum do |item|
      item.price * item.quantity
    end
  end
end

class Invoice
  def total_tax
    return @total_tax if defined?(@total_tax)

    @total_tax ||= @tax_rate * @line_items.sum do |item|
      item.price * item.quantity
    end
  end
end

class Invoice
  def line_item_taxes
    @line_items.map do |item|
      @tax_rate * item.price * item.quantity
    end
  end
end

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

class Invoice
  def line_item_taxes
    tax_rate = @tax_rate
    @line_items.map do |item|
      tax_rate * item.price * item.quantity
    end
  end
end
