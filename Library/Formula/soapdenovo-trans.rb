require 'formula'

class SoapdenovoTrans < Formula
  homepage ''
  url 'http://sourceforge.net/projects/soapdenovotrans/files/SOAPdenovo-Trans/src/v1.03/SOAPdenovo-Trans-src-v1.03.tar.gz'
  sha1 'fafff6006bf1be7c92fa6488416ec86e96682c8e'

  def install
    ENV.j1
    system "sh", "make.sh"
    bin.install "SOAPdenovo-Trans-127mer"
    bin.install "SOAPdenovo-Trans-31mer"
  end

  test do
    system "false"
  end
end
