# frozen_string_literal: true

require_relative 'static/gem'

Gem::Specification.new do |spec|
  spec.name    = NanoBot::GEM[:name]
  spec.version = NanoBot::GEM[:version]
  spec.authors = [NanoBot::GEM[:author]]

  spec.summary = NanoBot::GEM[:summary]
  spec.description = NanoBot::GEM[:description]

  spec.homepage = NanoBot::GEM[:github]

  spec.license = NanoBot::GEM[:license]

  spec.required_ruby_version = Gem::Requirement.new(">= #{NanoBot::GEM[:ruby]}")

  spec.metadata['allowed_push_host'] = NanoBot::GEM[:gem_server]

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = NanoBot::GEM[:github]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['ports/dsl']

  spec.executables = ['nb']

  spec.add_dependency 'babosa', '~> 2.0'
  spec.add_dependency 'concurrent-ruby', '~> 1.3', '>= 1.3.3'
  spec.add_dependency 'dotenv', '~> 3.1', '>= 3.1.2'
  spec.add_dependency 'pry', '~> 0.14.2'
  spec.add_dependency 'rainbow', '~> 3.1', '>= 3.1.1'
  spec.add_dependency 'rbnacl', '~> 7.1', '>= 7.1.1'
  spec.add_dependency 'redcarpet', '~> 3.6'
  spec.add_dependency 'sweet-moon', '~> 1.0'

  spec.add_dependency 'cohere-ai', '~> 1.1'
  spec.add_dependency 'gemini-ai', '~> 4.0'
  spec.add_dependency 'maritaca-ai', '~> 1.2'
  spec.add_dependency 'mistral-ai', '~> 1.2'
  spec.add_dependency 'ollama-ai', '~> 1.2', '>= 1.2.1'
  spec.add_dependency 'ruby-openai', '~> 7.1'

  spec.add_dependency 'faraday', '~> 2.9', '>= 2.9.2'
  spec.add_dependency 'faraday-typhoeus', '~> 1.1'
  spec.add_dependency 'typhoeus', '~> 1.4', '>= 1.4.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
