require 'xcodeproj'
require 'fileutils'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

lockedin_group = project.main_group.groups.find { |g| g.name == 'LockedIn' || g.path == 'LockedIn' }
shared_group = lockedin_group.groups.find { |g| g.name == 'Shared' } || lockedin_group.new_group('Shared', 'Shared')
shared_ui_group = shared_group.groups.find { |g| g.name == 'UI' } || shared_group.new_group('UI', 'UI')
shared_domain_group = shared_group.groups.find { |g| g.name == 'Domain' } || shared_group.new_group('Domain', 'Domain')
shared_data_group = shared_group.groups.find { |g| g.name == 'Data' } || shared_group.new_group('Data', 'Data')
shared_services_group = shared_group.groups.find { |g| g.name == 'Services' } || shared_group.new_group('Services', 'Services')
app_group = lockedin_group.groups.find { |g| g.name == 'App' || g.path == 'App' } || lockedin_group.new_group('App', 'App')
features_group = lockedin_group.groups.find { |g| g.name == 'Features' || g.path == 'Features' } || lockedin_group.new_group('Features', 'Features')
appshell_group = features_group.groups.find { |g| g.name == 'AppShell' || g.path == 'AppShell' } || features_group.new_group('AppShell', 'AppShell')

def all_files(group)
  group.files + group.groups.flat_map { |g| all_files(g) }
end

$all_project_files = all_files(project.main_group)

def move_file(project, file_name, dest_group, dest_physical_dir)
  file_ref = $all_project_files.find { |f| f.name == file_name || (f.path && f.path.end_with?(file_name)) || (f.real_path.to_s.end_with?(file_name) rescue false) }
  
  if file_ref
    old_path = file_ref.real_path.to_s
    new_path = File.expand_path(File.join("LockedIn", dest_physical_dir, file_name))
    
    if old_path != new_path
      if File.exist?(old_path)
        FileUtils.mkdir_p(File.dirname(new_path))
        FileUtils.mv(old_path, new_path)
        puts "Moved #{file_name} physically"
      else
        puts "Physical file not found (might already be moved): #{old_path}"
      end
    end
    
    file_ref.move(dest_group)
    file_ref.set_path(file_name)
    file_ref.source_tree = '<group>'
    puts "Moved #{file_name} to #{dest_group.name} in Xcode"
  else
    puts "Warning: #{file_name} not found in Xcode project!"
  end
end

move_file(project, 'LiquidGlassNavBar.swift', shared_ui_group, 'Shared/UI')
move_file(project, 'FitnessLiquidGlassNavStyle.swift', shared_ui_group, 'Shared/UI')
move_file(project, 'DateRules.swift', shared_domain_group, 'Shared/Domain')
move_file(project, 'NonNegotiableMode.swift', shared_domain_group, 'Shared/Domain')
move_file(project, 'NonNegotiableState.swift', shared_domain_group, 'Shared/Domain')
move_file(project, 'CompletionRecord.swift', shared_domain_group, 'Shared/Domain')
move_file(project, 'NonNegotiable.swift', shared_domain_group, 'Shared/Domain')
move_file(project, 'AppRouter.swift', appshell_group, 'Features/AppShell')

project.save
puts "Project saved."
