module Folgers

    module UI

        def self.prompt_user_with(message)
          delimiter = "=" * message.size

          puts <<-EOS.gsub(/^\s*/, "")
          #{delimiter}
          #{message}
          #{delimiter}
          EOS
        end

    end

end
