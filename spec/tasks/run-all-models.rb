# frozen_string_literal: true

require 'dotenv/load'

require 'yaml'

require_relative '../../ports/dsl/nano-bots'
require_relative '../../logic/helpers/hash'

def run_model!(cartridge, stream = true)
  if stream == false
    cartridge[:provider][:options] = {} unless cartridge[:provider].key?(:options)
    cartridge[:provider][:options][:stream] = false

    cartridge[:provider][:settings] = {} unless cartridge[:provider].key?(:settings)
    cartridge[:provider][:settings][:stream] = false
  end

  puts "\n#{cartridge[:meta][:symbol]} #{cartridge[:meta][:name]}\n\n"

  bot = NanoBot.new(cartridge:)

  output = bot.eval('Hi!') do |_content, fragment, _finished, _meta|
    print fragment unless fragment.nil?
  end
  puts ''
  puts '-' * 20
  puts ''
  puts output
  puts ''
  puts '*' * 20
end

puts '[NO STREAM]'

Dir['spec/data/cartridges/models/*/*.yml'].each do |path|
  run_model!(
    NanoBot::Logic::Helpers::Hash.symbolize_keys(
      YAML.safe_load_file(path, permitted_classes: [Symbol])
    ),
    false
  )
end

puts "\n[STREAM]"

Dir['spec/data/cartridges/models/*/*.yml'].each do |path|
  run_model!(
    NanoBot::Logic::Helpers::Hash.symbolize_keys(
      YAML.safe_load_file(path, permitted_classes: [Symbol])
    )
  )
end
