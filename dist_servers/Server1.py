import socket
import threading
import time
from message import Message  

PORT = 5000  

def handle_client(client_socket):
    try:
        
        message = client_socket.recv(1024).decode('utf-8')
        print(f"Server1({threading.get_ident()}) üzerinde istemciden gelen mesaj: {message}")

        
        if message == "STRT":
            response_msg = Message(demand="STRT", response="YEP")
        else:
            response_msg = Message(demand="STRT", response="NOP")

        
        client_socket.sendall(str(response_msg).encode('utf-8'))
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
        
        time.sleep(10)  

def start_server():
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind(('localhost', PORT))
    server_socket.listen()
    print(f"Server1 {PORT} portunda çalışıyor")

    
    threading.Thread(target=ping_other_server, args=("localhost", 5001)).start()
    threading.Thread(target=ping_other_server, args=("localhost", 5002)).start()

   
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
