# frozen_string_literal: true

require 'sweet-moon'

module NanoBot
  module Components
    class Adapter
      def self.apply(_direction, params)
        content = params[:content]

        if params[:fennel] && params[:lua]
          raise StandardError, 'Adapter conflict: You can only use either Lua or Fennel, not both.'
        end

        if params[:fennel]
          content = fennel(content, params[:fennel])
        elsif params[:lua]
          content = lua(content, params[:lua])
        end

        "#{params[:prefix]}#{content}#{params[:suffix]}"
      end

      def self.fennel(content, expression)
        path = "#{File.expand_path('../static/fennel', __dir__)}/?.lua"
        state = SweetMoon::State.new(package_path: path).fennel
        # TODO: global is deprecated...
        state.fennel.eval(
          "(global adapter (fn [content] #{expression}))", 1,
          { allowedGlobals: %w[math string table] }
        )
        adapter = state.get(:adapter)
        adapter.call([content])
      end

      def self.lua(content, expression)
        state = SweetMoon::State.new
        code = "_, adapter = pcall(load('return function(content) return #{
          expression.gsub("'", "\\\\'")
        }; end', nil, 't', {math=math,string=string,table=table}))"

        state.eval(code)
        adapter = state.get(:adapter)
        adapter.call([content])
      end
    end
  end
end
