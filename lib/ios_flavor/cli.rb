require 'thor'
require "pathname"

module IosFlavor
  class CLI < Thor
    include Thor::Actions

    def initialize(*args)
      super
      @dsl = nil
      @xcodeproj_path = nil;
      root_path = Dir.getwd

      # TO DELETE:
      # puts root_path
      # root_path = File.join(root_path,"sample")
      
      Dir.glob("#{root_path}/Flavorfile").each do |flavorfile|
        @dsl = DSL.evaluate(Pathname.new(flavorfile))
      end

      if (@dsl)
        Dir.glob("#{root_path}/**/*.xcodeproj").each do |xcodeproj_path|        
          @project = XcodeProject::Project.new(xcodeproj_path)
          @xcodeproj_path = xcodeproj_path

          @project_dir        = File.dirname @xcodeproj_path
          @project_name       = File.basename @project_dir
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

        opts = {
           product_name: @project.name
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

        @project.change do |data|
          # Layout
          group = data.group(@project.name)
          if (group)
            %w[classes lib resources].each do |name|
              group.add_group(name)
              group.add_dir(name)      
            end
          end
          
          # Frameworks
          data.add_frameworks(@dsl)

          # Settings
          data.add_settings(@dsl)
          
        end
        # versioning
        run "agvtool new-version -all 1"
      end
    end

  end
end
