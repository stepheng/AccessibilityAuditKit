#!/usr/bin/env ruby
# Regenerates AccessibilityFixtures.xcodeproj from the sources on disk.
# Re-run after adding/removing any .swift file. Safe to run repeatedly.
# Files under AccessibilityFixtures/Catalog/ are compiled into BOTH targets.
require 'xcodeproj'

ROOT       = File.expand_path(File.dirname(__FILE__))   # the AccessibilityFixtures/ dir
PROJECT    = File.join(ROOT, 'AccessibilityFixtures.xcodeproj')
APP_DIR    = 'AccessibilityFixtures'                     # relative to ROOT
TEST_DIR   = 'AccessibilityFixturesUITests'
PKG_REL    = '../AccessibilityAuditReport'
TEAM       = '3TY8Z73V2D'

Dir.chdir(ROOT)
project = Xcodeproj::Project.new(PROJECT)

app    = project.new_target(:application,     'AccessibilityFixtures',        :ios, '17.0')
uitest = project.new_target(:ui_test_bundle,  'AccessibilityFixturesUITests', :ios, '17.0')

app.build_configurations.each do |c|
  c.build_settings['GENERATE_INFOPLIST_FILE']   = 'YES'
  c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.synchonross.capsylspike.AccessibilityFixtures'
  c.build_settings['DEVELOPMENT_TEAM']          = TEAM
  c.build_settings['SWIFT_VERSION']             = '5.0'
  c.build_settings['MARKETING_VERSION']         = '1.0'
  c.build_settings['CURRENT_PROJECT_VERSION']   = '1'
  c.build_settings['TARGETED_DEVICE_FAMILY']    = '1,2'
  # Support all three usable orientations at the plist level; the AppDelegate
  # narrows to portrait only when launched with -lockOrientation portrait.
  c.build_settings['INFOPLIST_KEY_UISupportedInterfaceOrientations'] =
    'UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight'
end

uitest.build_configurations.each do |c|
  c.build_settings['GENERATE_INFOPLIST_FILE']   = 'YES'
  c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.synchonross.capsylspike.AccessibilityFixturesUITests'
  c.build_settings['DEVELOPMENT_TEAM']          = TEAM
  c.build_settings['SWIFT_VERSION']             = '5.0'
  c.build_settings['TEST_TARGET_NAME']          = 'AccessibilityFixtures'
end

uitest.add_dependency(app)

# Local Swift package, linked into the UITEST target only (the app is package-free).
pkg = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
pkg.relative_path = PKG_REL
project.root_object.package_references << pkg
['AccessibilityAuditReport', 'AccessibilityAuditXCTestSupport'].each do |product|
  dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  dep.package = pkg
  dep.product_name = product
  uitest.package_product_dependencies << dep
  bf = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = dep
  uitest.frameworks_build_phase.files << bf
end

def add(project, target, rel)
  ref = project.new_file(rel)
  target.source_build_phase.add_file_reference(ref)
  ref
end

# App sources -> app target. Anything under Catalog/ ALSO -> uitest target.
Dir.glob("#{APP_DIR}/**/*.swift").sort.each do |path|
  ref = add(project, app, path)
  uitest.source_build_phase.add_file_reference(ref) if path.include?("/Catalog/")
end
# Test sources -> uitest target.
Dir.glob("#{TEST_DIR}/**/*.swift").sort.each { |path| add(project, uitest, path) }

project.save

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.add_test_target(uitest)
scheme.set_launch_target(app)
scheme.save_as(PROJECT, 'AccessibilityFixtures', true)   # shared scheme

puts "Generated #{PROJECT}"
