import socket
import matplotlib.pyplot as plt
from datetime import datetime

# Server bilgileri
HOST = "localhost"
PORT = 6000

# Verileri tutmak için listeler
server_data = {"Server1": [], "Server2": [], "Server3": []}
timestamps = []

# Socket sunucusunu başlat
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((HOST, PORT))
    s.listen()
    print(f"Plotter {PORT} portunda dinliyor...")

    while True:
        conn, addr = s.accept()
        with conn:
            print(f"{addr} bağlandı.")
            data = conn.recv(1024).decode().strip()
            if data:
                print(f"Gelen veri: {data}")

                # Veriyi işle
                try:
                    # Veri formatı: ServerAdı,Kapasite,ZamanDamgası
                    parts = data.split(",")
                    server_name = parts[0].strip()

                    # Eğer kapasite kısmı "status: 1000" şeklinde geliyorsa, sadece sayıyı al
                    capacity_info = parts[1].strip()
                    if "status" in capacity_info:
                        # 'ServerX_status: 1000' formatındaki veriyi ayıklıyoruz
                        capacity = int(capacity_info.split(":")[1].strip())
                    else:
                        capacity = int(capacity_info)

                    # Zaman kısmı; 'timestamp: 1733155551' şeklinde gelebilir
                    timestamp_info = parts[2].strip()
                    if "timestamp" in timestamp_info:
                        timestamp = int(timestamp_info.split(":")[1].strip())
                    else:
                        timestamp = int(timestamp_info)

                    # Verileri sunucunun listesine ekle
                    if server_name in server_data:
                        server_data[server_name].append(capacity)
                    else:
                        server_data[server_name] = [capacity]

                    # Zaman damgasını timestamps listesine ekle
                    timestamps.append(datetime.fromtimestamp(timestamp))  # Zamanı ekleyin

                    # Grafik çizme
                    plt.clf()  # Önceki grafiği temizle

                    # Verilerin eşleştiğinden emin olun
                    for server, values in server_data.items():
                        if len(values) == len(timestamps):  # Eğer uzunluklar eşleşiyorsa
                            plt.plot(timestamps, values, label=server)  # Burada label parametresi ekleniyor
                        else:
                            print(f"Uzunluk uyumsuzluğu: {server} - Kapasite: {len(values)}, Zaman: {len(timestamps)}")

                    # Legend eklemek için bir kontrol
                    if any(len(values) > 0 for values in server_data.values()):
                        plt.legend()  # Etiket eklenmesi için legend çağrısı

                    plt.xlabel("Zaman")
                    plt.ylabel("Kapasite")
                    plt.xticks(rotation=45)  # X eksenindeki zamanları daha okunabilir yapar
                    plt.draw()
                    plt.pause(0.1)  # Grafiği güncellemek için kısa bir süre bekle
                except Exception as e:
                    print(f"Veri işleme hatası: {e}")
