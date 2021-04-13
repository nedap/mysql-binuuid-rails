# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "mysql-binuuid/version"

Gem::Specification.new do |spec|
  spec.name     = "mysql-binuuid-rails"
  spec.version  = MySQLBinUUID::VERSION
  spec.authors  = ["Mark Oude Veldhuis"]
  spec.email    = ["mark.oudeveldhuis@nedap.com"]

  spec.summary  = "Let ActiveRecord serialize and cast your UUIDs to and from binary columns in your database."
  spec.homepage = "https://github.com/nedap/mysql-binuuid-rails"
  spec.license  = "MIT"

  spec.require_paths = ["lib"]
  spec.files = Dir["**/*"].select { |f| File.file?(f) }
                          .reject { |f| f.end_with?(".gem") }

  spec.required_ruby_version = ">= 2.6"

  spec.add_runtime_dependency "activerecord", ENV["RAILS_VERSION"] || ">= 5"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-spec-context"
  spec.add_development_dependency "minitest-hooks"
  spec.add_development_dependency "rails", ENV["RAILS_VERSION"] || ">= 5" # required for a console
end
