# frozen_string_literal: true

require 'stringio'

module NanoBot
  module Components
    class Stream < StringIO
      def write(*args)
        if @callback
          @accumulated += args.first
          @callback.call(@accumulated, args.first, false)
        end
        super
      end

      def callback=(block)
        @accumulated = ''
        @callback = block
      end

      def finish
        flush
        result = string.clone
        truncate(0)
        rewind

        if @callback
          @callback.call(@accumulated, nil, true)
          @callback = nil
          @accumulated = nil
        end

        result
      end
    end
  end
end
