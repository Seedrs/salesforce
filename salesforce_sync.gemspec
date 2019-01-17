# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "salesforce_sync/version"

Gem::Specification.new do |s|
  s.name                    = "salesforce_sync"
  s.version                 = SalesforceSync::VERSION
  s.date                    = "2017-06-22"

  s.authors                 = ["Benjamin Sotty"]
  s.email                   = "ben.sotty@seedrs.com"

  s.summary                 = "Event based rails Salesforce synchronisation library"
  s.description             = "A scalable way to synchronise a Rails application with Salesforce"
  s.homepage                = "https://github.com/Seedrs/salesforce"
  s.license                 = "MIT"

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "rails", [">= 4.2.11"]
  s.add_runtime_dependency "delayed_job_active_record", [">= 4.1.1"]
  s.add_runtime_dependency "event_bus", [">= 1.1.1"]
  s.add_runtime_dependency "restforce", [">= 3.0.0"]
  s.add_runtime_dependency "salesforce_bulk_api", [">= 0.0.12"]
  s.add_runtime_dependency "sprockets", [">= 2.12.5"]
  s.add_runtime_dependency "rack", [">= 1.6.11"]
  s.add_runtime_dependency "nokogiri", [">= 1.8.2"]
  s.add_runtime_dependency "rails-html-sanitizer", [">= 1.0.4"]
  s.add_runtime_dependency "loofah", [">= 2.2.3"]

  s.add_development_dependency "rspec", [">= 3.5"]
  s.add_development_dependency "timecop", [">= 0.6.3"]
  s.add_development_dependency "pry"
end
