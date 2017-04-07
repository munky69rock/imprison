require 'spec_helper'
require 'fileutils'
require 'find'
require 'plist'

describe Imprison do
  let(:uuid) { 'E0A62D1F-3C18-4D74-BFE5-A4167D643966' }

  it 'has a version number' do
    expect(Imprison::VERSION).not_to be nil
  end

  describe '.run' do
    context 'invalid arguments' do
      context 'no uuid' do
        let(:uuid) { nil }
        it { expect { Imprison.run(uuid) }.to raise_error(/no uuid/) }
      end

      context 'invalid uuid' do
        let(:uuid) { 'invalid_uuid' }
        it { expect { Imprison.run(uuid) }.to raise_error(/invalid uuid/) }
      end
    end

    context 'valid arguments' do
      let(:uuid) {}
      let(:src_dir) { File.join(File.dirname(__FILE__), 'src') }
      let(:sample_plist) { File.join(src_dir, 'Info.plist.sample') }
      let(:plist) { File.join(src_dir, 'Info.plist') }
      let(:parsed_sample_plist) { Plist.parse_xml(sample_plist) }
      let(:parsed_plist) { Plist.parse_xml(plist) }

      before do
        File.open(plist, 'w') do |f|
          f.puts(parsed_sample_plist.to_plist)
        end
        stub_const('Imprison::PLUGIN_DIR', src_dir)
        Imprison.run(uuid)
      end

      after do
        Find.find(src_dir) do |path|
          FileUtils.rm path if path != sample_plist && File.file?(path)
        end
      end

      context 'already includes' do
        let(:uuid) { 'DFFB3951-EB0A-4C09-9DAC-5F2D28CC839C' }
        it { expect(parsed_plist).to eq parsed_sample_plist }
      end

      context 'new uuid' do
        let(:uuid) { 'DFFB3951-EB0A-4C09-9DAC-5F2D28CC839D' }
        it { expect(parsed_plist['DVTPlugInCompatibilityUUIDs'].last).to eq uuid }
      end
    end
  end
end
