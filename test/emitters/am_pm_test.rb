require 'test_helper'

class AmPmTest < Minitest::Test
  def test_format_lowercase
    e = emitter(upcase: false)
    assert_equal 'am', e.format(tm(0))
    assert_equal 'am', e.format(tm(1))
    assert_equal 'am', e.format(tm(11))
    assert_equal 'pm', e.format(tm(12))
    assert_equal 'pm', e.format(tm(13))
    assert_equal 'pm', e.format(tm(23))
  end

  def test_format_uppercase
    e = emitter(upcase: true)
    assert_equal 'AM', e.format(tm(1))
    assert_equal 'AM', e.format(tm(11))
    assert_equal 'PM', e.format(tm(12))
    assert_equal 'PM', e.format(tm(13))
    assert_equal 'PM', e.format(tm(23))
  end

  def test_format_default
    e = emitter
    assert_equal 'am', e.format(tm(1))
  end

  def test_field
    assert_nil emitter.field
  end

  private

  def emitter(*args)
    Stamp::Emitters::AmPm.new(*args)
  end
end
