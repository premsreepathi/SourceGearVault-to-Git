require 'thread'
require 'nokogiri'
require 'fileutils'
require 'time'
require 'log4r'
require 'pp'
require 'enumerator'


GITIGNORE = <<-EOF
[Oo]bj/
[Bb]in/
*.suo
*.user
*.vspscc
*.vssscc
*.tmp
*.log
EOF

class Converter

  # Configure logging
  include Log4r
  
  $logger = Logger.new('vault2git')
  stdout_log = StdoutOutputter.new('console')
  stdout_log.level = INFO
  file_log = FileOutputter.new('file', :filename => $options.logfile, :trunc => true)
  file_log.level = DEBUG
  $logger.add(stdout_log, file_log)
  %w(debug info warn error fatal).map(&:to_sym).each do |level|
    (class << self; self; end).instance_eval do
      define_method level do |msg|
        $logger.send level, msg
      end
    end
  end

  debug $options.inspect

  def self.quote_param(param)
    value = $options.send(param)
    quote_value value
  end

  def self.quote_value(value)
    return '' unless value
    value.include?(' ') ? '"' + value + '"' : value
  end
  eclient=$options.vault_client.gsub(/\//, '\\')
  puts"Source Gear Vault remove user login's"
  system("\"#{eclient}\" FORGETLOGIN > nul 2>&1")

  def self.vault_command(command, options = [], args = [], append_source_folder = true)
    parts = []
    parts << quote_param(:vault_client)
    parts << command
    %w(host username password repository).each{|param| parts << "-#{param} #{quote_param(param)}"}
    [*options].each{|param| parts << param}
    parts << quote_param(:source) if append_source_folder
    [*args].each{|param| parts << quote_value(param)}
    cmd = parts.join(' ')
    debug "Invoking vault: #{cmd}"
    retryable do
      begin
        xml = `#{cmd}`
        doc = Nokogiri::XML(xml) do |config|
          config.strict.noblanks
        end
        raise "Unsuccessful command '#{command}': #{(doc % :error).text}" if (doc % :result)[:success] == 'no'
        doc
      rescue Exception => e
        raise #"Error processing command '#{cmd}'", e
      end
    end
  end

  def self.git_command(command, *options)
    parts = []
    parts << quote_param(:git)
    parts << command
    [*options].each{|param| parts << param}
    cmd = parts.join(' ')
    debug "Invoking git: #{cmd}"
    begin
      debug output = retryable{`#{cmd}`}
    rescue Exception => e
      raise "Error processing command '#{command}'", e
    end
  end

  def self.git_commit(comments, *options)
    git_command 'add', '--all', '.'
    params = [*comments].map{|c| "-m \"#{c}\""} << options << "-a"
    git_command 'commit', *(params.flatten)
  end

  def self.retryable(max_times = 5, &block)
    tries = 0
    begin
    yield block
    rescue
    tries += 1
    if tries <= max_times
      warn "Retrying command, take #{tries} of #{max_times}"
      retry
    end
    error "Giving up retrying"
    raise
    end
  end


  def self.clear_working_folder
    Dir.chdir($options.dest)
    path=Dir.pwd()
    puts "Current working directory is: #{path}"
    files = Dir.entries(path)
    puts "before deleted directory #{files}"
    if Dir.exist? (path+'/.git')    
       FileUtils.mv(path+'/.git',path+'/../.git_bkp')       
       FileUtils.remove_dir(path,true)
       FileUtils.mkdir_p path
       files = Dir.entries(path)
       puts "after deleted directory #{files}"
       FileUtils.mv(path+'/../.git_bkp', path+'/.git')
     else
       puts "can not find source file to move"
    end

    files = Dir.entries(path)
    puts "after git directory #{files}"
  end

  def self.convert
    start = Time.now
    info "Starting at #{Time.now}"
    debug "Parameters: " + $options.inspect
    authors = get_authors()
    info "Prepare destination folder"
    FileUtils.rm_rf $options.dest
    git_command 'init', quote_value($options.dest)
    Dir.chdir $options.dest
    File.open(".gitignore", 'w') {|f| f.write(GITIGNORE)}
    git_commit 'Starting Vault repository import'

    info "Set Vault working folder"
    vault_command 'setworkingfolder', quote_value($options.source), $options.dest, false
    info "Fetch version history"
    cfilepath=$options.cfilepath
    puts "************current path is: #{cfilepath}"
    eclient=$options.vault_client.gsub(/\//, '\\')
    epath=cfilepath.gsub(/\//, '\\')
    efilename=$options.source.gsub(/[[:space:]]/, '').tr('$', '').gsub(/\/|\\/,"").tr('"', '')   
    efile="#{epath}\\#{efilename}.xml"
    puts "#{eclient}****#{epath}****#{efile}"
    hfile="#{epath}\\#{efilename}_history.xml"
    
    system("\"#{eclient}\" versionhistory -host #{$options.host} -user #{$options.username} -password #{$options.password} -rowlimit 0 -beginversion 0 -repository \"#{$options.repository}\" \"#{$options.source}\" > \"#{efile}\" 2>&1")
    system("\"#{eclient}\" history -host #{$options.host} -user #{$options.username} -password #{$options.password} -rowlimit 0 -beginversion 0 -repository \"#{$options.repository}\" \"#{$options.source}\" > \"#{hfile}\" 2>&1")
    puts "*********file writing is done*****"    
    

    history = File.open("#{hfile}")
    parsed_inf = Nokogiri::XML(history)
    hversions = parsed_inf.xpath('//history/item')

    sample_data = File.open("#{efile}")
    parsed_info = Nokogiri::XML(sample_data)
    versions = parsed_info.xpath('//history/item')


      
    maindir="#{$options.dest}/main"
     
     if Dir.exist? ("#{$options.dest}/main")    
       puts "#{maindir} directory is already created"
     else
      FileUtils.mkdir_p maindir
      puts "************#{maindir}"
      Dir.chdir("#{maindir}")
      path=Dir.pwd()

      system("git init")

      puts "after git init #{maindir}"
     end
     info "start time : #{Time.now}"

  slicelimit = 30
versions.sort_by {|v| v[:version].to_i}.each_slice(slicelimit) do |versions|
    
    count = 0
    sleep(1)
      
$results = []
   def do_stuff(opts={})
     'done'
   end

   def self.thread_wait(threads)
     threads.each{|t| t.join}
     threads.each {|t| $results << t }
     threads.delete_if {|t| t.status == false}
     threads.delete_if {|t| t.status.nil? }
   end
   
   opts = {}
   thread_limit = slicelimit
   threads = []
   versions.sort_by {|v| v[:version].to_i}.each_with_index do |version, i|
     thread_wait(threads) while threads.length >= thread_limit
     t = Thread.new { 
      count += 1
      sleep(1)
      info "Processing version #{count} of #{versions.size}"
      puts"********version number:#{version[:version]}******"
      fileslis = Dir.entries($options.dest)
      getvfiles="#{$options.dest}/#{version[:version]}"
      FileUtils.mkdir_p getvfiles
      #clear_working_folder
      vault_command 'getversion', ["-backup no", "-merge overwrite", "-setfiletime checkin", "-performdeletions removeworkingcopy", version[:version]], getvfiles
}
     sleep(1)
     t.abort_on_exception = true
     threads << t
   end
   # ensure remaining threads complete
   threads.each{|t| t.join}    

     maindir="#{$options.dest}/main"
    versions.sort_by {|v| v[:version].to_i}.each_with_index do |version, i|
     puts"********copy section version number:#{version[:version]}******"
     getvfiles="#{$options.dest}/#{version[:version]}"
    sleep(2)
    puts "Current working directory is: #{maindir}"
    files = Dir.entries(maindir)
    puts "before deleted directory #{maindir}"

if Dir.empty?("#{getvfiles}")
   puts "*****#{version[:version]} version empty try1 ***"
   fileslis = Dir.entries($options.dest)
   getvfiles="#{$options.dest}/#{version[:version]}"
   vault_command 'getversion', ["-backup no", "-merge overwrite", "-setfiletime checkin", "-performdeletions removeworkingcopy", version[:version]], getvfiles
end

if Dir.empty?("#{getvfiles}")
 puts "*****#{version[:version]} version dir is empty ***"
else

    if Dir.exist? (path+'/.git')    
       FileUtils.mv(path+'/.git',path+'/../.git_bkp')       
       Dir.chdir($options.dest)
       puts "after deleted directory #{maindir}"
       system("rmdir /q /s \"#{maindir}\"")
       sleep(1)  
       system("move \"#{getvfiles}\" \"#{maindir}\"")
       sleep(1) 

       FileUtils.mv(maindir+'/../.git_bkp', path+'/.git')
       Dir.chdir(maindir)
       files = Dir.entries(maindir)
       puts "after moving version to main directory #{maindir}"
     else
       puts "can not find source file to move"
    end
     sleep(2)

    
     
     vcommitmsg = "#{version[:comment]}"
     puts "********************commit message**#{vcommitmsg}****"
     vtxid="#{version[:txid]}"
     if "#{vcommitmsg}" == "" || "#{vcommitmsg}" == nil || "#{vcommitmsg}" == " "
        puts "***empty commit message**"
        hlist = []
        hversions.sort_by {|v| v[:hversion].to_i}.each_with_index do |hversion, i|
          htxid="#{hversion[:txid]}"
          if vtxid == htxid
           hlist.append("#{hversion[:actionString]}")

          end          
        end
        puts "print list #{hlist}"        

          comments ="#{hlist.join(" ")} by #{version[:user]} (txid=#{version[:txid]})"
          finalcomments="#{comments.gsub("\"", "")}"

          puts "********comments***#{finalcomments.strip}****"
          comitdate="#{Time.parse(version[:date]).strftime('%Y-%m-%dT%H:%M:%S')}" 
          authname="#{version[:user]}<#{version[:user]}@opentext.com>"
          system("git add .")
          system("git commit -m \"#{finalcomments.strip}\" --date=\"#{comitdate}\" --author=\"#{authname}\"")       

     else
        comments ="#{(version[:comment])} by #{version[:user]} (txid=#{version[:txid]})"
        finalcomments="#{comments.gsub("\"", "")}"
        puts "********comments***#{finalcomments}****"
        comitdate="#{Time.parse(version[:date]).strftime('%Y-%m-%dT%H:%M:%S')}" 
        authname="#{version[:user]}<#{version[:user]}@opentext.com>"
        system("git add .")
        system("git commit -m \"#{finalcomments}\" --date=\"#{comitdate}\" --author=\"#{authname}\"")
     
     end
         # Add tag to commit if specified
     hversions.sort_by {|v| v[:hversion].to_i}.each_with_index do |hversion, i|
      type="#{hversion[:typeName]}"
      tagversion="#{hversion[:version]}"
      dversion="#{version[:version]}"
      labelna="#{hversion[:actionString]}"
      labelname=labelna.gsub(/[[:space:]]/, '_')
      
      if "#{type}" == "Label" && tagversion == dversion
        puts "**********label********#{labelname}"
        system("git tag -a \"#{labelname}\"  -m \"vault #{version[:actionString]}\"")
      end
     end
      #git_command 'gc' 
     system("\"#{eclient}\" FORGETLOGIN > nul 2>&1")
     info "version completed time : #{Time.now}"
     sleep(1)
    end
end
    finish = Time.now
    diff = finish - start
    puts "***************Total execution time #{diff}"
    info "Ended at #{Time.now}"
    vault_command 'FORGETLOGIN'
    system("\"#{eclient}\" FORGETLOGIN > nul 2>&1")
  end
  end

  AUTHORS_FILE = "authors.xml"
  def self.get_authors
    authors = Hash.new()

    if File.exists? AUTHORS_FILE then
      info "Reading authors file"
      doc = Nokogiri::XML(File.open(AUTHORS_FILE))
      doc.children.each do |item|
        authors[item[:vaultname]] = "#{item[:name]} <#{item[:email]}>"
        
      end
    end

    authors

  end

end
