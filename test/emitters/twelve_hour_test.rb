require 'test_helper'

class TwelveHourTest < Minitest::Test
  def test_format_no_leading_zero
    e = emitter(:hour, leading_zero: false)
    assert_equal '12', e.format(tm(0)).to_s
    assert_equal '1', e.format(tm(1)).to_s
    assert_equal '9', e.format(tm(9)).to_s
    assert_equal '11', e.format(tm(11)).to_s
    assert_equal '12', e.format(tm(12)).to_s
    assert_equal '1', e.format(tm(13)).to_s
    assert_equal '11', e.format(tm(23)).to_s
  end

  def test_format_leading_zero
    e = emitter(:hour, leading_zero: true)
    assert_equal '12', e.format(tm(0)).to_s
    assert_equal '01', e.format(tm(1)).to_s
    assert_equal '09', e.format(tm(9)).to_s
    assert_equal '11', e.format(tm(11)).to_s
    assert_equal '12', e.format(tm(12)).to_s
    assert_equal '01', e.format(tm(13)).to_s
    assert_equal '11', e.format(tm(23)).to_s
  end

  def test_format_default
    e = emitter(:hour)
    assert_equal '1', e.format(tm(1)).to_s
  end

  def test_field
    assert_equal :hour, emitter(:hour).field
  end

  private

  def emitter(*args)
    Stamp::Emitters::TwelveHour.new(*args)
  end
end
