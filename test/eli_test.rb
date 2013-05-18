require 'test/unit'
require './eli'

class TestSampleELI < Test::Unit::TestCase
  def test_local_eli
    assert_equal("http://eli.budabe.eu/eli/dir/2010/24/oj",  Eli.new().eli )
  end

  def test_remote_eli
    assert_equal("http://eli.budabe.eu/eli/dir/2010/24/oj",  Eli.new("http://publications.europa.eu/resource/oj/JOL_2010_084_R_0001_01").eli )
    assert_equal("http://eli.budabe.eu/eli/dir/2010/24/oj",  Eli.new("http://publications.europa.eu/resource/celex/32010L0024").eli )
  end

  def test_search
    assert_equal("http://eli.budabe.eu/eli/dec/2012/77/oj", Eli.new("http://publications.europa.eu/resource/oj/JOL_2012_038_R_0047_01").eli)
    assert_equal("http://eli.budabe.eu/eli/dec/2011/10/oj", Eli.new("http://publications.europa.eu/resource/celex/32010D0024").eli)
  end

  def test_corrigenda
    assert_equal("http://eli.budabe.eu/eli/reg/2010/178/corr-fra/2012-01-11/oj", Eli.new("http://publications.europa.eu/resource/celex/32010R0178R%2801%29").eli)  #Celex is 32010R0178R(01)
    assert_equal("http://eli.budabe.eu/eli/reg/2010/178/corr-fra/2012-01-11/oj", Eli.new("http://publications.europa.eu/resource/oj/JOL_2012_007_R_0011_01_REG_2010_178_11").eli)
    assert_equal("http://eli.budabe.eu/eli/dir/2012/12/corr-bul-ces-dan-deu-ell-eng-est-fin-fra-hun-ita-lav-lit-mlt-nld-pol-por-ron-slk-slv-spa-swe/2013-01-31/oj", Eli.new("http://publications.europa.eu/resource/celex/32012L0012R%2801%29").eli)
  end
end

