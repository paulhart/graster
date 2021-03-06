#!/usr/bin/ruby

unless ARGV.size == 5
  puts "usage: ruby tile.rb <input-gcode-file> <tile-width> <tile-height> <horiz-count> <vert-count>"
  exit(1)
end

def parse_line line
  nc = {}
  line.gsub(/\([^)]*\)/,'').upcase.scan(/([A-Z])\s*([0-9\.]+)?/).each {|code| nc[code[0].intern] = (code[1] && code[1].to_f) }
  nc
end

def gcode ncs
  ncs = [ncs] unless ncs.is_a? Array
  ncs.reduce('') {|a,nc| a << (nc.map {|k,v| "#{k}#{v}" }.join(' ') + "\n") }
end

tile_width = ARGV[1].to_f
tile_height = ARGV[2].to_f
horiz_count = ARGV[3].to_i
vert_count = ARGV[4].to_i

header = []
body = []
footer = []
state = :header


File.open ARGV[0] do |io|
  io.each_line do |line|
    if (nc = parse_line(line)) != {}
      case state
      when :header
        if nc[:G] == 0 || nc[:G] == 1
          state = :body
          body << nc
        else
          header << nc
        end

      when :body
        if nc[:G] == 0 || nc[:G] == 1
          body << nc
        else
          state = :footer
          footer << nc
        end

      when :footer
        footer << nc
      end
    end # case
    
  end # io.each_line
end # File.open

print gcode(header)

vert_count.times.map do |yc|
  horiz_count.times.map do |xc|
    body.each do |nc|
      nc = nc.dup
      nc[:X] += xc*tile_width if nc[:X]
      nc[:Y] += yc*tile_height if nc[:Y]
      print gcode(nc)
    end
  end
end

print gcode(footer)
