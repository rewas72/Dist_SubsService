
require 'open3'  
require 'timeout'  
require 'socket'


class Message
  attr_accessor :demand, :response

  def initialize(demand, response)
    @demand = demand
    @response = response
  end

  def to_s
    "Demand: #{@demand}, Response: #{@response}"
  end
end

class Capacity
  attr_accessor :server_status, :timestamp

  def initialize(server_status, timestamp)
    @server_status = server_status
    @timestamp = timestamp
  end

  def to_s
    "Server Status: #{@server_status}, Timestamp: #{@timestamp}"
  end
end


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

def request_response(server, port, message)
  
  begin
    socket = TCPSocket.new(server, port)
    socket.puts("#{message.demand},#{message.response}")
    response = socket.gets
    return response ? Message.new(*response.strip.split(',')) : nil
  rescue => e 
    puts "Hata: #{e.message}"
    return nil
  ensure
    socket.close if socket
  end
end

def parse_response(response)
  server_status, timestamp = response.strip.split(',')
  [server_status.to_i, timestamp.to_i]
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


servers = {'Server1'=> 5000 , 'Server2'=> 5001 , 'Server3'=> 5002}
responses = {}

servers.each do |server, port|
  message = Message.new("STRT", nil)
  response = request_response(server, port, message)
  responses[server] = response if response&.response == "YEP"
end

loop do
  responses.each do |server, _|
    capacity_message = Message.new("CPCTY", nil)
    response = request_response(server, servers[server], capacity_message)

    if response
      server_status, timestamp = parse_response(response.to_s)
      capacity = Capacity.new(server_status, timestamp)
      puts "#{server}'in kapasite durumu: #{capacity.to_s}"
    else
      puts "#{server}'in kapasitesi için yanıt alınamadı."
    end
  end
  sleep(5)
end
