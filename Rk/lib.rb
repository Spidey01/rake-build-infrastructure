def Error(msg, status=1)
  puts "ERROR: #{msg}", "STOPPING BUILD".center(ENV['COLUMNS']||70)
  exit status
end

def Warn(msg)
  puts "WARNING: "+msg
end

def Notice(msg)
  puts "NOTICE: "+msg
end

#
# Recursively loads any Rakefile from the directory names given as
# arguments. This function may throw any of the usual exceptions.
#
def load_r(*dirs)
  require 'find'

  begin
    Find.find(*dirs) do |p| 
      if p =~ /Rakefile$/i or p =~ /Rakefile.rb$/
        load p
      end
    end
  rescue LoadError => msg
    Error msg
  end
end

#
# Find files in dir that match the pattern, yielding to the required block.
#
def find_files(dir, pattern, &block)
  require 'find'

  Find.find(dir) do |p|
    if p =~ Regexp.compile(pattern)
      yield p
    end
  end
end


#
# A magic function that generates file tasks that copy all headers from
# directory ind # to directory outd.  Any missing directories are created as
# needed.
#
# The return value is a list suitable for the right hand side of a task, e.g.
#
#   task :headers => header_magic(src, dest)
#
def header_magic(ind, outd)
  dirs = []
  hdrs = []

  find_files(ind, /.*\.h[hxp]*$/) do |p|
    outdir = File.dirname p.sub(ind, outd)
    outfile = File.join(outd, File.basename(p))

    directory outdir
    file outfile => p do
      cp_r p, outdir
    end
    dirs.push outdir
    hdrs.push outfile
    CLEAN.include outfile, outdir
  end

  dirs+hdrs
end
