module Stamp
  class Emitter
    attr_accessor :field
    attr_accessor :legacy
    attr_accessor :formatter
    def initialize(field=nil, legacy=nil, &block)
      @field=field
      @legacy=legacy
      @formatter=block || lambda() {|d| d.send(@field) }
    end

    def format(d)
      #@formatter.call(d.send(@field))
      @formatter.call(d)
    end
    alias :call :format
    def inspect ; "[#{field||self.class.name} (#{legacy})]" ; end
    def blank? ; false ; end
  end

  class CompositeEmitter < Emitter
    include Enumerable
    attr_accessor :emitters

    def initialize(emitters=nil)
      super(nil)
      @emitters=[]
      self << emitters if emitters
    end

    def format(d)
      @emitters.map {|e| e.format(d)}.join('')
    end
    alias :call :format

    def <<(emitter)
      if emitter.is_a?(Enumerable)
        emitter.each {|e| self << e }
      elsif ! emitter.is_a?(Emitter)
        raise "not an emitter: #{emitter.nil? ? "nil" : emitter}"
      elsif @emitters.last.is_a?(StringEmitter) && emitter.is_a?(StringEmitter)
        @emitters.last << emitter
      else
        @emitters << emitter unless emitter.blank?
      end
    end

    def each(&block) ; @emitters.each(&block) ; end

    def blank? ; @emitters.empty? ; end

    def inspect
      "ce[#{@emitters.map {|e| e.inspect}.join(",")}]"
    end
  end

  class StringEmitter < Emitter
    attr_accessor :value

    def initialize(value=' ')
      super(nil,value) { |d| value }
      @value=value
    end
    def <<(other)
      @value << other.value unless other.blank?
    end

    def blank? ; @value.nil? || @value == ''; end

    def inspect ; "[='#{@value}']" ; end
  end
end
