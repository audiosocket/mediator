Gem::Specification.new do |gem|
  gem.authors       = ["Audiosocket"]
  gem.email         = ["tech@audiosocket.com"]
  gem.description   = "A go-between for models."
  gem.summary       = "Translates models to and from primitive representations."
  gem.homepage      = "https://github.com/audiosocket/mediator"

  gem.files         = `git ls-files`.split "\n"
  gem.test_files    = `git ls-files -- test/*`.split "\n"
  gem.name          = "mediator"
  gem.require_paths = ["lib"]
  gem.version       = "0.4.2"

  gem.required_ruby_version = ">= 1.9.2"
end
