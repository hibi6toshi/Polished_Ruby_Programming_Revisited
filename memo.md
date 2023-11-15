1syou

```
flat_map

album_infos.each do |album, track, artist|
  ((albums[album] ||= {})[track] ||= []) << artist
end

albums.dig(album, track)

each_value

select
```

3 章

```
time_filert = TimeFilter.new(Time.local(2020,10),
                             Time.local(2020,11))
array_of_times.filter!(&time_filter)

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
