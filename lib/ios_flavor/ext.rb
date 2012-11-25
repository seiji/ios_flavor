require "xcodeproject"

module XcodeProject
  class Data
    def configs
      project.configs
    end

    def add_frameworks(dsl)
      path = `xcode-select --print-path`.chomp
      platform_path = Pathname.new("#{path}/Platforms/#{dsl.platform_name}.platform/Developer/SDKs/#{dsl.platform_name}#{dsl.version}.sdk/")

      group = group('Frameworks')
      dsl.frameworks.each do |name|
        if (name =~ /^lib/)
          path ="usr/lib/#{name}"
        else
          path ="System/Library/Frameworks/#{name}.framework"
        end
        abs_path = group.absolute_path(File.join(platform_path, path))
        raise FilePathError.new("No such file '#{abs_path}'.") unless abs_path.exist?

        framework = group.add_framework(path)
        targets.each do |target|
          target.add_framework(framework)
        end
      end
    end

    def add_settings(dsl)      
      process = lambda {|config, target=nil|

        build_settings = dsl.build_settings[:common].merge(dsl.build_settings[config.name])
        # puts build_settings
        # if target
        #   puts "%-10s - %s" % [config.name, target.name]
        # else
        #   puts "%-10s" % [config.name]
        # end
        config.build_settings.merge!(build_settings)
      }

      # global
      configs.each do |config|
        process.call(config)
      end

      # target
      targets.each do |target|
        target.configs.each do |config|
          process.call(config, target)
        end
      end
    end
  end

  class PBXProject
    def configs
      configuration_list = root.object!(data['buildConfigurationList'])
      configuration_list.build_configurations
    end
  end

  class PBXGroup
    def add_dir (path, gpath = nil)
      path = absolute_path(path)
      raise FilePathError.new("No such directory '#{path}'.") unless path.exist?

      gpath ||= path.basename
      parent = create_group(gpath, path)

      chs = path.entries.select {|obj| obj.to_s =~ /\A\./ ? false : true }
      chs.each do |pn|
        pn =  File.join(path, pn)
        parent.absolute_path(pn).directory? ? parent.add_dir(pn) : parent.add_file(pn)
      end
      parent
    end

    def add_framework(path)
      name = File.basename(path)
      obj = file_ref(name)
      if obj.nil?
        obj = PBXFileReference.add_framework(root, relative_path(path))
        add_child_uuid(obj.uuid)
      end
      obj
    end
  end

  class PBXVariantGroup < PBXGroup; end

  class PBXFileReference
    def self.add_framework(root, path)
      uuid, data = root.add_object(self.create_object_framework_hash(path))
      self.new(root, uuid, data)
    end

    private
    def self.create_object_framework_hash(path)
      path = path.to_s
      name = File.basename(path)
      ext  = File.extname(path)
      raise ParseError.new("No such file type '#{name}'.") if !FileTypeFrameworkMap.include?(ext)

      data = []
      data << ['isa', 'PBXFileReference']
      data << ['sourceTree', 'SDKROOT']
      data << ['lastKnownFileType', FileTypeFrameworkMap[ext]]
      data << ['path', path]
      data << ['name', name] if name != path

      Hash[ data ]
    end

    FileTypeFrameworkMap = {
      '.framework' => 'wrapper.framework',
      '.dylib'     => 'wrapper.framework',
      '.o'         => 'wrapper.framework',
    }
  end

  class PBXNativeTarget
    def add_framework(file_ref)
      phase = frameworks_build_phase
      phase.add_file(file_ref)
    end
  end
end
