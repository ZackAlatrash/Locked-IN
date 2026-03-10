require 'xcodeproj'

project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

all_files = project.main_group.recursive_children.select { |c| c.isa == 'PBXFileReference' }
commit_ref = all_files.find { |f| f.path && f.path.end_with?('RepositoryCommitmentService.swift') }

if commit_ref
  # Reset the path to just the filename if the group has the path configured
  commit_ref.set_path('RepositoryCommitmentService.swift')
  project.save
  puts "Fixed Xcode project file path reference for RepositoryCommitmentService."
else
  puts "Could not find RepositoryCommitmentService in project."
end
