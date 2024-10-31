import socket
import threading
import time

PORT = 5002  # Server2'nin portu

def handle_client(client_socket):
    try:
        # İstemciden gelen mesajı al
        message = client_socket.recv(1024).decode('utf-8')
        print(f"Server3({threading.get_ident()}) üzerinde istemciden gelen mesaj: {message}")

        # İstemciye cevap gönder
        response = "55 TAMM"
        client_socket.sendall(response.encode('utf-8'))
    except Exception as e:
        print(f"İstemci işleme hatası: {e}")
    finally:
        client_socket.close()

def ping_other_server(host, port):
    while True:
        try:
            with socket.create_connection((host, port), timeout=5):
                print(f"{host} üzerindeki {port} portuna ping gönderildi")
        except Exception:
            print(f"{host} üzerindeki {port} portuna ping başarısız oldu, yeniden deniyor...")
        
        time.sleep(10)  # 10 saniye bekle

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', PORT))
    server_socket.listen()
    print(f"Server2 {PORT} portunda çalışıyor")

    # Diğer sunuculara ping gönder
    threading.Thread(target=ping_other_server, args=("localhost", 5000)).start()  # Server1'e ping
    threading.Thread(target=ping_other_server, args=("localhost", 5001)).start()  # Server3'e ping

    # İstemci bağlantılarını dinle
    try:
        while True:
            client_socket, _ = server_socket.accept()
            threading.Thread(target=handle_client, args=(client_socket,)).start()
    except Exception as e:
        print(f"Sunucu hatası: {e}")
    finally:
        server_socket.close()

if __name__ == "__main__":
    start_server()
