# Configures token-storage prerequisites without replacing custom entitlements.
# Run from the repository root after configuring iOS flavors.
require "fileutils"
require "pathname"
require "xcodeproj"

project_dir = File.expand_path("ios")
project = Xcodeproj::Project.open("ios/Runner.xcodeproj")
runner = project.targets.find { |target| target.name == "Runner" }
abort("Runner target not found") unless runner

# Validate all configured files before mutating any native configuration.
entries = runner.build_configurations.map do |config|
  configured = config.build_settings["CODE_SIGN_ENTITLEMENTS"].to_s
  name = config.name.start_with?("Release") ? "Release" : "DebugProfile"
  relative_path = configured.empty? ? "Runner/#{name}.entitlements" : configured
  resolved = relative_path.dup
  { "SRCROOT" => project_dir, "PROJECT_DIR" => project_dir,
    "CONFIGURATION" => config.name }.each do |key, value|
    resolved.gsub!("$(#{key})", value)
    resolved.gsub!("${#{key}}", value)
  end
  abort("Resolve entitlement path manually: #{relative_path}") if resolved.include?("$")
  path = File.expand_path(resolved, project_dir)
  if !configured.empty? && !File.file?(path)
    abort("Configured entitlement file does not exist: #{path}")
  end
  plist = File.file?(path) ? Xcodeproj::Plist.read_from_path(path) : {}
  groups = plist["keychain-access-groups"]
  abort("Invalid Keychain access groups: #{path}") unless groups.nil? || groups.is_a?(Array)
  [config, relative_path, path, plist]
end

manifest_path = "android/app/src/main/AndroidManifest.xml"
manifest = File.read(manifest_path)
application = manifest[/<application\b[^>]*>/m]
abort("Android application element not found") unless application
updated = if application.match?(/android:allowBackup="[^"]*"/)
  application.sub(/android:allowBackup="[^"]*"/, 'android:allowBackup="false"')
else
  application.sub("<application", "<application\n        android:allowBackup=\"false\"")
end
File.write(manifest_path, manifest.sub(application, updated))

entries.each do |config, relative_path, path, plist|
  plist["keychain-access-groups"] ||= []
  FileUtils.mkdir_p(File.dirname(path))
  Xcodeproj::Plist.write_to_path(plist, path)
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = relative_path
end
project.save
puts "Configured Android backup handling and Keychain entries; existing entitlement paths and capabilities preserved."
