require 'socket'
require 'open3'

# 1. Config dosyasını oku
def read_config(file_path)
  fault_tolerance_level = nil
  File.foreach(file_path) do |line|
    if line =~ /fault_tolerance_level\s*=\s*(\d+)/  # Config dosyasından tolerans seviyesini oku
      fault_tolerance_level = $1.to_i
    end
  end
  fault_tolerance_level
end

# 2. Sunucuları başlat
def start_server(server_script)
  command = "java #{server_script}"
  Open3.popen3(command) do |_stdin, _stdout, stderr, wait_thr|
    if wait_thr.value.success?
      puts "#{server_script} başarıyla başlatıldı."
    else
      puts "#{server_script} başlatılamadı: #{stderr.read}"
    end
  end
end

# 3. Kapasite sorgula
def send_request(host, port, demand)
  begin
    socket = TCPSocket.new(host, port) # Sunucuya bağlan
    socket.puts(demand)               # İstek gönder
    response = socket.gets           # Yanıtı oku
    response
  rescue => e
    puts "Hata: #{e.message}"
    nil
  ensure
    socket.close if socket
  end
end

# 4. Plotter'a mesaj gönder
def send_to_plotter(host, port, message)
  begin
    socket = TCPSocket.new(host, port) # Plotter sunucusuna bağlan
    socket.puts(message)               # Mesajı gönder
    puts "Plotter'a gönderilen mesaj: #{message}"
  rescue => e
    puts "Plotter'a mesaj gönderme hatası: #{e.message}"
  ensure
    socket.close if socket
  end
end

# 5. Config dosyasını yükle ve sunucuları başlat
config_file = 'dist_subs.conf'
fault_tolerance_level = read_config(config_file)

if fault_tolerance_level
  puts "Fault Tolerance Level: #{fault_tolerance_level}"
  %w[Server1 Server2 Server3].each { |server| start_server(server) }
else
  puts "Config dosyası bulunamadı veya geçersiz."
end

# 6. YEP yanıtı alan sunuculara kapasite sorgusu ve Plotter'a gönderim
servers = { 'Server1' => 5000, 'Server2' => 5001, 'Server3' => 5002 }
plotter_host = 'localhost' # Plotter sunucusu
plotter_port = 6000        # Plotter'ın dinlediği port

loop do
  servers.each do |name, port|
    response = send_request('localhost', port, 'CPCTY') # Sunucudan kapasite isteği gönder
    if response
      # Plotter'a sunucu kapasitesini ve zaman bilgisiyle gönder
      message = "#{name},#{response.strip}" # Sunucu adını ve yanıtı birleştir
      send_to_plotter(plotter_host, plotter_port, message)
    else
      puts "#{name} yanıt vermedi."
    end
  end
  sleep(5) # 5 saniye bekle
end
