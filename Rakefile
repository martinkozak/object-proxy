# encoding: utf-8
require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler2'

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "object-proxy"
  gem.homepage = "http://github.com/martinkozak/object-proxy"
  gem.license = "MIT"
  gem.summary = "Provides collection of four proxy objects intended for intercepting calls to instance methods. Works as intermediate layer between caller and called. Allows to invoke an handler both before method call and adjust its arguments and after call and post-proccess result. Aimed as tool for instant adapting the complex objects without complete deriving and extending whole classes in cases, where isn\'t possible to derive them as homogenic functional units or where it's simply impractical to derive them."
  gem.email = "martinkozak@martinkozak.net"
  gem.authors = ["Martin Kozák"]
  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
end
Jeweler::RubygemsDotOrgTasks.new
