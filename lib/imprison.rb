require 'imprison/version'
require 'find'
require 'fileutils'
require 'plist'

module Imprison
  PLUGIN_DIR = "#{ENV['HOME']}/Library/Application Support/Developer/Shared/Xcode/Plug-ins".freeze

  def self.run(uiid, options = {})
    raise 'no uiid specified.' if uiid.nil?
    raise 'invalid uiid specified.' unless uiid[/^[0-9A-F]{8}\-[A-Z0-9]{4}\-[A-Z0-9]{4}\-[A-Z0-9]{4}\-[A-Z0-9]{12}$/]

    dir = options[:dir] || PLUGIN_DIR
    raise "#{dir} not found." unless File.exist?(dir)

    Find.find(dir) do |path|
      next unless path[/info\.plist$/i]
      result = Plist.parse_xml(path)
      uiids = result['DVTPlugInCompatibilityUUIDs']
      next if uiids.include?(uiid)
      uiids.push(uiid)

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
