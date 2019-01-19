# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mini_nrepl/version'

Gem::Specification.new do |spec| # rubocop:disable BlockLength
  spec.name          = 'mini-nrepl'
  spec.version       = MiniNrepl::VERSION
  spec.authors       = ['Michael Lutsiuk']
  spec.email         = ['michael.lutsiuk@gmail.com']

  spec.summary       = 'mini-nrepl gives you access to clojure\'s repl'
  spec.description   = 'mini-nrepl gives you access to clojure\'s repl'
  spec.homepage      = 'https://github.com/mluts/mini-nrepl'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bencode', '~> 0.8.2'
  spec.add_dependency 'edn', '~> 1.1'
  spec.add_dependency 'neovim', '~> 0.7'

  spec.add_development_dependency 'guard', '~> 2.14.2'
  spec.add_development_dependency 'guard-minitest', '~> 2.4.6'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry', '~> 0.11.3'
  spec.add_development_dependency 'rake', '~> 10.0'
end
