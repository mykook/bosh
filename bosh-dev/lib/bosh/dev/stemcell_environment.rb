require 'fileutils'

module Bosh::Dev
  class StemcellEnvironment
    attr_reader :build_path, :work_path

    def initialize(options)
      mnt = ENV.to_hash.fetch('FAKE_MNT', '/mnt')
      @directory = File.join(mnt, 'stemcells', "#{options.fetch(:infrastructure_name)}")
      @build_path = File.join(directory, 'build')
      @work_path = File.join(directory, 'work')
    end

    def sanitize
      FileUtils.rm_rf('*.tgz')

      system("sudo umount #{File.join(work_path, 'work/mnt/tmp/grub/root.img')} 2> /dev/null")
      system("sudo umount #{File.join(work_path, 'work/mnt')} 2> /dev/null")

      mnt_type = `df -T '#{directory}' | awk '/dev/{ print $2 }'`
      mnt_type = 'unknown' if mnt_type.strip.empty?

      if mnt_type != 'btrfs'
        system("sudo rm -rf #{directory}")
      end
    end

    private

    attr_reader :directory
  end
end
