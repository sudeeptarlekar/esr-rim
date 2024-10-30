require 'rim/rim_exception'
require 'rim/rim_info'
require 'rim/dirty_check'

module RIM
  module Command
    class Clean < Command
      def initialize(opts)
        opts.banner = 'Usage: rim clean <local_module_path>'
        opts.description = 'Updates the checksum of rim module'
        opts.separator ''
      end

      def invoke
        local_path = ARGV.shift

        raise RimException, 'Please provide RIM module path' unless local_path

        module_path = "./#{local_path}"
        raise RimException, "#{local_path} is not RIM module" unless RimInfo.exists?(module_path)

        puts "Cleaning RIM module: #{local_path}..."
        DirtyCheck.mark_clean(module_path)

        puts "RIM module cleaned..."
      end
    end
  end
end
