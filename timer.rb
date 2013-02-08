require "benchmark"
require "stamp"

STRFTIME="%B %d, %Y at %H:%M %p %Z"
STAMP="December 14, 2012 at 12:29 am GMT"
now=Time.now
# es=now.stamp_emitters(STAMP)
# es.each {|e|
#   puts "#{e.class} \"#{e.is_a?(Stamp::Emitters::String) ? e.value : nil}\""
# }
puts now.stamp(STAMP)
puts now.strftime(STRFTIME)

Benchmark.bm(8) do |x|
  #strftime 0.19 - 0.20
  x.report("strftime:") do
    (1..100_000).each do
      now.strftime(STRFTIME)
    end
  end
  #rip-strftime 1.29 - 1.33 (~1.30)
  #no_percents 0.88 - 0.91 (~0.89)
  #no_modifiers 0.50
  2.times do |i|
    x.report("stamp#{i}:") do
      (1..100_000).each do
        now.stamp(STAMP)
      end
    end
  end
end

#0.19