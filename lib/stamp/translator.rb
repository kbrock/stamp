module Stamp
  class StrftimeTranslator
    MONTHNAMES_REGEXP      = /^(#{Date::MONTHNAMES.compact.join('|')})$/i
    ABBR_MONTHNAMES_REGEXP = /^(#{Date::ABBR_MONTHNAMES.compact.join('|')})$/i
    DAYNAMES_REGEXP        = /^(#{Date::DAYNAMES.join('|')})$/i
    ABBR_DAYNAMES_REGEXP   = /^(#{Date::ABBR_DAYNAMES.join('|')})$/i

    # Full list of time zone abbreviations from http://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
    TIMEZONE_REGEXP        = /^(ACDT|ACST|ACT|ADT|AEDT|AEST|AFT|AKDT|AKST|AMST|AMT|ART|AST|AST|AST|AST|AWDT|AWST|AZOST|AZT|BDT|BIOT|BIT|BOT|BRT|BST|BST|BTT|CAT|CCT|CDT|CDT|CEDT|CEST|CET|CHADT|CHAST|CHOT|ChST|CHUT|CIST|CIT|CKT|CLST|CLT|COST|COT|CST|CST|CST|CST|CST|CT|CVT|CWST|CXT|DAVT|DDUT|DFT|EASST|EAST|EAT|ECT|ECT|EDT|EEDT|EEST|EET|EGST|EGT|EIT|EST|EST|FET|FJT|FKST|FKT|FNT|GALT|GAMT|GET|GFT|GILT|GIT|GMT|GST|GST|GYT|HADT|HAEC|HAST|HKT|HMT|HOVT|HST|ICT|IDT|IOT|IRDT|IRKT|IRST|IST|IST|IST|JST|KGT|KOST|KRAT|KST|LHST|LHST|LINT|MAGT|MART|MAWT|MDT|MET|MEST|MHT|MIST|MIT|MMT|MSK|MST|MST|MST|MUT|MVT|MYT|NCT|NDT|NFT|NPT|NST|NT|NUT|NZDT|NZST|OMST|ORAT|PDT|PET|PETT|PGT|PHOT|PHT|PKT|PMDT|PMST|PONT|PST|PST|RET|ROTT|SAKT|SAMT|SAST|SBT|SCT|SGT|SLT|SRT|SST|SST|SYOT|TAHT|THA|TFT|TJT|TKT|TLT|TMT|TOT|TVT|UCT|ULAT|UTC|UYST|UYT|UZT|VET|VLAT|VOLT|VOST|VUT|WAKT|WAST|WAT|WEDT|WEST|WET|WST|YAKT|YEKT)$/

    ONE_DIGIT_REGEXP       = /^\d{1}$/
    TWO_DIGIT_REGEXP       = /^\d{2}$/
    FOUR_DIGIT_REGEXP      = /^\d{4}$/

    TIME_REGEXP            = /(\d{1,2})(:)(\d{2})(\s*)(:)?(\d{2})?(\s*)?([ap]m)?/i

    MERIDIAN_LOWER_REGEXP  = /^(a|p)m$/
    MERIDIAN_UPPER_REGEXP  = /^(A|P)M$/

    ORDINAL_DAY_REGEXP     = /^(\d{1,2})(st|nd|rd|th)$/

    # supporting basic ones, not sure how extensive to make this
    LEGACY = {
      '%A' => Emitter.new(:wday, '%A')  { |d| Date::DAYNAMES[d.wday] },
      '%B' => Emitter.new(:month, '%B') { |d| Date::MONTHNAMES[d.month] },
      '%H' => Emitter.new(:hour, '%H')  { |d| "%2d" % d.hour }, # 24-hour clock
      '%I' => Emitter.new(:hour, '%I')  { |d| "%2.2d" % ((d.send(:hour) -1) % 12 +1) }, # 12-hour clock with leading zero
      '%M' => Emitter.new(:min, '%M')   { |d| "%2.2d" % d.min },
      '%P' => Emitter.new(:hour, '%P')  { |d| d.hour < 12 ? "am" : "pm" },
      '%S' => Emitter.new(:sec, '%S')   { |d| "%2.2d" % d.sec },
      '%Y' => Emitter.new(:year, '%Y')  { |d| d.year },
      '%Z' => Emitter.new(:zone, '%Z'),
      '%a' => Emitter.new(:wday, '%a')  { |d| Date::ABBR_DAYNAMES[d.wday] },
      '%b' => Emitter.new(:month, '%b') { |d| Date::ABBR_MONTHNAMES[d.month] },
      '%d' => Emitter.new(:day, '%d')   { |d| "%2.2d" % d.day },
      '%e' => Emitter.new(:day, '%e')   { |d| "%2d" % d.day }, # day without leading zero
      '%l' => Emitter.new(:hour, '%l')  { |d| "%2d" % ((d.send(:hour) -1) % 12 +1) }, # hour without leading zero (but leading space)
      '%m' => Emitter.new(:month, '%m') { |d| "%2.2d" % d.month },
      '%p' => Emitter.new(:hour, '%P')  { |d| d.hour < 12 ? "AM" : "PM" },
      '%y' => Emitter.new(:year, '%y')  { |d| "%2.2d" % (d.year % 100) }
    }

    # Disambiguate based on value
    OBVIOUS_YEARS          = 60..99
    OBVIOUS_MONTHS         = 12
    OBVIOUS_DAYS           = 13..31
    OBVIOUS_24_HOUR        = 13..23

    OBVIOUS_DATE_MAP = {
      OBVIOUS_YEARS  => LEGACY['%y'],
      OBVIOUS_MONTHS => LEGACY['%m'],
      OBVIOUS_DAYS   => LEGACY['%d']
    }

    TWO_DIGIT_DATE_SUCCESSION = {
      :month => LEGACY['%d'],
      :day   => LEGACY['%y'],
      :year  => LEGACY['%m']
    }

    TWO_DIGIT_TIME_SUCCESSION = {
      :hour  => LEGACY['%M'],
      :min   => LEGACY['%S']
    }

    def translate(example)
      # extract any substrings that look like times, like "23:59" or "8:37 am"
      before, time_example, after = example.partition(TIME_REGEXP)

      # transform any date tokens to strftime directives
      words = CompositeEmitter.new
      words << strftime_directives(before.split(/([0-9a-zA-Z]+|%[a-zA-Z])/)) do |token, previous_part|
        strftime_date_directive(token, previous_part)
      end

      # transform the example time string to strftime directives
      unless time_example.empty?
        time_parts = time_example.scan(TIME_REGEXP).first
        words << strftime_directives(time_parts) do |token, previous_part|
          strftime_time_directive(token, previous_part)
        end
      end

      # recursively process any remaining text
      words << translate(after) unless after.empty?
      words
    end

    # Transforms tokens that look like date/time parts to strftime directives.
    def strftime_directives(tokens)
      previous_part = nil
      tokens.map do |token|
        directive = yield(token, previous_part)
        previous_part = directive.field unless directive.nil?
        directive || LEGACY[token] || StringEmitter.new(token||'')
      end
    end

    def strftime_time_directive(token, previous_part)
      case token
      when MERIDIAN_LOWER_REGEXP
        LEGACY['%P']
      when MERIDIAN_UPPER_REGEXP
        LEGACY['%p']
      when TWO_DIGIT_REGEXP
        TWO_DIGIT_TIME_SUCCESSION[previous_part] ||
          case token.to_i
          when OBVIOUS_24_HOUR
            LEGACY['%H']
          else
            LEGACY['%I']
          end

      when ONE_DIGIT_REGEXP
        LEGACY['%l']
      end
    end

    def strftime_date_directive(token, previous_part)
      case token
      when MONTHNAMES_REGEXP
        LEGACY['%B']

      when ABBR_MONTHNAMES_REGEXP
        LEGACY['%b']

      when DAYNAMES_REGEXP
        LEGACY['%A']

      when ABBR_DAYNAMES_REGEXP
        LEGACY['%a']

      when TIMEZONE_REGEXP
        LEGACY['%Z']

      when FOUR_DIGIT_REGEXP
        LEGACY['%Y']

      when ORDINAL_DAY_REGEXP
        Emitter.new(:day, '%TH') do |d|
          number=d.day
          if number.to_i % 100 / 10 == 1
            "#{number}th"
          else
            case number.to_i % 10
            when 1; "#{number}st"
            when 2; "#{number}nd"
            when 3; "#{number}rd"
            else    "#{number}th"
            end
          end
        end

      when TWO_DIGIT_REGEXP
        value = token.to_i

        obvious_mappings =
          OBVIOUS_DATE_MAP.reject { |k,v| v.field == previous_part }

        obvious_directive = obvious_mappings.find do |range, directive|
          break directive if range === value
        end

        # if the intent isn't obvious based on the example value, try to
        # disambiguate based on context
        obvious_directive ||
          TWO_DIGIT_DATE_SUCCESSION[previous_part] ||
          LEGACY['%m']

      when ONE_DIGIT_REGEXP
        LEGACY['%e']
      end
    end
  end
end
