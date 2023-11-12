'a'.gsub!('b', '')
# -> nil

[2, 4, 6].select!(&:even?)
# -> nil

%w[a b c].reject!(&:empty?)
# -> nil

string = '...'
if string.gsub!('a', 'b')
  # 文字列が変更された場合
end

string
  .gsub!('a', 'b')
  .downcase!

@cached_value ||= some_expression
# または
cache[:key] ||= some_expression

if defined?(@cached_value)
  @cached_value
else
  @cached_value = some_expression
end

cache.fetch(:key) { cache[:key] = some_expression }

album_infos = 100.times.flat_map do |i|
  10.times.map do |j|
    ["album #{i}", j, "Artist #{j}"]
  end
end

album_artists = {}
album_track_artists = {}
album_infos.each do |album, track, artist|
  (album_artists[album] ||= []) << artist
  (album_track_artists[[album, track]] ||= []) << artist
end
album_artists.each_value(&:uniq!)

lookup = lambda do |album, track = nil|
  if track
    album_track_artists[[album, track]]
  else
    album_artists[album]
  end
end

albums = {}
album_infos.each do |album, track, artist|
  ((albums[album] ||= {})[track] ||= []) << artist
end

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

albums = {}
album_infos.each do |album, track, artist|
  album_array = albums[album] ||= [[]]
  album_array[0] << artist
  (album_array[track] ||= []) << artist
end
albums.each_value do |array|
  array[0].uniq!
end

lookup = lambda do |album, track = 0|
  albums.dig(album, track)
end

album_artists = album_infos.flat_map(&:last)
album_artists.uniq!

lookup = lambda do |artist|
  album_artists & artist
end

album_artists = {}
album_infos.each do |_, _, artist|
  album_artists[artist] ||= true
end

lookup = lambda do |artists|
  artists.each do |artist|
    album_artists[artist]
  end
end

album_artists = Set.new(album_infos.flat_map(&:last))

lookup = lambda do |artists|
  album_artist & artists
end

A = Struct.new(:a, :b) do
  def initialize(...)
    super
    freeze
  end
end
