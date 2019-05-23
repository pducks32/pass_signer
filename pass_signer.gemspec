# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pass_signer/version'

Gem::Specification.new do |spec|
  spec.name          = 'pass_signer'
  spec.version       = PassSigner::VERSION
  spec.authors       = ['Patrick Metcalfe']
  spec.email         = ['git@patrickmetcalfe.com']

  spec.summary       = 'Signs passes for Apple Wallet.'
  spec.description   = 'Apple Wallet passes require signing. Apple provides code for this, it isnt ideal.'
  spec.homepage      = 'https://github.com/pducks32/pass_signer'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'solargraph'

  spec.add_dependency 'rubyzip'
end
