# frozen_string_literal: true

require_relative '../components/crypto'

module NanoBot
  module Controllers
    module Security
      def self.check
        password = ENV.fetch('NANO_BOTS_ENCRYPTION_PASSWORD', nil)
        password = 'UNSAFE' unless password && password != ''

        {
          encryption: Components::Crypto.encrypt('SAFE') != 'SAFE',
          password: password != 'UNSAFE'
        }
      end
    end
  end
end
