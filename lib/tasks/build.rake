require 'rake/packagetask'

BUILD_DIR = "release"
QUIET = {verbose: false}

task :source => BUILD_DIR
directory BUILD_DIR

version = `git rev-parse --short HEAD 2>/dev/null | tr -d "\n"`

Rake::PackageTask.new(:fiat, version) do |p|
  p.need_tar_gz = true
  p.package_dir = BUILD_DIR

  task :source => p.package_dir_path

  desc "Copy source files"
  task :source, [BUILD_DIR] do |t, args|
    cp Dir['*.rb'],"#{p.package_dir_path}" 
    cp_r ['app', 'bin', 'config', 'db', 'lib', 'public', 'service', 'util', 'Rakefile', 'Gemfile', 'Gemfile.lock',  'config.ru', 'grab.sh'], "#{p.package_dir_path}"
    mkdir_p "#{p.package_dir_path}/vendor"
    File.write("#{p.package_dir_path}/version", version)
  end

  task :rm_dir do
    rm_r "#{p.package_dir_path}" if File.exist?("#{p.package_dir_path}")
    rm   "#{p.package_dir_path}.tar.gz" if File.exist?("#{p.package_dir_path}.tar.gz")
  end

  task :package => [:rm_dir, :source]
end


task :build => 'package' 

