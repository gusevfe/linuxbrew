require 'formula'

class Python3 < Formula
  homepage 'http://www.python.org/'
  url 'http://python.org/ftp/python/3.3.3/Python-3.3.3.tar.bz2'
  sha1 '6ff7d34427cbf7bf875e6a456850231e488118ca'
  VER='3.3'  # The <major>.<minor> is used so often.

  head 'http://hg.python.org/cpython', :using => :hg, :branch => VER

  option :universal
  option 'quicktest', 'Run `make quicktest` after the build'
  option 'with-brewed-openssl', "Use Homebrew's openSSL instead of the one from OS X"
  option 'with-brewed-tk', "Use Homebrew's Tk (has optional Cocoa and threads support)"

  depends_on 'pkg-config' => :build
  depends_on 'readline' => :recommended
  depends_on 'sqlite' => :recommended
  depends_on 'gdbm' => :recommended
  depends_on 'openssl' if build.with? 'brewed-openssl'
  depends_on 'xz' => :recommended  # for the lzma module added in 3.3
  depends_on 'homebrew/dupes/tcl-tk' if build.with? 'brewed-tk'
  depends_on :x11 if build.with? 'brewed-tk' and Tab.for_name('tcl-tk').used_options.include?('with-x11')

  skip_clean "bin/pip3", "bin/pip-#{VER}"
  skip_clean "bin/easy_install3", "bin/easy_install-#{VER}"

  resource 'setuptools' do
    url 'https://pypi.python.org/packages/source/s/setuptools/setuptools-1.3.2.tar.gz'
    sha1 '77180132225c5b4696e6d061655e291f3d1b20f5'
  end

  resource 'pip' do
    url 'https://pypi.python.org/packages/source/p/pip/pip-1.4.1.tar.gz'
    sha1 '9766254c7909af6d04739b4a7732cc29e9a48cb0'
  end

  def patches
    DATA if build.with? 'brewed-tk'
  end

  fails_with :llvm do
    build '2336'
    cause <<-EOS.undent
      Could not find platform dependent libraries <exec_prefix>
      Consider setting $PYTHONHOME to <prefix>[:<exec_prefix>]
      python.exe(14122) malloc: *** mmap(size=7310873954244194304) failed (error code=12)
      *** error: can't allocate region
      *** set a breakpoint in malloc_error_break to debug
      Could not import runpy module
      make: *** [pybuilddir.txt] Segmentation fault: 11
    EOS
  end
  #
  # The HOMEBREW_PREFIX location of site-packages.
  def site_packages
    HOMEBREW_PREFIX/"lib/python2.7/site-packages"
  end

  def site_packages_cellar
    prefix/"lib/python3.3/site-packages"
  end

  def install
    # Unset these so that installing pip and setuptools puts them where we want
    # and not into some other Python the user has installed.
    ENV['PYTHONHOME'] = nil
    ENV['PYTHONPATH'] = nil

    args = %W[
      --prefix=#{prefix}
      --enable-ipv6
      --datarootdir=#{share}
      --datadir=#{share}]

    args << '--without-gcc' if ENV.compiler == :clang

    if superenv?
      distutils_fix_superenv(args)
    else
      distutils_fix_stdenv
    end

    if build.universal?
      ENV.universal_binary
      args << "--enable-universalsdk" << "--with-universal-archs=intel"
    end

    # Allow sqlite3 module to load extensions: http://docs.python.org/library/sqlite3.html#f1
    inreplace("setup.py", 'sqlite_defines.append(("SQLITE_OMIT_LOAD_EXTENSION", "1"))', 'pass') if build.with? 'sqlite'

    # Allow python modules to use ctypes.find_library to find homebrew's stuff
    # even if homebrew is not a /usr/local/lib. Try this with:
    # `brew install enchant && pip install pyenchant`
    inreplace "./Lib/ctypes/macholib/dyld.py" do |f|
      f.gsub! 'DEFAULT_LIBRARY_FALLBACK = [', "DEFAULT_LIBRARY_FALLBACK = [ '#{HOMEBREW_PREFIX}/lib',"
    end

    if build.with? 'brewed-tk'
      ENV.append 'CPPFLAGS', "-I#{Formula.factory('tcl-tk').opt_prefix}/include"
      ENV.append 'LDFLAGS', "-L#{Formula.factory('tcl-tk').opt_prefix}/lib"
    end

    system "./configure", *args

    system "make"

    ENV.deparallelize # Installs must be serialized
    system "make", "install"
    system "make", "quicktest" if build.include? "quicktest"
     
    # Remove the site-packages that Python created in its Cellar.
    site_packages_cellar.rmtree
    # Create a site-packages in HOMEBREW_PREFIX/lib/python2.7/site-packages
    site_packages.mkpath
    # Symlink the prefix site-packages into the cellar.
    ln_s site_packages, site_packages_cellar

    # We ship setuptools and pip and reuse the PythonDependency
    # Requirement here to write the sitecustomize.py
    py = PythonDependency.new(VER)
    py.binary = bin/"python#{VER}"
    py.modify_build_environment

    # Remove old setuptools installations that may still fly around and be
    # listed in the easy_install.pth. This can break setuptools build with
    # zipimport.ZipImportError: bad local file header
    # setuptools-0.9.8-py3.3.egg
    rm_rf Dir["#{py.global_site_packages}/setuptools*"]
    rm_rf Dir["#{py.global_site_packages}/distribute*"]

    setup_args = [ "-s", "setup.py", "install", "--force", "--verbose",
                   "--install-scripts=#{bin}"]

    resource('setuptools').stage { system py.binary, *setup_args }

    resource('pip').stage { system py.binary, *setup_args }
        mv bin/'pip', bin/'pip3'

    # And now we write the distutils.cfg
    # /data/results/gusev/software/linuxbrew/
    # 
    # Cellar/python3/3.3.3/lib/python3.3/distutils
    cfg = prefix/"lib/python#{VER}/distutils/distutils.cfg"
    cfg.delete if cfg.exist?
    cfg.write <<-EOF.undent
      [global]
      verbose=1
      [install]
      prefix=#{HOMEBREW_PREFIX}
    EOF
  end

  def distutils_fix_superenv(args)
    # To allow certain Python bindings to find brewed software (and sqlite):
    cflags = "CFLAGS=-I#{HOMEBREW_PREFIX}/include -I#{Formula.factory('sqlite').opt_prefix}/include"
    ldflags = "LDFLAGS=-L#{HOMEBREW_PREFIX}/lib -L#{Formula.factory('sqlite').opt_prefix}/lib"
    unless MacOS::CLT.installed?
      # Help Python's build system (setuptools/pip) to build things on Xcode-only systems
      # The setup.py looks at "-isysroot" to get the sysroot (and not at --sysroot)
      cflags += " -isysroot #{MacOS.sdk_path}"
      ldflags += " -isysroot #{MacOS.sdk_path}"
      # Same zlib.h-not-found-bug as in env :std (see below)
      args << "CPPFLAGS=-I#{MacOS.sdk_path}/usr/include"
    end
    args << cflags
    args << ldflags
    # Avoid linking to libgcc http://code.activestate.com/lists/python-dev/112195/
    args << "MACOSX_DEPLOYMENT_TARGET=#{MacOS.version}"
    # We want our readline! This is just to outsmart the detection code,
    # superenv makes cc always find includes/libs!
    inreplace "setup.py",
              "do_readline = self.compiler.find_library_file(lib_dirs, 'readline')",
              "do_readline = '#{HOMEBREW_PREFIX}/opt/readline/lib/libhistory.dylib'"
  end

  def distutils_fix_stdenv()
    # Python scans all "-I" dirs but not "-isysroot", so we add
    # the needed includes with "-I" here to avoid this err:
    #     building dbm using ndbm
    #     error: /usr/include/zlib.h: No such file or directory
    ENV.append 'CPPFLAGS', "-I#{MacOS.sdk_path}/usr/include" unless MacOS::CLT.installed?

    # Don't use optimizations other than "-Os" here, because Python's distutils
    # remembers (hint: `python3-config --cflags`) and reuses them for C
    # extensions which can break software (such as scipy 0.11 fails when
    # "-msse4" is present.)
    ENV.minimal_optimization

    # We need to enable warnings because the configure.in uses -Werror to detect
    # "whether gcc supports ParseTuple" (https://github.com/mxcl/homebrew/issues/12194)
    ENV.enable_warnings
    if ENV.compiler == :clang
      # http://docs.python.org/devguide/setup.html#id8 suggests to disable some Warnings.
      ENV.append_to_cflags '-Wno-unused-value'
      ENV.append_to_cflags '-Wno-empty-body'
      ENV.append_to_cflags '-Qunused-arguments'
    end
  end

  def caveats
    text = <<-EOS.undent
      Setuptools and Pip have been installed. To update them
        pip3 install --upgrade setuptools
        pip3 install --upgrade pip

      You can install Python packages with
        `pip3 install <your_favorite_package>`

      See: https://github.com/mxcl/homebrew/wiki/Homebrew-and-Python
    EOS

    # Tk warning only for 10.6
    tk_caveats = <<-EOS.undent

      Apple's Tcl/Tk is not recommended for use with Python on Mac OS X 10.6.
      For more information see: http://www.python.org/download/mac/tcltk/
    EOS

    text += tk_caveats unless MacOS.version >= :lion
    return text
  end

  test do
    # Check if sqlite is ok, because we build with --enable-loadable-sqlite-extensions
    # and it can occur that building sqlite silently fails if OSX's sqlite is used.
    system "#{bin}/python#{VER}", "-c", "import sqlite3"
    # Check if some other modules import. Then the linked libs are working.
    system "#{bin}/python#{VER}", "-c", "import tkinter; root = tkinter.Tk()"
  end
end

__END__
# Homebrew's tcl-tk is build in a standard unix fashion (due to link errors)
# and we have to stop python from searching for frameworks and link against
# X11.

diff --git a/setup.py b/setup.py
index d4183d4..9f69520 100644
--- a/setup.py
+++ b/setup.py
@@ -1623,9 +1623,6 @@ class PyBuildExt(build_ext):
         # Rather than complicate the code below, detecting and building
         # AquaTk is a separate method. Only one Tkinter will be built on
         # Darwin - either AquaTk, if it is found, or X11 based Tk.
-        if (host_platform == 'darwin' and
-            self.detect_tkinter_darwin(inc_dirs, lib_dirs)):
-            return

         # Assume we haven't found any of the libraries or include files
         # The versions with dots are used on Unix, and the versions without
@@ -1671,21 +1668,6 @@ class PyBuildExt(build_ext):
             if dir not in include_dirs:
                 include_dirs.append(dir)

-        # Check for various platform-specific directories
-        if host_platform == 'sunos5':
-            include_dirs.append('/usr/openwin/include')
-            added_lib_dirs.append('/usr/openwin/lib')
-        elif os.path.exists('/usr/X11R6/include'):
-            include_dirs.append('/usr/X11R6/include')
-            added_lib_dirs.append('/usr/X11R6/lib64')
-            added_lib_dirs.append('/usr/X11R6/lib')
-        elif os.path.exists('/usr/X11R5/include'):
-            include_dirs.append('/usr/X11R5/include')
-            added_lib_dirs.append('/usr/X11R5/lib')
-        else:
-            # Assume default location for X11
-            include_dirs.append('/usr/X11/include')
-            added_lib_dirs.append('/usr/X11/lib')

         # If Cygwin, then verify that X is installed before proceeding
         if host_platform == 'cygwin':
@@ -1710,10 +1692,6 @@ class PyBuildExt(build_ext):
         if host_platform in ['aix3', 'aix4']:
             libs.append('ld')

-        # Finally, link with the X11 libraries (not appropriate on cygwin)
-        if host_platform != "cygwin":
-            libs.append('X11')
-
         ext = Extension('_tkinter', ['_tkinter.c', 'tkappinit.c'],
                         define_macros=[('WITH_APPINIT', 1)] + defs,
                         include_dirs = include_dirs,
