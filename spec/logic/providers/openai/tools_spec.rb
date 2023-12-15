# frozen_string_literal: true

require 'yaml'

require_relative '../../../../logic/providers/openai/tools'

RSpec.describe NanoBot::Logic::OpenAI::Tools do
  context 'tools' do
    let(:cartridge) { load_symbolized('cartridges/tools.yml') }

    context 'adapt' do
      it 'adapts to OpenAI expected format' do
        expect(described_class.adapt(cartridge[:tools][0])).to eq(
          { type: 'function',
            function: {
              name: 'what-time-is-it',
              description: 'Returns the current date and time for a given timezone.',
              parameters: {
                type: 'object',
                properties: {
                  timezone: {
                    type: 'string',
                    description: 'A string representing the timezone that should be used to provide a datetime, following the IANA (Internet Assigned Numbers Authority) Time Zone Database. Examples are "Asia/Tokyo" and "Europe/Paris".'
                  }
                }, required: ['timezone']
              }
            } }
        )

        expect(described_class.adapt(cartridge[:tools][1])).to eq(
          { type: 'function',
            function: {
              name: 'get-current-weather',
              description: 'Get the current weather in a given location.',
              parameters: {
                type: 'object',
                properties: {
                  location: { type: 'string' },
                  unit: { type: 'string' }
                }
              }
            } }
        )

        expect(described_class.adapt(cartridge[:tools][2])).to eq(
          { type: 'function',
            function: {
              name: 'sh',
              description: "It has access to computer users' data and can be used to run shell commands, similar to those in a Linux terminal, to extract information. Please be mindful and careful to avoid running dangerous commands on users' computers.",
              parameters: {
                type: 'object',
                properties: {
                  command: {
                    type: 'array',
                    description: 'An array of strings that represents a shell command along with its arguments or options. For instance, `["df", "-h"]` executes the `df -h` command, where each array element specifies either the command itself or an associated argument/option.',
                    items: { type: 'string' }
                  }
                }
              }
            } }
        )

        expect(described_class.adapt(cartridge[:tools][3])).to eq(
          { type: 'function',
            function: {
              name: 'clock',
              description: 'Returns the current date and time.',
              parameters: { type: 'object', properties: {} }
            } }
        )
      end
    end

    context 'prepare' do
      let(:tools) { load_symbolized('providers/openai/tools.yml') }

      it 'prepare tools to be executed' do
        expect(described_class.prepare(cartridge[:tools], tools)).to eq(
          [{ id: 'call_XYZ',
             name: 'get-current-weather',
             label: 'get-current-weather',
             type: 'function',
             parameters: { 'location' => 'Tokyo, Japan' },
             source: { fennel: "(let [{:location location :unit unit} parameters]\n  (.. \"Here is the weather in \" location \", in \" unit \": 35.8°C.\"))\n" } },
           { id: 'call_ZYX',
             name: 'what-time-is-it',
             label: 'what-time-is-it',
             type: 'function',
             parameters: {},
             source: { fennel: "(os.date)\n" } }]
        )
      end
    end
  end
end
