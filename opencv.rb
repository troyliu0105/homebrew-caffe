class Opencv < Formula
  desc "Open source computer vision library"
  homepage "https://opencv.org/"
  url "https://github.com/opencv/opencv/archive/4.1.0.tar.gz"
  sha256 "8f6e4ab393d81d72caae6e78bd0fd6956117ec9f006fba55fcdb88caf62989b7"
  revision 2

  bottle do
    rebuild 1
    root_url "https://homebrew.bintray.com/bottles"
    sha256 "5f6821416988e413bcc9bd4ef5169a66e8458c4b55495286850bea7c6b6d34ee" => :catalina
    sha256 "a5ff3b325dda09989870c0ff910b4ca4e639962b605ee95e9d2a01627d93da07" => :mojave
    sha256 "d028ff3f01a4548e402659bf2291030d98a8ef6ec3ad54cbf18e2b7782899dec" => :high_sierra
  end

  depends_on "pkg-config" => :build
  depends_on "cmake" => :build
  depends_on "gcc" => :build
  depends_on "ffmpeg"
  depends_on "gflags"
  depends_on "glog"
  depends_on "harfbuzz"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "libtiff"
  depends_on "openexr"
  depends_on "numpy"
  depends_on "python"
  depends_on "eigen"

  resource "contrib" do
    url "https://github.com/opencv/opencv_contrib/archive/4.1.0.tar.gz"
    sha256 "e7d775cc0b87b04308823ca518b11b34cc12907a59af4ccdaf64419c1ba5e682"
  end

  patch do
    url "https://github.com/opencv/opencv/pull/14308.patch?full_index=1"
    sha256 "c48a6a769f364e6f61bc99cf47a6e664c85246c9fcd4a201afc408158fc4f1ef"
  end

  def install
    ENV.cxx11

    resource("contrib").stage buildpath/"opencv_contrib"

    # Reset PYTHONPATH, workaround for https://github.com/Homebrew/homebrew-science/pull/4885
    ENV.delete("PYTHONPATH")
    gcc = Formula["gcc"]
    ENV["CC"]="#{gcc.opt_prefix}/bin/gcc-#{gcc.version_suffix}"
    ENV["CXX"]="#{gcc.opt_prefix}/bin/g++-#{gcc.version_suffix}"

    py3_config = `python3-config --configdir`.chomp
    py3_include = `python3 -c "import distutils.sysconfig as s; print(s.get_python_inc())"`.chomp
    py3_version = Language::Python.major_minor_version "python3"

    args = std_cmake_args + %W[
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
      -DBUILD_JASPER=OFF
      -DBUILD_JPEG=OFF
      -DBUILD_OPENEXR=OFF
      -DBUILD_PERF_TESTS=OFF
      -DBUILD_PNG=OFF
      -DBUILD_TESTS=OFF
      -DBUILD_TIFF=OFF
      -DBUILD_ZLIB=OFF
      -DBUILD_opencv_hdf=OFF
      -DBUILD_opencv_java=OFF
      -DBUILD_opencv_text=ON
      -DOPENCV_ENABLE_NONFREE=ON
      -DOPENCV_EXTRA_MODULES_PATH=#{buildpath}/opencv_contrib/modules
      -DOPENCV_GENERATE_PKGCONFIG=ON
      -DWITH_1394=OFF
      -DWITH_CUDA=OFF
      -DWITH_OPENCL=ON
      -DWITH_EIGEN=ON
      -DWITH_FFMPEG=ON
      -DWITH_GPHOTO2=OFF
      -DWITH_GSTREAMER=OFF
      -DWITH_JASPER=OFF
      -DWITH_OPENEXR=ON
      -DWITH_OPENGL=OFF
      -DWITH_QT=OFF
      -DWITH_TBB=OFF
      -DWITH_OPENMP=ON
      -DWITH_VTK=OFF
      -DWITH_JPEG=ON
      -DBUILD_opencv_python2=OFF
      -DBUILD_opencv_python3=ON
      -DPYTHON3_EXECUTABLE=#{which "python3"}
      -DPYTHON3_LIBRARY=#{py3_config}/libpython#{py3_version}.dylib
      -DPYTHON3_INCLUDE_DIR=#{py3_include}
    ]

    # The compiler on older Mac OS cannot build some OpenCV files using AVX2
    # extensions, failing with errors such as
    # "error: use of undeclared identifier '_mm256_cvtps_ph'"
    # Work around this by not trying to build AVX2 code.
    if MacOS.version <= :yosemite
      args << "-DCPU_DISPATCH=SSE4_1,SSE4_2,AVX"
    end

    args << "-DENABLE_AVX=OFF" << "-DENABLE_AVX2=OFF"
    unless MacOS.version.requires_sse42?
      args << "-DENABLE_SSE41=OFF" << "-DENABLE_SSE42=OFF"
    end

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
      system "make", "clean"
      system "cmake", "..", "-DBUILD_SHARED_LIBS=OFF", *args
      system "make"
      lib.install Dir["lib/*.a"]
      lib.install Dir["3rdparty/**/*.a"]
    end
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <opencv2/opencv.hpp>
      #include <iostream>
      int main() {
        std::cout << CV_VERSION << std::endl;
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++11", "test.cpp", "-I#{include}/opencv4",
                    "-o", "test"
    assert_equal `./test`.strip, version.to_s

    ["python3"].each do |python|
      output = shell_output("#{python} -c 'import cv2; print(cv2.__version__)'")
      assert_equal version.to_s, output.chomp
    end
  end
end
