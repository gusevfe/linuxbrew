require 'formula'

class TrimGalore < Formula
  homepage 'http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/'
  url 'http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/trim_galore_v0.3.3.zip'
  sha1 'e779c3a1f6ba8fd3201efd5752b4a5f3e85f6ced'

  def install
    bin.install 'trim_galore'
  end

  test do
    system "false"
  end
end
