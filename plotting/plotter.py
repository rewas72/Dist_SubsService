import socket
import matplotlib.pyplot as plt
from datetime import datetime

HOST = "localhost"
PORT = 6000

server_data = {"Server1": [], "Server2": [], "Server3": []}
timestamps = []

plt.ion()

def parse_data(data):

    try:
        parts = data.split(",")

      
        server_name = parts[0].strip()

        
        if "status" in parts[1]:
            capacity = int(parts[1].split(":")[1].strip())
        else:
            capacity = int(parts[1].strip())

        
        if "timestamp" in parts[-1]:
            timestamp = int(parts[-1].split(":")[1].strip())
        else:
            timestamp = int(parts[2].strip())

        return server_name, capacity, timestamp

    except Exception as e:
        raise ValueError(f"Geçersiz veri formatı: {data}. Hata: {e}")

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
                try:
                    server_name, capacity, timestamp = parse_data(data)

                   
                    if server_name in server_data:
                        server_data[server_name].append(capacity)
                    else:
                        server_data[server_name] = [capacity]

                    timestamps.append(datetime.fromtimestamp(timestamp))

                    
                    plt.clf()
                    for server, values in server_data.items():
                        plt.plot(timestamps[:len(values)], values, label=server)

                    plt.xlabel("Zaman")
                    plt.ylabel("Kapasite")
                    plt.xticks(rotation=45)
                    plt.legend(loc="upper left")
                    plt.draw()
                    plt.pause(0.1)

                except ValueError as ve:
                    print(f"Veri işleme hatası: {ve}")