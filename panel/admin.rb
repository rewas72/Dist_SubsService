require 'socket'
require 'open3'

def read_config(file_path)
  fault_tolerance_level = nil
  File.foreach(file_path) do |line|
    if line =~ /fault_tolerance_level\s*=\s*(\d+)/
      fault_tolerance_level = $1.to_i
    end
  end
  fault_tolerance_level
end

def start_server(server_script)
  if File.exist?("#{server_script}.class")
    command = "java #{server_script}"
    Open3.popen3(command) do |_stdin, _stdout, stderr, wait_thr|
      if wait_thr.value.success?
        puts "#{server_script} başarıyla başlatıldı."
      else
        puts "#{server_script} başlatılamadı: #{stderr.read}"
      end
    end
  else
    puts "#{server_script}.class bulunamadı. Lütfen derlediğinizden emin olun."
  end
end

def send_request(host, port, demand)
  begin
    socket = TCPSocket.new(host, port)
    socket.puts(demand)
    response = socket.gets
    response
  rescue => e
    puts "Hata: #{e.message}"
    nil
  ensure
    socket.close if socket
  end
end

def send_to_plotter(host, port, message)
  begin
    socket = TCPSocket.new(host, port)
    socket.puts(message)
    puts "Plotter'a gönderilen mesaj: #{message}"
  rescue => e
    puts "Plotter'a mesaj gönderme hatası: #{e.message}"
  ensure
    socket.close if socket
  end
end

config_file = 'dist_subs.conf'
fault_tolerance_level = read_config(config_file)

if fault_tolerance_level
  puts "Fault Tolerance Level: #{fault_tolerance_level}"
  %w[Server1 Server2 Server3].each { |server| start_server(server) }
else
  puts "Config dosyası bulunamadı veya geçersiz."
end

servers = { 'Server1' => 5000, 'Server2' => 5001, 'Server3' => 5002 }
plotter_host = 'localhost'
plotter_port = 6000

loop do
  servers.each do |name, port|
    response = send_request('localhost', port, 'CPCTY')
    if response
      message = "#{name},#{response.strip},timestamp:#{Time.now.to_i}"
      send_to_plotter(plotter_host, plotter_port, message)
    else
      puts "#{name} yanıt vermedi."
    end
  end
  sleep(5)
end