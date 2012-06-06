VERSION_NUMBER = "0.0.0"
GROUP = "Splat"

LINUX = RbConfig::CONFIG['host_os'] =~  /linux|cygwin/
WINDOWS = RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
MAC = RbConfig::CONFIG['host_os'] =~ /mac|darwin/

java_layout = Layout.new
java_layout[:source, :main] = 'src'
java_layout[:target, :main] = 'target'

repositories.remote << "http://repo1.maven.org/maven2/"

desc "Splat Text Editor"
define "Splat", :layout=>java_layout do

  TAR_INCLUDE = _("target/resources/*"),  _("target/classes/plugins"), "COPYING", "README", compile.classpath
  JAR_EXCLUDE = _("target/resources/*"), "plugins"

  if LINUX
     Dir[_(:src, :dep, :linux, '*')].each do |file|
       compile.with file
     end
     LIBRARY = _(:src, :dep, :linux)
  elsif WINDOWS
     Dir[_(:src, :dep, :win32, '*')].each do |file|
       compile.with file
     end
     LIBRARY = _(:src, :dep, :win32)
  elsif MAC
     Dir[_(:src, :dep, :macosx, '*')].each do |file|
       compile.with file
     end
     LIBRARY = _(:src, :dep, :macosx)
  end
  Dir[_(:src, :dep, :all, '*')].each do |file|
    compile.with file
  end

  manifest['Main-Class'] = 'com.digitaltea.splat.Splat'
  manifest['Class-Path'] = compile.classpath.map {|dep| File.basename(dep) }.join(":")

  run.using :main => "com.digitaltea.splat.Splat",
            :java_args => ["-Djava.library.path=#{LIBRARY}"]

  project.version = VERSION_NUMBER
  project.group = GROUP

  package(:tgz).include(package(:jar).exclude(JAR_EXCLUDE), TAR_INCLUDE)

  task :compile do
    chdir(_(:target, :main, :classes)){
      mkdir_p "plugins"
      Dir["com/digitaltea/splat/plugins/*"].each do |file|
        if File.directory?(file)
          system "jar cf #{_(:target, :main, :classes)}/plugins/#{File.basename(file)}.jar #{file}"
          rm_r file
        end
      end
      system "jar cf plugins/CorePlugin.jar com/digitaltea/splat/core"
    }
  end

  task :copy do
    system "cp -rf * /opt/Splat-run"
  end
end


