require 'formula'

class Macs < Formula
  homepage 'http://liulab.dfci.harvard.edu/MACS'
  version '1.4.2-1'
  url 'https://github.com/downloads/taoliu/MACS/MACS-1.4.2-1.tar.gz'
  sha1 '956fd4dd4ab2dd295b1dbf282b1a8be497273c90'

  depends_on :python => "2.7"
  depends_on :python3 => :optional

  def install
    system python, "setup.py", "--prefix=#{prefix}"
#    system "./configure", "--disable-debug",
#                          "--disable-dependency-tracking",
#                          "--disable-silent-rules",
#                          "--prefix=#{prefix}"
    # system "cmake", ".", *std_cmake_args
#    system "make", "install" # if this fails, try separate make/make install steps
  end

  test do
    system "false"
  end
end
