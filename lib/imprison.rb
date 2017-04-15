require 'imprison/version'
require 'find'
require 'fileutils'
require 'plist'

module Imprison
  PLUGIN_DIR = "#{ENV['HOME']}/Library/Application Support/Developer/Shared/Xcode/Plug-ins".freeze

  def self.run(uuid, options = {})
    raise 'no uuid specified.' if uuid.nil?
    raise 'invalid uuid specified.' unless uuid[/^[0-9A-F]{8}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{12}$/]

    dir = options[:dir] || PLUGIN_DIR
    raise "#{dir} not found." unless File.exist?(dir)

    Find.find(dir) do |path|
      next unless path[/info\.plist$/i]
      result = Plist.parse_xml(path)
      uuids = result['DVTPlugInCompatibilityUUIDs']
      next if uuids.include?(uuid)
      uuids.push(uuid)

      unless options[:no_backup]
        FileUtils.cp path, "#{path}.#{Time.now.strftime('%Y%m%d_%H%M')}"
      end
      File.open(path, 'w') do |f|
        f.puts(result.to_plist)
      end
      puts "Updated '#{path}'"
    end
  end
end
