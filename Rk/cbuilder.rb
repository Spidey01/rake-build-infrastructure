require 'rake/clean'
require 'Rk/builder'

#
# A version of Builder suited for C/C++ type languages.
#
class CBuilder < Builder
  public
    def make_static_library slib, objs
      make_thing('make_static_library', '${SOURCE}' => objs.join(' '), 
                                        '${TARGET}' => slib)
    end

    def make_shared_library dll, objs, implib=nil
      make_thing('make_shared_library', '${TARGET}' => dll,
                                        '${SOURCE}' => objs.join(' '),
                                        '${IMPLIB}' => implib.to_s)
    end

    def exeext
      query_ext 'executable'
    end

    def shlibext
      query_ext 'sharedlib'
    end

    def stlibext
      query_ext 'staticlib'
    end

    def implibext
      query_ext 'implib'
    end


    #
    # Generates a file task to create/clean a shared library 'name' from
    # the object files 'objs'.
    #
    # Returns the shared libraries file name, e.g. libfoo.so
    #
    def shlib_file name, objs
      implib = distdir('lib', 
                       File.basename(name.sub(/#{shlibext}$/, implibext)))
      expfile = implib.sub(/#{implibext}$/, '.exp')
      manifest = "#{name}.manifest"

      file name => objs do
        make_shared_library(name, objs, implib)
      end

      CLEAN.include objs
      CLOBBER.include name, implib, manifest, expfile

      name
    end


    #
    # finds all C/C++ header files in the named directories.
    # block is passed the file path of the current header.
    #
    # Returns the file names of each header as an array.
    #
    def find_headers *dirs, &block
      targets = Array.new

      for d in dirs do
        find_files(d, /.*\.h[hxp]*$/) do |header|
          yield header
        end

        unless targets.include? d
          targets.push(d)
        end
      end

      targets
    end

    #
    # Creates tasks to install all the header files in the input directory
    # (ind) to the output directory (outd).
    #
    # Suitable CLOBBER targets are also profided.
    #
    # Returns a list of directory/file names to match the tasks created.
    #
    #
    def install_headers ind, outd
      install_files(ind, outd, /.*\.h[hxp]*$/)
    end
end

#
# Subclass for use with vendor modules
#
class VendorCBuilder < CBuilder
  protected 
    def setup_paths modname
      v = 'Vendor'

      @paths = Paths.new(File.join(v, modname, 'src'),
                         File.join('Build', @cpu, @os, @toolset, v, modname),
                         File.join('Dist', @cpu, @os, @toolset))
    end
end



