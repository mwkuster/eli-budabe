require 'test/unit'
require './eli'

class TestSampleELI < Test::Unit::TestCase
  def test_local_eli
    assert_equal("http://eli.budabe.eu/eli/dir/2010/24/consil/oj",  Eli.build_eli() )
  end

  def test_remote_eli
    assert_equal("http://eli.budabe.eu/eli/dir/2010/24/consil/oj",  Eli.build_eli("http://publications.europa.eu/resource/oj/JOL_2010_084_R_0001_01") )
    assert_equal("http://eli.budabe.eu/eli/dir/2010/24/consil/oj",  Eli.build_eli("http://publications.europa.eu/resource/celex/32010L0024") )
  end

  def test_search
    assert_equal("http://eli.budabe.eu/eli/dec/2012/77/com/oj", Eli.build_eli("http://publications.europa.eu/resource/oj/JOL_2012_038_R_0047_01"))
    assert_equal("http://eli.budabe.eu/eli/dec/2011/10/ecb/oj", Eli.build_eli("http://publications.europa.eu/resource/celex/32010D0024"))
  end
end
