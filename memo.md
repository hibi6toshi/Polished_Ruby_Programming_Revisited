1 章

```
flat_map

album_infos.each do |album, track, artist|
  ((albums[album] ||= {})[track] ||= []) << artist
end

albums.dig(album, track)

each_value

select
```
