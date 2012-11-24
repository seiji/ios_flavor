require 'thor'
require 'xcodeproj'
require "pathname"

module IosFlavor
  class CLI < Thor
    include Thor::Actions

    def initialize(*args)
      super
      @dsl = nil
      @xcodeproj_path = nil;
      root_path = Dir.getwd
#      puts root_path
#      root_path = File.join(root_path,"snap")        # TO DELETE:
      
      Dir.glob("#{root_path}/Flavorfile").each do |flavorfile|
        @dsl = DSL.evaluate(Pathname.new(flavorfile))
      end

      if (@dsl)
        Dir.glob("#{root_path}/**/*.xcodeproj").each do |xcodeproj_path|        
          @project = Xcodeproj::Project.new(xcodeproj_path)
          @xcodeproj_path = xcodeproj_path

          @project_dir = File.dirname @xcodeproj_path
          @project_name = File.basename @project_dir
          @project_dir_source = File.join(@project_dir, @project_name)
        end
      end
    end

    desc "init", "create Flavorfile skelton"
    def init
      IosFlavor::CLI.source_root(IosFlavor.templates)
      template('Flavorfile', 'Flavorfile')
    end

    desc 'install', "flavor ur xcodeproject"
    def install
      if (@dsl and @project)
        @project.add_frameworks(@dsl)
        @project.add_settings(@dsl)
        @project.save_as(@xcodeproj_path)

        product_name = nil
        @project.targets.each do |target|
          product_name = target.name
        end
        unless product_name
          puts "target not found"
          return;
        end
        
        opts = {
          product_name: product_name
        }
        IosFlavor::CLI.source_root(IosFlavor.templates)
        template('Rakefile',  File.join(@project_dir, 'Rakefile'))
        template(
                 File.join('config','environment.yml'),
                 File.join(@project_dir, 'config', 'environment.yml'),
                 opts)
        template(
                 File.join('config','project.yml'),
                 File.join(@project_dir, 'config', 'project.yml'),
                 opts)

        directory('classes',  File.join(@project_dir_source, 'classes'))
        directory('lib',      File.join(@project_dir_source, 'lib'))
        directory('resources',File.join(@project_dir_source, 'resources'))

        # versioning
        
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
      self.build_configurations.each do |conf|
        puts "Add Settings [project #{conf.name}]"
        build_settings = dsl.build_settings[:common].merge(dsl.build_settings[conf.name])
        conf.build_settings.merge!(build_settings)
      end

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
              build_phase.files << framework
            end
          end
        end
      end
    end
  end
end
