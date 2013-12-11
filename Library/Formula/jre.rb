require 'formula'

class Jre < Formula
  homepage 'http://www.oracle.com/technetwork/java/javase/downloads/jre7-downloads-1880261.html'
  version '7u45'
  url 'http://download.oracle.com/otn-pub/java/jdk/7u45-b18/jre-7u45-linux-x64.tar.gz'
  sha1 '43eabe42bb8d6e8dfe33f3a815f265ac5d5bb586'

  def install
    # ENV.j1  # if your formula's build system can't parallelize

    # Remove unrecognized options if warned by configure
    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"
    # system "cmake", ".", *std_cmake_args
    system "make", "install" # if this fails, try separate make/make install steps
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test jre-7u45-linux-x`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "--version"`.
    system "false"
  end
end
