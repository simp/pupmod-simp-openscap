require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet/version'
require 'puppet/vendor/semantic/lib/semantic' unless Puppet.version.to_f < 3.6
require 'puppet-syntax/tasks/puppet-syntax'

# These gems aren't always present, for instance
# on Travis with --without development
begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
end


# FIXME: move all this lint logic into simp-rake-helpers
Rake::Task[:lint].clear

# Lint Material
begin
  require 'puppet-lint/tasks/puppet-lint'

  PuppetLint.configuration.send("disable_80chars")
  PuppetLint.configuration.send("disable_variables_not_enclosed")
  PuppetLint.configuration.send("disable_class_parameter_defaults")

  PuppetLint.configuration.relative = true
  PuppetLint.configuration.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"
  #PuppetLint.configuration.fail_on_warnings = true

  # Forsake support for Puppet 2.6.2 for the benefit of cleaner code.
  # http://puppet-lint.com/checks/class_parameter_defaults/
  PuppetLint.configuration.send('disable_class_parameter_defaults')
  # http://puppet-lint.com/checks/class_inherits_from_params_class/
  PuppetLint.configuration.send('disable_class_inherits_from_params_class')

  exclude_paths = [
    "bundle/**/*",
    "pkg/**/*",
    "dist/**/*",
    "vendor/**/*",
    "spec/**/*",
  ]
  PuppetLint.configuration.ignore_paths = exclude_paths
  PuppetSyntax.exclude_paths = exclude_paths
rescue LoadError
  puts "== WARNING: Gem puppet-lint not found, lint tests cannot be run! =="
end

begin
  require 'simp/rake/pkg'
  Simp::Rake::Pkg.new( File.dirname( __FILE__ ) ) do | t |
    t.clean_list << "#{t.base_dir}/spec/fixtures/hieradata/hiera.yaml"
  end
rescue LoadError
  puts "== WARNING: Gem simp-rake-helpers not found, pkg: tasks cannot be run! =="
end


desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/acceptance'
end

desc "Populate CONTRIBUTORS file"
task :contributors do
  system("git log --format='%aN' | sort -u > CONTRIBUTORS")
end

task :metadata do
  sh "metadata-json-lint metadata.json"
end

desc "Run syntax, lint, and spec tests."
task :test => [
  :syntax,
  :lint,
  :spec,
  :metadata,
]
