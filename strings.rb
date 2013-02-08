require "benchmark"
require 'erb'

d=Time.now

#parser produces:
  formatters=['abc ','%2.2', ' ','%2.2', ' cdef']
  fields=[:hour, :min, lambda() {|d| d.hour < 12 ? 'am' : 'pm'}]

Benchmark.bm(20) do |x|
  # # the ultimate, but still can't figure out how to generate something that can be interpolated
  # x.report("str") { 100_000.times {
  #     "abc #{d.hour < 10 ? '0' : ''}#{d.hour} #{d.min < 10 ? '0' : ''}#{d.min} cdef"
  # } }

  # #not dynamically constructed
  # x.report("code") { 100_000.times {
  #   'abc ' << (d.send(:hour) < 10 ? '0' : '') << d.send(:hour).to_s << ' ' << (d.send(:min) < 10 ? '0' : '') << d.send(:min).to_s << ' cdef'
  # } }

  x.report("strftime") { 100_000.times {
    d.strftime 'abc %H %M %P cdef'
  } }

  x.report("'' % [s,l]") { 100_000.times {
    'abc %2.2d %2.2d %s cdef' % [d.send(:hour), d.send(:min), d.send(:hour) < 12 ? 'am' : 'pm' ]
  } }

  formatters=['abc ','%2.2', ' ','%2.2', ' cdef'].join
  fields=[:hour, :min, :hour]
  #using formatted % formatters

  x.report("'' % map{s}") { 100_000.times {
    'abc %2.2d %2.2d %s cdef' % fields.map {|f| d.send(f) }
  } }
  fields=[:hour, :min, :min]
  x.report("'' % map(?s:l) f") { 100_000.times {
    'abc %2.2d %2.2d %d cdef' % fields.map {|f| f.is_a?(Symbol) ? d.send(f) : f.call(d) }
  } }

  fields=[:hour, :min, lambda() {|d| d.hour < 12 ? 'am' : 'pm'}]
  x.report("'' % map(?s:l) t") { 100_000.times {
    'abc %2.2d %2.2d %s cdef' % fields.map {|f| f.is_a?(Symbol) ? d.send(f) : f.call(d) }
  } }

  fields=[lambda() {|d| d.hour}, lambda() {|d| d.min}, lambda() {|d| d.hour < 12 ? 'am' : 'pm'}]
  x.report("'' % map(l) t") { 100_000.times {
    'abc %2.2d %2.2d %s cdef' % fields.map {|f| f.call(d) }
  } }

  # # using a static proc to generate the output
  # x.report("proc{} prep") { 100_000.times {
  #   ops=proc {|d| 'abc ' << (d.hour < 10 ? '0' : '') << d.send(:hour).to_s << ' ' << (d.hour < 10 ? '0' : '') << d.send(:min).to_s << ' cdef' }
  # } }
  # ops=proc {|d| 'abc ' << (d.hour < 10 ? '0' : '') << d.send(:hour).to_s << ' ' << (d.hour < 10 ? '0' : '') << d.send(:min).to_s << ' cdef' }
  # x.report("proc{}") { 100_000.times {
  #   ops.call(d)
  # } }

  # # using eval to generate the proc with formatters
  # x.report("e(proc{}) prep") { 100_000.times {
  #   ops=eval %{proc {|d| 'abc ' << (d.hour < 10 ? '0' : '') << d.send(:hour).to_s << ' ' << (d.hour < 10 ? '0' : '') << d.send(:min).to_s << ' cdef' }}
  # } }
  # ops=eval %{proc {|d| 'abc ' << (d.hour < 10 ? '0' : '') << d.send(:hour).to_s << ' ' << (d.hour < 10 ? '0' : '') << d.send(:min).to_s << ' cdef' }}
  # x.report("e(proc{})") { 100_000.times {
  #   ops.call(d)
  # } }

  # ops = proc {|d| 'abc %2.2d %2.2d cdef' % [d.hour, d.min] }
  # x.report("proc{%}") { 100_000.times {
  #   ops.call(d)
  # } }

  # x.report("strftime") { 100_000.times {
  #   d.strftime 'abc %H %M cdef'
  # } }

  # x.report("e(proc{%}) prep") { 100_000.times {
  #   ops=eval %{proc {|dd| 'abc %2.2d %2.2d cdef' % [dd.hour, dd.min]}}
  # } }

  # ops=eval %{proc {|dd| 'abc %2.2d %2.2d cdef' % [dd.hour, dd.min]}}
  # x.report("e(proc{%})") { 100_000.times {
  #   ops.call(d)
  # } }

  # ops=[:hour, :min]
  # x.report("%[]") { 100_000.times {
  #   'abc %2.2d %2.2d cdef' % ops.map {|v| d.send(v)}
  # } }

  # ops=[:hour, :min]
  # x.report("%[?]") { 100_000.times {
  #   values=ops.map {|v| v.is_a?(Symbol) ? d.send(v) : v }
  #   'abc %2.2d %2.2d cdef' % values
  # } }

  # x.report("%[proc] prep") { 100_000.times {
  #   ops=[] << proc {|dd| dd.hour} << proc {|dd| dd.min}
  # } }
  # ops=[] << proc {|dd| dd.hour} << proc {|dd| dd.min}
  # x.report("%[proc]") { 100_000.times {
  #   'abc %2.2d %2.2d cdef' % ops.map { |v| v.call(d)}
  # } }

  # x.report("e(%[proc]) prep") { 100_000.times {
  #   ops=eval %{proc {|dd| [dd.hour, dd.min] } }
  # } }
  # x.report("e(%[proc])") { 100_000.times {
  #   'abc %2.2d %2.2d cdef' % ops.call(d)
  # } }

  # x.report("name%") { 100_000.times {
  #   'abc %2.2<hour>d %2.2<min>d cdef' % { hour: d.hour, min: d.min }
  # } }

  # x.report("name%[] pre") { 100_000.times {
  #   ops=[:hour, :min]
  # } }
  # ops=[:hour, :min]
  # x.report("name%[]") { 100_000.times {
  #   values={} ; ops.each {|op| values[op]=d.send(op) }
  #   'abc %2.2<hour>d %2.2<min>d cdef' % values
  # } }

  # # ops='abc #{hour} #{min} cdef'
  # # x.report("N - template1") { 100_000.times {
  # #   ops.gsub(/\#\{(\w+)\}/) { d.send($1) }
  # # } }

  # x.report("eval") { 100_000.times {
  #   eval '"abc #{d.hour < 10 ? "0" : ""}#{d.hour} #{d.min < 10 ? "0" : ""}#{d.min} cdef"'
  # } }

  # x.report("erb pre") { 100_000.times {
  #   ops=ERB.new("abc <%= d.hour %> <%= d.min %> cdef")
  # } }
  # x.report("erb") { 100_000.times {
  #   ops.result(binding)
  # } }
end
