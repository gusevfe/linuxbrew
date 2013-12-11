require 'formula'

class Rsem < Formula
  homepage ''
  url 'http://deweylab.biostat.wisc.edu/rsem/src/rsem-1.2.8.tar.gz'
  sha1 'c7e290c9dde15745c3bb57a943d7abb770443459'

  def install
    system "make"
    (share/'rsem').install Dir["*"]
  end

  test do
    system "false"
  end
end
