class Icu4c < Formula
  desc "C/C++ and Java libraries for Unicode and globalization"
  homepage "http://site.icu-project.org/home"
  url "https://github.com/unicode-org/icu/releases/download/release-64-2/icu4c-64_2-src.tgz"
  version "64.2"
  sha256 "627d5d8478e6d96fc8c90fed4851239079a561a6a8b9e48b0892f24e82d31d6c"
  
  depends_on "troyliu0105/caffe/gcc" => :build

  def install
    gcc = Formula["troyliu0105/caffe/gcc"]
    ENV["CC"]="#{gcc.opt_prefix}/bin/gcc-#{gcc.version_suffix}"
    ENV["CXX"]="#{gcc.opt_prefix}/bin/g++-#{gcc.version_suffix}"
    args = %W[
      --prefix=#{prefix}
      --disable-samples
      --disable-tests
      --enable-static
      --with-library-bits=64
    ]

    cd "source" do
      system "./configure", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    system "#{bin}/gendict", "--uchars", "/usr/share/dict/words", "dict"
  end
end
