#!/usr/bin/env ruby
require "xcodeproj"
require "json"
ROOT = File.expand_path("..", __dir__)
NAME = "QRReader"
project = Xcodeproj::Project.open(File.join(ROOT, "#{NAME}.xcodeproj"))
app = project.targets.find { |target| target.name == NAME } or abort "Missing app target"
pins = JSON.parse(File.read(File.join(__dir__, "Package.resolved"))).fetch("pins")
products = {
  "quantumleap" => %w[QuantumLeap],
  "firebase-ios-sdk" => %w[FirebaseCore FirebaseAnalytics FirebaseAppCheck FirebaseMessaging FirebasePerformance],
  "codescanner" => %w[CodeScanner],
  "licenselist" => %w[LicenseList],
  "swiftui-introspect" => %w[SwiftUIIntrospect]
}
# Keep the restored target IDs and synchronized groups; current filenames are
# automatically members of their corresponding app/unit/UI source folders.
products.each do |identity, names|
  pin = pins.find { |entry| entry.fetch("identity") == identity } or abort "Missing pin: #{identity}"
  package = project.root_object.package_references.find { |entry| entry.repositoryURL == pin.fetch("location") }
  package ||= project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
  package.repositoryURL = pin.fetch("location")
  # Pin the published 0.0.8 code by revision; its tag has a conflicting cached fingerprint.
  package.requirement = if identity == "quantumleap"
    { "kind" => "revision", "revision" => pin.fetch("state").fetch("revision") }
  else
    { "kind" => "exactVersion", "version" => pin.fetch("state").fetch("version") }
  end
  project.root_object.package_references << package unless project.root_object.package_references.include?(package)
  names.each do |name|
    product = app.package_product_dependencies.find { |entry| entry.product_name == name }
    product ||= project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
    product.package = package
    product.product_name = name
    app.package_product_dependencies << product unless app.package_product_dependencies.include?(product)
    unless app.frameworks_build_phase.files.any? { |build| build.product_ref == product }
      build = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build.product_ref = product
      app.frameworks_build_phase.files << build
    end
  end
end
(project.build_configurations + project.targets.flat_map(&:build_configurations)).each do |config|
  config.build_settings["DEVELOPMENT_TEAM"] = "5Q94QJ7G98"
  config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "16.0"
end
app.build_configurations.each do |config|
  config.build_settings["MARKETING_VERSION"] = "1.0.3"
  config.build_settings["CODE_SIGN_ENTITLEMENTS"] = "QRReader/QRReader.entitlements"
  config.build_settings["OTHER_LDFLAGS"] = "$(inherited) -ObjC"
end
project.targets.each do |target|
  next if target == app
  target.build_configurations.each do |config|
    config.build_settings["TEST_TARGET_NAME"] = NAME if target.product_type.end_with?("ui-testing")
  end
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
project.targets.reject { |target| target == app }.each { |target| scheme.add_test_target(target) }
scheme.save_as(project.path, NAME, true)
require "fileutils"
lock = File.join(project.path, "project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
FileUtils.mkdir_p(File.dirname(lock))
FileUtils.cp(File.join(__dir__, "Package.resolved"), lock)
puts "Reconciled restored #{NAME} target IDs, imports, settings and testables"
