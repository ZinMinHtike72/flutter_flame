# Adds development/production flavors to a Flutter iOS project.
# Run from the project root on an unflavored project (fresh `flutter create`):
#   ruby scripts/setup_ios_flavors.rb <bundle_id> "<app name>" "<dev app name>"
#   ruby scripts/setup_ios_flavors.rb com.example.myApp "My App" "My App Dev"
#
# Creates Debug|Release|Profile-<flavor> configurations, flavor xcconfigs,
# development/production schemes, and maps them in the Podfile. Requires the
# xcodeproj gem (bundled with CocoaPods). Run `flutter pub get` first so the
# Podfile exists.
require "fileutils"
require "xcodeproj"

bundle_id, app_name, dev_app_name = ARGV
abort("Usage: ruby scripts/setup_ios_flavors.rb <bundle_id> \"<app name>\" \"<dev app name>\"") unless bundle_id && app_name && dev_app_name

FLAVORS = { "development" => [dev_app_name, ".dev"], "production" => [app_name, ""] }.freeze
TYPES = %w[Debug Release Profile].freeze

Dir.chdir("ios") do
  project = Xcodeproj::Project.open("Runner.xcodeproj")
  abort("Already flavored: #{project.build_configurations.map(&:name).join(', ')}") unless (project.build_configurations.map(&:name) - TYPES).empty?
  abort("Podfile missing. Run `flutter pub get` first.") unless File.exist?("Podfile")

  # xcconfig files
  FLAVORS.each do |flavor, (name, suffix)|
    File.write("Flutter/#{flavor}.xcconfig", <<~XC)
      // #{flavor.capitalize} flavor settings, included by *-#{flavor}.xcconfig.
      APP_DISPLAY_NAME = #{name}
      BUNDLE_ID_SUFFIX = #{suffix}
    XC
    TYPES.each do |type|
      File.write("Flutter/#{type}-#{flavor}.xcconfig", <<~XC)
        #include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.#{type.downcase}-#{flavor}.xcconfig"
        #include "Generated.xcconfig"
        #include "#{flavor}.xcconfig"
      XC
    end
  end

  # File references in the Flutter group
  group = project.main_group["Flutter"]
  refs = {}
  FLAVORS.each_key do |flavor|
    (["#{flavor}.xcconfig"] + TYPES.map { |t| "#{t}-#{flavor}.xcconfig" }).each do |file|
      path = "Flutter/#{file}"
      ref = group.files.find { |r| r.path == path } || group.new_file(path)
      ref.path = path
      ref.source_tree = "<group>"
      refs[file] = ref
    end
  end

  # Build configurations
  lists = [[nil, project.build_configuration_list]] + project.targets.map { |t| [t.name, t.build_configuration_list] }
  lists.each do |target_name, list|
    TYPES.each do |type|
      base = list.build_configurations.find { |c| c.name == type }
      FLAVORS.each do |flavor, (_, suffix)|
        config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
        config.name = "#{type}-#{flavor}"
        config.build_settings = Marshal.load(Marshal.dump(base.build_settings))
        case target_name
        when "Runner"
          config.base_configuration_reference = refs["#{type}-#{flavor}.xcconfig"]
          config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "#{bundle_id}$(BUNDLE_ID_SUFFIX)"
        when "RunnerTests"
          # CocoaPods owns this target's base configuration.
          config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "#{bundle_id}#{suffix}.RunnerTests"
        else
          config.base_configuration_reference = base.base_configuration_reference
        end
        list.build_configurations << config
      end
    end
    TYPES.each do |type|
      old = list.build_configurations.find { |c| c.name == type }
      list.build_configurations.delete(old)
      old.remove_from_project
    end
    list.default_configuration_name = "Release-production"
  end
  project.save

  # Display name
  plist = "Runner/Info.plist"
  content = File.read(plist)
  content.sub!(%r{(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)}, '\1$(APP_DISPLAY_NAME)\2') or abort("CFBundleDisplayName not found in #{plist}")
  File.write(plist, content)

  # Schemes
  schemes = "Runner.xcodeproj/xcshareddata/xcschemes"
  runner = File.read("#{schemes}/Runner.xcscheme")
  FLAVORS.each_key do |flavor|
    File.write("#{schemes}/#{flavor}.xcscheme",
               runner.gsub(/buildConfiguration = "(Debug|Release|Profile)"/) { %(buildConfiguration = "#{Regexp.last_match(1)}-#{flavor}") })
  end
  FileUtils.rm("#{schemes}/Runner.xcscheme")

  # Podfile
  podfile = File.read("Podfile")
  mapping = FLAVORS.keys.flat_map do |flavor|
    ["  'Debug-#{flavor}' => :debug,", "  'Profile-#{flavor}' => :release,", "  'Release-#{flavor}' => :release,"]
  end.join("\n")
  podfile.sub!(/project 'Runner', \{.*?\}/m, "project 'Runner', {\n#{mapping}\n}") or abort("Podfile project mapping not found")
  File.write("Podfile", podfile)

  # Report
  project = Xcodeproj::Project.open("Runner.xcodeproj")
  project.targets.each do |target|
    target.build_configurations.each do |c|
      puts "#{target.name.ljust(12)} #{c.name.ljust(20)} #{(c.base_configuration_reference&.path || '-').ljust(36)} #{c.build_settings['PRODUCT_BUNDLE_IDENTIFIER']}"
    end
  end
end
