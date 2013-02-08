module Stamp
  class Parser
    MONTHNAMES_REGEXP      = /^(#{Date::MONTHNAMES.compact.join('|')})$/i
    ABBR_MONTHNAMES_REGEXP = /^(#{Date::ABBR_MONTHNAMES.compact.join('|')})$/i
    DAYNAMES_REGEXP        = /^(#{Date::DAYNAMES.join('|')})$/i
    ABBR_DAYNAMES_REGEXP   = /^(#{Date::ABBR_DAYNAMES.join('|')})$/i

    CH_ZODIAK_NAMES        = ['rat', 'ox', 'tiger', 'rabbit', 'dragon', 'snake', 'horse', 'goat', 'monkey', 'rooster', 'dog', 'pig']
    CH_ZODIAK_REGEXP       = /^(#{CH_ZODIAK_NAMES.join('|')})$/i
    # Full list of time zone abbreviations from http://en.wikipedia.org/wiki/List_of_time_zone_abbreviations
    TIMEZONE_REGEXP        = /^(ACDT|ACST|ACT|ADT|AEDT|AEST|AFT|AKDT|AKST|AMST|AMT|ART|AST|AST|AST|AST|AWDT|AWST|AZOST|AZT|BDT|BIOT|BIT|BOT|BRT|BST|BST|BTT|CAT|CCT|CDT|CDT|CEDT|CEST|CET|CHADT|CHAST|CHOT|ChST|CHUT|CIST|CIT|CKT|CLST|CLT|COST|COT|CST|CST|CST|CST|CST|CT|CVT|CWST|CXT|DAVT|DDUT|DFT|EASST|EAST|EAT|ECT|ECT|EDT|EEDT|EEST|EET|EGST|EGT|EIT|EST|EST|FET|FJT|FKST|FKT|FNT|GALT|GAMT|GET|GFT|GILT|GIT|GMT|GST|GST|GYT|HADT|HAEC|HAST|HKT|HMT|HOVT|HST|ICT|IDT|IOT|IRDT|IRKT|IRST|IST|IST|IST|JST|KGT|KOST|KRAT|KST|LHST|LHST|LINT|MAGT|MART|MAWT|MDT|MET|MEST|MHT|MIST|MIT|MMT|MSK|MST|MST|MST|MUT|MVT|MYT|NCT|NDT|NFT|NPT|NST|NT|NUT|NZDT|NZST|OMST|ORAT|PDT|PET|PETT|PGT|PHOT|PHT|PKT|PMDT|PMST|PONT|PST|PST|RET|ROTT|SAKT|SAMT|SAST|SBT|SCT|SGT|SLT|SRT|SST|SST|SYOT|TAHT|THA|TFT|TJT|TKT|TLT|TMT|TOT|TVT|UCT|ULAT|UTC|UYST|UYT|UZT|VET|VLAT|VOLT|VOST|VUT|WAKT|WAST|WAT|WEDT|WEST|WET|WST|YAKT|YEKT)$/

    ONE_DIGIT_REGEXP       = /^\d{1}$/
    TWO_DIGIT_REGEXP       = /^\d{2}$/
    FOUR_DIGIT_REGEXP      = /^\d{4}$/

    TIME_REGEXP            = /(\d{1,2})(:)(\d{2})(\s*)(:)?(\d{2})?(\s*)?([ap]m)?/i

    MERIDIAN_LOWER_REGEXP  = /^(a|p)m$/
    MERIDIAN_UPPER_REGEXP  = /^(A|P)M$/

    ORDINAL_DAY_REGEXP     = /^(\d{1,2})(st|nd|rd|th)$/

    # Disambiguate based on value
    OBVIOUS_YEARS          = 60..99
    OBVIOUS_MONTHS         = 12
    OBVIOUS_DAYS           = 13..31
    OBVIOUS_24_HOUR        = 13..23

    OBVIOUS_DATE_MAP = {
      OBVIOUS_YEARS  => NumericEmitter.new(:year, 100, "2.2"), # '%y'
      OBVIOUS_MONTHS => NumericEmitter.new(:month, nil, "2.2"), # '%m'
      OBVIOUS_DAYS   => NumericEmitter.new(:day, nil, "2.2") # '%d'
    }

    TWO_DIGIT_DATE_SUCCESSION = {
      :month => NumericEmitter.new(:day, nil, "2.2"), # '%d'
      :day   => NumericEmitter.new(:year, 100, "2.2"), # '%y'
      :year  => NumericEmitter.new(:month, nil, "2.2") # '%m'
    }

    TWO_DIGIT_TIME_SUCCESSION = {
      :hour   => NumericEmitter.new(:min, nil, "2.2"), # '%M'
      :min => NumericEmitter.new(:sec, nil, "2.2")  # '%S'
    }

  "(%%A)      full weekday name, var length (Sunday..Saturday)  %A",
  "(%%B)       full month name, var length (January..December)  %B",
  "(%%C)                                               Century  %C",
  "(%%D)                                       date (%%m/%%d/%%y)  %D",
  "(%%E)                           Locale extensions (ignored)  %E",
  "(%%H)                          hour (24-hour clock, 00..23)  %H",
  "(%%I)                          hour (12-hour clock, 01..12)  %I",
  "(%%M)                                       minute (00..59)  %M",
  "(%%O)                           Locale extensions (ignored)  %O",
  "(%%R)                                 time, 24-hour (%%H:%%M)  %R",
  "(%%S)                                       second (00..60)  %S",
  "(%%T)                              time, 24-hour (%%H:%%M:%%S)  %T",
  "(%%U)    week of year, Sunday as first day of week (00..53)  %U",
  "(%%V)                    week of year according to ISO 8601  %V",
  "(%%W)    week of year, Monday as first day of week (00..53)  %W",
  "(%%X)     appropriate locale time representation (%H:%M:%S)  %X",
  "(%%Y)                           year with century (1970...)  %Y",
  "(%%Z) timezone (EDT), or blank if timezone not determinable  %Z",
  "(%%a)          locale's abbreviated weekday name (Sun..Sat)  %a",
  "(%%b)            locale's abbreviated month name (Jan..Dec)  %b",
  "(%%c)           full date (Sat Nov  4 12:02:33 1989)%n%t%t%t  %c",
  "(%%d)                             day of the month (01..31)  %d",
  "(%%e)               day of the month, blank-padded ( 1..31)  %e",
  "(%%h)                                should be same as (%%b)  %h",
  "(%%j)                            day of the year (001..366)  %j",
  "(%%k)               hour, 24-hour clock, blank pad ( 0..23)  %k",
  "(%%l)               hour, 12-hour clock, blank pad ( 0..12)  %l",
  "(%%m)                                        month (01..12)  %m",
  "(%%p)              locale's AM or PM based on 12-hour clock  %p",
  "(%%r)                   time, 12-hour (same as %%I:%%M:%%S %%p)  %r",
  "(%%u) ISO 8601: Weekday as decimal number [1 (Monday) - 7]   %u",
  "(%%v)                                VMS date (dd-bbb-YYYY)  %v",
  "(%%w)                       day of week (0..6, Sunday == 0)  %w",
  "(%%x)                appropriate locale date representation  %x",
  "(%%y)                      last two digits of year (00..99)  %y",
  "(%%z)      timezone offset east of GMT as HHMM (e.g. -0500)  %z",
    def legacy(m)
      case m[1,3]
      when 'A'; LookupEmitter.new(:wday, Date::DAYNAMES)
      when 'a'; LookupEmitter.new(:wday, Date::ABBR_DAYNAMES)
      when 'B'; LookupEmitter.new(:mon, Date::MONTHNAMES)
      when 'b'; LookupEmitter.new(:mon, Date::ABBR_MONTHNAMES)
      when 'C', 'EC'; LookupEmitter.new(:year, 100) #TODO: this should be the century
      when 'c', 'Ec'; CompositeEmitter.new(['%a',' ','%b',' ','%e',' ','%H',':','%M',':','%S',' ','%Y'].map {|p| legacy(p)})
      when 'D'; CompositeEmitter.new(['%m','/','%d','/','%y'].map {|p| legacy(p)})
      when 'd', 'Od'; NumericEmitter.new(:mday, nil, "2.2") 
      when 'e', 'Oe'; NumericEmitter.new(:mday, nil, "2") 
      when 'F' ; CompositeEmitter.new(['%Y','-','%m','-','%d'].map {|p| legacy(p)})
  if m == '%F'
    format('%.4d-%02d-%02d', year, mon, mday) # 4p
  else
    emit_a(strftime('%Y-%m-%d'), 0, f)
  end
      when 'G'; emit_sn(cwyear, 4, f)
      when 'g'; emit_n(cwyear % 100, 2, f)
      when 'H', 'OH'; emit_n(hour, 2, f)
      when 'h'; emit_ad(strftime('%b'), 0, f)
      when 'I', 'OI'; emit_n((hour % 12).nonzero? || 12, 2, f)
      when 'j'; emit_n(yday, 3, f)
      when 'k'; emit_a(hour, 2, f)
      when 'L'
  f[:p] = nil
  w = f[:w] || 3
  u = 10**w
  emit_n((sec_fraction * u).floor, w, f)
      when 'l'; emit_a((hour % 12).nonzero? || 12, 2, f)
      when 'M', 'OM'; emit_n(min, 2, f)
      when 'm', 'Om'; emit_n(mon, 2, f)
      when 'N'
  f[:p] = nil
  w = f[:w] || 9
  u = 10**w
  emit_n((sec_fraction * u).floor, w, f)
      when 'n'; emit_a("\n", 0, f)
      when 'P'; emit_ad(strftime('%p').downcase, 0, f)
      when 'p'; emit_au(if hour < 12 then 'AM' else 'PM' end, 0, f)
      when 'Q'
  s = ((ajd - UNIX_EPOCH_IN_AJD) / MILLISECONDS_IN_DAY).round
  emit_sn(s, 1, f)
      when 'R'; emit_a(strftime('%H:%M'), 0, f)
      when 'r'; emit_a(strftime('%I:%M:%S %p'), 0, f)
      when 'S', 'OS'; emit_n(sec, 2, f)
      when 's'
  s = ((ajd - UNIX_EPOCH_IN_AJD) / SECONDS_IN_DAY).round
  emit_sn(s, 1, f)
      when 'T'
  if m == '%T'
    format('%02d:%02d:%02d', hour, min, sec) # 4p
  else
    emit_a(strftime('%H:%M:%S'), 0, f)
  end
      when 't'; emit_a("\t", 0, f)
      when 'U', 'W', 'OU', 'OW'
  emit_n(if c[-1,1] == 'U' then wnum0 else wnum1 end, 2, f)
      when 'u', 'Ou'; emit_n(cwday, 1, f)
      when 'V', 'OV'; emit_n(cweek, 2, f)
      when 'v'; emit_a(strftime('%e-%b-%Y'), 0, f)
      when 'w', 'Ow'; emit_n(wday, 1, f)
      when 'X', 'EX'; emit_a(strftime('%H:%M:%S'), 0, f)
      when 'x', 'Ex'; emit_a(strftime('%m/%d/%y'), 0, f)
      when 'Y', 'EY'; emit_sn(year, 4, f)
      when 'y', 'Ey', 'Oy'; emit_n(year % 100, 2, f)
      when 'Z'; emit_au(strftime('%:z'), 0, f)

    }
    # return an array of procs that can be used to generate this string

    def translate(example)
      # extract any substrings that look like times, like "23:59" or "8:37 am"
      before, time_example, after = example.partition(TIME_REGEXP)

      # transform any date tokens to strftime directives
      words = CompositeEmitter.new
      words << strftime_directives(before.split(/\b/)) do |token, previous_part|
        strftime_date_directive(token, previous_part)
      end

      # transform the example time string to strftime directives
      unless time_example.empty?
        time_parts = time_example.scan(TIME_REGEXP).first
        #NOTE: was +=
        words << strftime_directives(time_parts) do |token, previous_part|
          strftime_time_directive(token, previous_part)
        end
      end

      # recursively process any remaining text
      words << translate(after) unless after.empty?
      puts "==> #{words.inspect}"
      words
    end

    # Transforms tokens that look like date/time parts to strftime directives.
    def strftime_directives(tokens)
      previous_part = nil
      tokens.map do |token|
        directive = yield(token, previous_part)
        previous_part = directive.field unless directive.nil?
        directive || (token && token[0] == '%') ? LEGACY[token[1]] : StringEmitter.new(token||'')
      end
    end

    def strftime_time_directive(token, previous_part)
      case token
      when MERIDIAN_LOWER_REGEXP
        AmPmEmitter.new() # '%P'
      when MERIDIAN_UPPER_REGEXP
        AmPmEmitter.new(:upcase) # '%p'
      when TWO_DIGIT_REGEXP
        TWO_DIGIT_TIME_SUCCESSION[previous_part] ||
          case token.to_i
          when OBVIOUS_24_HOUR
            NumericEmitter.new(:hour, nil, '2') # '%H' # 24-hour clock
          else
            NumericEmitter.new(:hour, 12, '2.2', true) #%I' # 12-hour clock with leading zero
          end

      when ONE_DIGIT_REGEXP
        NumericEmitter.new(:hour, 12, '2', true) # '%l' # hour without leading zero (but leading space)
      end
    end

    def strftime_date_directive(token, previous_part)
      case token
      when MONTHNAMES_REGEXP
        LookupEmitter.new(:month, Date::MONTHNAMES) #'%B'

      when ABBR_MONTHNAMES_REGEXP
        LookupEmitter.new(:month, Date::ABBR_MONTHNAMES) #'%b'

      when DAYNAMES_REGEXP
        LookupEmitter.new(:wday, Date::DAYNAMES) #'%A'

      when ABBR_DAYNAMES_REGEXP
        LookupEmitter.new(:wday, Date::ABBR_DAYNAMES) #'%a'

      when TIMEZONE_REGEXP
        LookupEmitter.new(:zone) #'%Z'

      when FOUR_DIGIT_REGEXP
        NumericEmitter.new(:year) #'%Y'

      when ORDINAL_DAY_REGEXP
        OrdinalEmitter.new(:day)

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
          NumericEmitter.new(:month, 100, "2.2") # '%m'

      when ONE_DIGIT_REGEXP
        NumericEmitter.new(:day,nil,"2") #'%e' # day without leading zero
      end
    end

  end
end
