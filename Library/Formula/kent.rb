require 'formula'

class Kent < Formula
  homepage 'http://genome-source.cse.ucsc.edu/gitweb/?p=kent.git;a=blob;f=src/userApps/README'
  version '16-07-2013'
  url 'http://hgdownload.cse.ucsc.edu/admin/exe/userApps.src.tgz'
  sha1 '0e8bd5c604b239f9ca457d15efba8fc17559a2f1'

  def install
    ENV['MYSQLLIBS'] = `mysql_config --libs`.strip + " -lz"
    ENV['MYSQLINC'] = `mysql_config --include`.strip.sub(/^-I/, "")
    system "make"
    (prefix/"bin").mkpath
    system "cp", *(Dir["bin/*"]), prefix/"bin"
  end

  test do
    system "false"
  end
end
