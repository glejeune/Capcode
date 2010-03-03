require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'json/pure'
require 'open-uri'
require 'fileutils'
require './lib/capcode/version'
include FileUtils

NAME = "Capcode"
VERS = Capcode::CAPCOD_VERION
CLEAN.include ['**/.*.sw?', '*.gem', '.config', 'test/test.log']
RDOC_OPTS = ['--quiet', '--title', "Capcode, the Documentation",
  "--line-numbers",
  "--main", "README.rdoc",
  "--inline-source"]

desc "Packages up Capcode."
task :default => [:package]
task :package => [:clean]

task :doc => [:rdoc, :after_doc]

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += RDOC_OPTS
  rdoc.main = "README.rdoc"
  rdoc.title = "Capcode, the Documentation"
  rdoc.rdoc_files.add [
    'README.rdoc', 
    'AUTHORS', 
    'COPYING',
    'lib/capcode.rb',
    'lib/capcode/base/db.rb',
    'lib/capcode/configuration.rb',
    'lib/capcode/filters.rb'
  ] + Dir.glob( "lib/capcode/render/*.rb" ) + Dir.glob( "lib/capcode/helpers/*.rb" )
end

task :after_doc do
  sh %{scp -r doc/rdoc/* #{ENV['USER']}@rubyforge.org:/var/www/gforge-projects/capcode/}
end

spec =
  Gem::Specification.new do |s|
    s.name = NAME
    s.version = VERS
    s.platform = Gem::Platform::RUBY
    s.has_rdoc = true
    s.extra_rdoc_files = ["README.rdoc", "AUTHORS", "COPYING",
      'lib/capcode.rb', 'lib/capcode/configuration.rb', 'lib/capcode/base/db.rb'] + Dir.glob( "lib/capcode/render/*.rb" )
    s.rdoc_options += RDOC_OPTS + ['--exclude', '^(examples|extras|test|lib)\/']
    s.summary = "Capcode is a web microframework"
    s.description = s.summary
    s.author = "Grégoire Lejeune"
    s.email = 'gregoire.lejeune@free.fr'
    s.homepage = 'http://algorithmique.net'
    s.rubyforge_project = 'capcode'

    s.add_dependency('rack')
    s.add_dependency('activesupport')
    # s.add_dependency('mime-types')
    s.required_ruby_version = ">= 1.8.1"

    s.files = %w(COPYING README.rdoc AUTHORS setup.rb) + 
      Dir.glob("{bin,doc,test,lib,examples}/**/*").delete_if {|item| item.include?("CVS") or item.include?("._")}
       
    s.require_path = "lib"
        
    s.post_install_message = <<EOM

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!                                           !!
!!       0.9.0 WAS A MAJOR ENHANCEMENT       !!
!!    -----------------------------------    !!
!!                                           !!
!!  YOU MUST UNINSTALL ALL PREVIOUS          !!
!!  VERSIONS !!!                             !!
!!                                           !!
!!  gem uninstall Capode --version '< 0.9.0' !!
!!                                           !!
!!  IF YOU DON'T DO IT, THIS ONE WILL NOT    !!
!!  WORK !!!                                 !!
!!                                           !!
!!  Moreover :                               !!
!!                                           !!
!!  Renderers and database accessors have    !!
!!  been extracted and are now in the        !!
!!  plugins repository :                     !!
!!                                           !!
!!  http://github.com/glejeune/Capcode.more  !!
!!                                           !!
!!  Each plugin is a gem that’s can be       !!
!!  installed separately.                    !!
!!                                           !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

For more information about Capcode, see 
  http://capcode.rubyforge.org

You can also read the Capcode book (fr) at
  http://algorithmique.net/capcode.html

EOM
  end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true
  p.gem_spec = spec
end

class Rubygems
  def initialize
    url = "http://rubygems.org/api/v1/gems/#{NAME}.json"
    @version_at_rubygems = JSON.parse( open(url).read )["version"]
  end
  
  def status
    version == VERS
  end
  def self.status
    self.new.status
  end
  
  def version
    @version_at_rubygems
  end
  def self.version
    self.new.version
  end
end

namespace :gemcutter do
  desc "push to gemcutter"
  task :push => [:package] do
    unless Rubygems.status
      sh %{gem push pkg/#{NAME}-#{VERS}.gem}, :verbose => true
    else
      puts "This gem already existe in version #{VERS}!"
    end
  end
  
  desc "check gemcutter status"
  task :status do
    if Rubygems.status
      puts "This gem already existe in version #{VERS}!"
    else
      puts "This gem (#{VERS}) has nos been published! Last version at gemcutter is #{Rubygems.version}"
    end
  end
end


task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VERS}}
end

task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end
