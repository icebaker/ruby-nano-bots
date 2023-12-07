# frozen_string_literal: true

require 'stringio'

module NanoBot
  module Components
    class Stream < StringIO
      def write(*args)
        if @callback
          begin
            @accumulated += args.first
          rescue StandardError => _e
            @accumulated = "#{@accumulated.force_encoding('UTF-8')}#{args.first.force_encoding('UTF-8')}"
          end

          @callback.call(@accumulated, args.first, false, args[1])
        end
        super(args.first)
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
