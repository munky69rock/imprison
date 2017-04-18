require 'imprison/version'
require 'find'
require 'fileutils'
require 'plist'

module Imprison
  XCODE_DIR = '/Applications/Xcode.app'.freeze
  PLUGIN_DIR = "#{ENV['HOME']}/Library/Application Support/Developer/Shared/Xcode/Plug-ins".freeze

  def self.run(uuid, options = {})
    if uuid.nil?
      info_plist = xcode_info(options[:xcode_dir] || XCODE_DIR)
      raise 'no uuid specified.' if info_plist.nil?
      uuid = current_uuid(info_plist)
      puts "Use current uuid: '#{uuid}'"
    end

    raise 'invalid uuid specified.' unless uuid[/^[0-9A-F]{8}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{4}\-[0-9A-F]{12}$/]

    plugin_dir = options[:plugin_dir] || PLUGIN_DIR
    raise "#{plugin_dir} not found." unless File.exist?(plugin_dir)

    Find.find(plugin_dir) do |path|
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

  private

  def self.xcode_info(xcode_dir)
    info_plist = "#{xcode_dir}/Contents/Info.plist"
    info_plist if File.exist?(info_plist) 
  end

  def self.current_uuid(info_plist)
    `defaults read #{info_plist} DVTPlugInCompatibilityUUID`.chomp
  end
end
