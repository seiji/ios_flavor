require 'thor'
require 'thor/group'
require 'xcodeproj'
require "pathname"

module IosFlavor
  class CLI < Thor

    def initialize(*args)
      super
      @dsl = nil
      @xcodeproj_path = nil;
      root_path = Dir.getwd

      Dir.glob("#{root_path}/Flavorfile").each do |flavorfile|
        @dsl = DSL.evaluate(Pathname.new(flavorfile))
      end

      if (@dsl)
        Dir.glob("#{root_path}/**/*.xcodeproj").each do |xcodeproj_path|        
          @project = Xcodeproj::Project.new(xcodeproj_path)
          @xcodeproj_path = xcodeproj_path
        end
      end
    end

    desc "init", "create Flavorfile skelton"
    def init
      File.open('Flavorfile', 'w') do |io|
        io.puts <<EOS
platform 'iPhoneOS', '6.0'

#framework 'MobileCoreServices'

settings \
common: {
#  'HEADEsettingsR_SEARCH_PATHS' => ['${SDKROOT}/usr/include/libxml2'],
#  'GCC_ENABLE_OBJC_EXCEPTIONS'  => 'YES',
#  'SKIP_INSTALL'                => 'NO'
},
'Debug' => {
#  'OTHER_LDFLAGS' => ['-ObjC,-all_load'],
},
'Release'=> {
#  'OTHER_LDFLAGS' => ['-Wl,-S,-x'],
}

EOS
      end
    end

    desc 'install', "flavor ur xcodeproject"
    def install
      if (@dsl and @project)
        @project.add_frameworks(@dsl)
        @project.add_settings(@dsl)
        @project.save_as(@xcodeproj_path)
      end
    end
  end
end

module Xcodeproj
  class Project
    def get_group(name)
      self.groups.find {|g| g.name == name } || self.groups.new({ 'name' => name })
    end

    def add_system_framework(platform_path, fname)
      name, path = nil, nil
      if (fname =~ /^lib/)
        name, path = fname, "usr/lib/#{fname}"
      else
        name, path = "#{fname}.framework", "System/Library/Frameworks/#{fname}.framework"
      end
      target = platform_path + path
      target.realpath           # check framework
      puts "Add Framework [#{name}]"
      self.files.new({
                       'name' => name,
                       'path' => path,
                       'sourceTree' => 'SDKROOT',
                     })
    rescue SystemCallError => e
      puts "No such Framework [#{name}]"
      nil
    end

    def add_settings(dsl)
      self.targets.each do |target|
        target.build_configurations.each do |conf|
          puts "Add Settings [#{target.name} #{conf.name}]"
          build_settings = dsl.build_settings[:common].merge(dsl.build_settings[conf.name])
          conf.build_settings.merge!(build_settings)
        end
      end
    end

    def add_frameworks(dsl)
      group = get_group('Frameworks')
      frameworks_build_phases_list = []
      self.targets.each do |target|
        target.frameworks_build_phases.each do |phase|
          frameworks_build_phases_list.push(phase)
        end
      end
      self.files.sort{|a,b| a.name <=> b.name }.each do |file|
        path = file.path
        if (path =~ /^System\/Library\/Frameworks/ or path =~ /^usr\/lib/)
          file.group = group
        end
      end

      path = `xcode-select --print-path`.chomp
      platform_path = Pathname.new("#{path}/Platforms/#{dsl.platform_name}.platform/Developer/SDKs/#{dsl.platform_name}#{dsl.version}.sdk/")

      dsl.frameworks.each do |fname|
        unless (group.files.find {|f|
                  cname = (f.name =~ /framework$/) ? "#{fname}.framework" :  fname
                  f.name == cname
                })
          if (framework = add_system_framework(platform_path, fname))

            framework.group = group
            frameworks_build_phases_list.each do |build_phase|
              build_phase.files << framework.build_files.new
            end
          end
        end
      end
    end
  end
end
