require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

all_files = project.main_group.recursive_children.select { |c| c.isa == 'PBXFileReference' }
wrapper_ref = all_files.find { |f| f.path && f.path.end_with?('LegacyCommitmentWrapper.swift') }

if wrapper_ref
  wrapper_ref.remove_from_project
  project.save
  puts "Removed LegacyCommitmentWrapper.swift from Xcode project"
else
  puts "Could not find LegacyCommitmentWrapper in project."
end
