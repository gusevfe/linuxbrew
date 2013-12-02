require 'formula'

class Macs < Formula
  homepage 'http://liulab.dfci.harvard.edu/MACS'
  version '1.4.2-1'
  url 'https://github.com/downloads/taoliu/MACS/MACS-1.4.2-1.tar.gz'
  sha1 '956fd4dd4ab2dd295b1dbf282b1a8be497273c90'

  depends_on :python => "2.7"

  def install
    system python, "setup.py", "install"
  end

  test do
    system "false"
  end
end
