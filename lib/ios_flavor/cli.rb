require 'thor'
require 'thor/group'
require 'xcodeproj'

module IosFlavor
  class CLI < Thor::Group
    class_option :frameworks, :default => %W(
AudioToolbox
CFNetwork
CoreGraphics
CoreLocation
Foundation
MediaPlayer
OpenAL
OpenGLES
QuartzCore
UIKit
)

    def add_frameworks
      frameworks = options[:frameworks]
      root_path = Dir.getwd

      Dir.glob("#{Dir.getwd}/projects/Test_org/*.xcodeproj").each do |xcodeproj_path|
        project = Xcodeproj::Project.new(xcodeproj_path)
        project.add_frameworks(frameworks)

        project.save_as("#{Dir.getwd}/projects/Test/Test.xcodeproj")
      end
    end
  end
end

module Xcodeproj
  class Project
    def get_group(name)
      self.groups.find {|g| g.name == name } || self.groups.new({ 'name' => name })
    end

    def add_system_framework(fname)
      name, path = nil, nil
      if (fname =~ /^lib/)
        name, path = fname, "usr/lib/#{fname}"
      else
        name, path = "#{fname}.framework", "System/Library/Frameworks/#{fname}.framework"
      end
      self.files.new({
                       'name' => name,
                       'path' => path,
                       'sourceTree' => 'SDKROOT',
                     })
    end

    def add_frameworks(frameworks)
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
      frameworks.each do |fname|
        unless (group.files.find {|f|
              cname = (f.name =~ /framework$/) ? "#{fname}.framework" :  fname
              f.name == cname
            })
          puts fname
          framework = add_system_framework(fname)
          framework.group = group
          frameworks_build_phases_list.each do |buildPhase|
            puts buildPhase
            buildPhase.files << framework
          end
        end
      end
    end
  end
end
