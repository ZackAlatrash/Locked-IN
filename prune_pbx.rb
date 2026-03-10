require 'xcodeproj'
project_path = 'LockedIn.xcodeproj'
project = Xcodeproj::Project.open(project_path)

puts "Cleaning missing files from build phases..."

project.targets.each do |target|
  target.source_build_phase.files.to_a.each do |build_file|
    file_ref = build_file.file_ref
    if file_ref
      begin
        path = file_ref.real_path
        unless File.exist?(path)
          puts "Removing missing file reference: #{file_ref.path || file_ref.name}"
          build_file.remove_from_project
          file_ref.remove_from_project
        end
      rescue => e
        puts "Error checking path for #{file_ref.name}: #{e.message}"
        build_file.remove_from_project
        file_ref.remove_from_project
      end
    else
      puts "Removing orphaned build file"
      build_file.remove_from_project
    end
  end
end

project.save
puts "Clean complete."
