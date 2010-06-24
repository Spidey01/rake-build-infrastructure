require 'Rk/cbuilder'

#
# Create our builder object, configured for the 'c' language type
#
# '' = no module
#
b = CBuilder.new '', 'c'

# This recursively loads rakefiles from the named directories
#
load_r 'Source', 'Vendor'


#
# Directories we want rake to create for us
#
dirs = [ b.distdir(), b.distdir('include'), b.distdir('lib'), b.builddir() ]
#
# A simple dependency on third party library called foolib
#
deps = [ 'vendor:foolib:default' ]
#
# Modules to build from Source/
#
mods = [ 'MyLib:default', 'MyApp:default' ]




#
# Simple default rule that builds what we've defined above
#
desc "A C based example"
task :default => dirs + deps + mods

# Ensure the rules for our directories get done
#
for d in dirs do
  directory d
end

#
# Uncomment for easy nuking of all generated files
#
#   rake clean => erase build tree
#   rake clobber => erase dist files
#
#CLEAN.include b.builddir()
#CLOBBER.include b.distdir()

