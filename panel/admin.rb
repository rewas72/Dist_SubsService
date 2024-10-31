
require 'open3'  # 'open3' modülünü dahil eder; bu modül ile komut satırı işlemleri yapabiliriz
require 'timeout'  # Zaman aşımı için modülü ekliyoruz

# Configuration sınıfı tanımlanıyor
class Configuration
  attr_accessor :fault_tolerance_level, :method  # Bu iki özellik dışarıdan erişilebilir ve değiştirilebilir

  def initialize(fault_tolerance_level)  # Yapıcı metod (constructor) tanımlanıyor; fault_tolerance_level parametresi alır
    @fault_tolerance_level = fault_tolerance_level  # Gelen fault_tolerance_level parametresi sınıfın örnek değişkenine atanır
    @method = 'STRT'  # method değişkenine "STRT" değeri atanır; bu sunuculara gönderilecek başlangıç komutudur
  end
end

# dist_subs.conf dosyasını okuyan fonksiyon tanımlanıyor
def read_config(file_path)
  fault_tolerance_level = nil  # fault_tolerance_level değişkeni başta boş olarak tanımlanır
  
  # Dosyanın her satırını okur
  File.foreach(file_path) do |line|
    # Eğer satır "fault_tolerance_level = X" desenine uyuyorsa
    if line =~ /fault_tolerance_level\s*=\s*(\d+)/
      fault_tolerance_level = $1.to_i  # Sayı kısmını alır ve fault_tolerance_level değişkenine tam sayı olarak atar
    end
  end
  fault_tolerance_level  # Bu değeri geri döndürür
end

# Belirtilen sunucu betiğini başlatan fonksiyon
def start_server(server_script, config)
  # Sunucu başlatma komutunu oluşturur
  command = "python C:/Users/Revas/Desktop/Dist_SubsService-main/dist_servers/#{server_script} #{config.method}"

  begin
    Timeout.timeout(10) do  # 10 saniyelik bir zaman aşımı belirliyoruz
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
  
  # Komutu çalıştırır ve çıktısını alır
  Open3.popen3(command) do |_stdin, _stdout, stderr, wait_thr|
    exit_status = wait_thr.value  # Komutun çıkış durumunu kontrol eder
    
    # Eğer komut başarıyla çalıştıysa, sunucu başlatıldı mesajı yazdırır
    if exit_status.success?
      puts "#{server_script} başarıyla başlatıldı."
    else
      # Başarısız olduysa, hata mesajını stderr'den alır ve yazdırır
      puts "#{server_script} başlatılamadı: #{stderr.read}"
    end
  end
end

# dist_subs.conf dosyasını okur ve Configuration nesnesini oluşturur
config_file = 'dist_subs.conf'  # Konfigürasyon dosyasının adı
fault_tolerance_level = read_config(config_file)  # Dosyadan fault_tolerance_level değerini okur

# Eğer bir fault_tolerance_level değeri mevcutsa, Configuration nesnesi oluşturulur
if fault_tolerance_level
  config = Configuration.new(fault_tolerance_level)  # Configuration sınıfından bir nesne oluşturulur
  
  # Her bir sunucuyu başlatma komutu gönderilir
  %w[Server1.py Server2.py Server3.py].each do |server_script|
    start_server(server_script, config)  # Sunucu başlatılır
  end
else
  puts "Hata: fault_tolerance_level bulunamadı."  # Eğer dosyada fault_tolerance_level bulunmazsa hata mesajı yazdırır
end
