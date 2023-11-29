# frozen_string_literal: true

require 'yaml'

require_relative '../logic/helpers/hash'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

def load_symbolized(path)
  cartridge = YAML.safe_load_file("spec/data/#{path}", permitted_classes: [Symbol])

  NanoBot::Logic::Helpers::Hash.symbolize_keys(cartridge)
end
