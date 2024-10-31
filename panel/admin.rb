
require 'open3'  
require 'timeout'  


class Configuration
  attr_accessor :fault_tolerance_level, :method  

  def initialize(fault_tolerance_level)  
    @fault_tolerance_level = fault_tolerance_level 
    @method = 'STRT'  
  end
end


def read_config(file_path)
  fault_tolerance_level = nil  
  
 
  File.foreach(file_path) do |line|
    
    if line =~ /fault_tolerance_level\s*=\s*(\d+)/
      fault_tolerance_level = $1.to_i  
    end
  end
  fault_tolerance_level  
end


def start_server(server_script, config)
  
  command = "python C:/Users/Merve/Dist_SubsService/dist_servers/#{server_script} #{config.method}"

  begin
    Timeout.timeout(10) do  
      Open3.popen3(command) do |_stdin, _stdout, stderr, wait_thr|
        exit_status = wait_thr.value
        if exit_status.success?
          puts "#{server_script} başarıyla başlatıldı."
        else
          puts "#{server_script} başlatılamadı: #{stderr.read}"
        end
      end
    end
  rescue Timeout::Error
    puts "#{server_script} başlatılamadı: Komut zaman aşımına uğradı."
  end
  
  
  Open3.popen3(command) do |_stdin, _stdout, stderr, wait_thr|
    exit_status = wait_thr.value 
    
    
    if exit_status.success?
      puts "#{server_script} başarıyla başlatıldı."
    else
      
      puts "#{server_script} başlatılamadı: #{stderr.read}"
    end
  end
end


config_file = 'dist_subs.conf'  
fault_tolerance_level = read_config(config_file)  

if fault_tolerance_level
  config = Configuration.new(fault_tolerance_level)  
  
  %w[Server1.py Server2.py Server3.py].each do |server_script|
    start_server(server_script, config)  
  end
else
  puts "Hata: fault_tolerance_level bulunamadı."  
end
