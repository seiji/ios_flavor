require 'thor'
require 'thor/group'
require 'xcodeproj'
require "pathname"

module IosFlavor
  class CLI < Thor::Group

    def add_frameworks
      dsl = nil
      frameworks = []
      root_path = Dir.getwd
      
      Dir.glob("#{root_path}/Flavorfile").each do |flavorfile|
        dsl = DSL.evaluate(Pathname.new(flavorfile))
        frameworks = dsl.frameworks
      end

      if (dsl)
        Dir.glob("#{root_path}/**/*.xcodeproj").each do |xcodeproj_path|        
          project = Xcodeproj::Project.new(xcodeproj_path)
          project.add_frameworks(dsl, frameworks)
          project.save_as(xcodeproj_path)
        end
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

    def add_frameworks(dsl, frameworks)
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

      frameworks.each do |fname|
        unless (group.files.find {|f|
                  cname = (f.name =~ /framework$/) ? "#{fname}.framework" :  fname
                  f.name == cname
                })
          if (framework = add_system_framework(platform_path, fname))

            framework.group = group
            frameworks_build_phases_list.each do |buildPhase|
              buildPhase.files << framework
            end
          end

        end
      end
    end
  end
end
