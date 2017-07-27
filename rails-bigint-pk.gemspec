# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bigint_pk/version"

Gem::Specification.new do |s|
  s.name        = "rails-bigint-pk"
  s.version     = BigintPk::VERSION
  s.authors     = ["David J. Hamilton"]
  s.email       = ["dhamilton@verticalresponse.com"]
  s.homepage    = ""
  s.summary     = %q{Easily use 64-bit primary keys in rails}
  s.description = %q{Easily use 64-bit primary keys in rails}

  s.rubyforge_project = "rails-bigint-pk"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord", ">= 4.2", "< 5.2"
  s.add_dependency "railties", ">= 4.2", "< 5.2"

  s.add_development_dependency "mysql2"
  s.add_development_dependency "pg"
end
