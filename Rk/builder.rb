#
# the idea:
#
# +load details into Builder from system specific YAML file
# load custom YAML from next to Rakefile
# Create a builder per module
# +most stuff in lib moves into Builder
#
# +-> make even the commands be templated into YAML
# +-> abstract Builder::ftype into the YAML settings.
# -> make ${foo:bar} work
# -> make ${foo:bar:ham} to an abritary level work
#

require 'rake/clean'
require 'Rk/lib'

#
# Helpful container for our usual pathing needs
#
Paths = Struct.new :sd, :bd, :dd

#
# Class representing build time setting
#
class Builder
  public
    #
    # sets p the Builder obect for building the module 'modname', using
    # settings defined for language 'lang'.
    #
    def initialize modname, lang
      require 'platform'

      @cpu = Platform::ARCH
      @os = Platform::OS

      if @os == :unix then # we need to be more specific
        @os = Platform::IMPL
      end

      setup_toolset
      setup_paths modname
      setup_conf lang, modname
    end

    def make_object obj, src
      make_thing 'make_object', '${TARGET}' => obj, '${SOURCE}' => src
    end

    def make_executable exe, objs, libs
      libsfilter = Proc.new { |s|

        libstoflags(libs)
      }

      make_thing('make_executable', '${TARGET}' => exe,
                                    '${SOURCE}' => objs.join(' '),
                                    '${LIBS_TEMPLATE}' => libsfilter)
    end

    def make_library name, objs
      make_thing('make_library', '${SOURCE}' => objs.join(' '), 
                                 '${TARGET}' => name)
    end

    def srcext
      query_ext 'source'
    end

    def objext
      query_ext 'object'
    end

    def libext
      query_ext 'library'
    end

    def srcdir(*f)
      getdir @paths.sd, *f
    end

    def builddir(*f)
      getdir @paths.bd, *f
    end

    def distdir(*f)
      getdir @paths.dd, *f
    end

    #
    # Generates a file task to create/clean an object file from 'source'
    #
    # Returns the object file name.
    #
    def obj_file source
      ext = @data['extensions'][@language]['source']
      obj, src = builddir(source.sub(/#{ext}$/, objext)), srcdir(source)
      d = File.dirname(obj)

      directory d
      file obj => [ d, src ] do
        make_object obj, src
      end
      CLEAN.include obj

      obj
    end

    def install_files ind, outd, rx=Regexp.compile('.*')
      targets = Array.new

      find_files ind, rx do |f|
        outfile = f.sub ind, outd
        outdir = File.dirname outfile

        directory outdir
        file outfile => f do
          cp_r f, outfile
        end
        CLOBBER.include outfile, outdir

        unless targets.include? outfile
          targets.push(outdir, outfile) 
        end
      end

      targets
    end

    def dump_settings
      require 'pp'

      pp @data

      @data
    end

    attr_reader :cpu, :os, :toolset, :language

  protected

    def setup_toolset
      @toolset = ENV['toolset']

      return if @toolset

      # provide a default toolset  where applicable
      #
      case @os
        when :win32
          @toolset = 'msvc'
        else 
          @toolset = :unknown
      end

    end

    def setup_paths modname
      @paths = Paths.new(File.join('Source', modname),
                         File.join('Build', "#{@cpu}", "#{@os}", 
                                   "#{@toolset}", modname),
                         File.join('Dist', "#{@cpu}", "#{@os}", "#{@toolset}"))
    end

    def setup_conf lang, modname
      @language = lang
      yamlconf = "#{@cpu}.#{@os}.#{@toolset}.yml"

      #
      # Load the main build settings
      #
      require 'yaml'
      maincfg = File.join('Rk', 'conf', yamlconf)
      begin
        @data = YAML.load_file(maincfg)
      rescue Errno::ENOENT
        Error "Missing #{maincfg}, please create it with the correct settings!"
      end

      #
      # If present, load additional (overriding) settings from alongside
      # the current module.
      #
      begin
        @data.merge! YAML.load_file(File.join(File.dirname(srcdir()), 
                                              'conf', yamlconf))
      rescue Errno::ENOENT
        # pass
      end

      setup_lut
    end

  private

    # expand expression s and return s
    #
    # the hash evrs is used used to supplement the parsed yaml configuration
    # data.
    #
    def expand s, evars
      return unless s

      ns = s.clone
      t = @vars.merge(evars)

      for var in t.keys do
        p = t[var]
        if p.respond_to? :call
          p = p.call(var)
        end

        ns.gsub!(var, p)
      end

      ns
    end

    def make_thing thing, evars, cb=nil
      begin
        c = expand @data['commands'][@language][thing], evars
        sh c
        #puts "\n\n#{c}\n\n"
      rescue NoMethodError
        puts 'Build settings missing or incorrect for language ' + @language
      end
    end

    def query_ext name
      @data['extensions'][@language][name]
    end

    def setup_lut
      # Construct a simple LUT to map environment variable forms to their
      # associated nested data structure; that is the nested hashes we jimmy
      # between YAML and Ruby.
      #
      # XXX
      #   While we could save even more run time by combining the loops, and
      #   making each program corispond to a flags in the usual convention,
      #   that wouldn't process the file correctly. So use the seperate
      #   loops. It's all faster than the average monkey any way.
      #
      @vars = Hash.new


      # keys in the 'programs' hash are taken as name=>command pairs.
      # Each name written as ${NAME} in s, expand to command.
      #
      for prog in @data['programs'].keys do
        p = '${'+prog.upcase+'}'
        @vars[p] = @data['programs'][prog]
      end

      # keys in the 'options' has are taken as the following:
      #   name => { category => options, ... }
      #
      # Occurences of ${NAME} in s, will be replaced with each category set
      # for name.
      #
      for flag in @data['options'].keys do
        o = @data['options'][flag] 
        f = '${'+flag.upcase+'}'
        @vars[f] = ''

        # XXX not pretty but it filters out any enter we're not looking for
        #
        next unless o.respond_to? :[] and o.respond_to? :each_key

        o.each_key do |val| 
          v = o[val]
          if v==nil
            Error "Assertion failed: v==nil for o[#{val}]"
            next
          end
          @vars[f] += " #{v}"
        end
      end
    end

    def getdir(d, *f)
      return d unless f

      File.join d, *f
    end

    def libstoflags libs
      t = @data['template_vars']['libs_template']
      ls = ''

      for l in libs do
        ls << t.gsub('${LIB}', l) << " "
      end

      ls
    end

    @data     = Hash.new
    @vars     = Hash.new
    @paths    = nil
    @cpu      = :unknown
    @os       = :unknown
    @toolset  = :unknown
end

#
# Subclass for use with vendor modules
#
class VendorBuilder < Builder
  protected 
    def setup_paths modname
      v = 'Vendor'

      @paths = Paths.new(File.join(v, modname, 'src'),
                         File.join('Build', @cpu, @os, @toolset, v, modname),
                         File.join('Dist', @cpu, @toolset, @os))
    end
end

