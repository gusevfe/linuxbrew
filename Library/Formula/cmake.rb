require 'formula'

class Cmake < Formula
  homepage 'http://www.cmake.org/'
  url 'http://www.cmake.org/files/v2.8/cmake-2.8.12.1.tar.gz'
  sha1 '5661a607acbce7c16bb5f15ff2895fa5ca53a4da'

  head 'http://cmake.org/cmake.git'

  bottle do
    cellar :any
    sha1 '47c0961bc3cca0e89d4fee9f96638b9848e2d40a' => :mavericks
    sha1 'b9908be7e2eb79cc2e0f9ab1d9e46faea2748b10' => :mountain_lion
    sha1 'bc012f5e4a1a4eb09967d0e8f26688781412dc01' => :lion
  end

  depends_on "expat"

  def install
    args = %W[
      --prefix=#{prefix}
      --system-libs
      --no-system-libarchive
      --datadir=/share/cmake
      --docdir=/share/doc/cmake
      --mandir=/share/man
    ]

    system "./bootstrap", *args
    system "make"
    system "make install"
  end

  test do
    (testpath/'CMakeLists.txt').write('find_package(Ruby)')
    system "#{bin}/cmake", '.'
  end
end
