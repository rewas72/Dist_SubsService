import java.io.*;
import java.net.*;
import java.util.concurrent.*;
import java.time.Instant;

class Message {
    private String demand;
    private String response;

    public Message(String demand, String response) {
        this.demand = demand;
        this.response = response;
    }

    @Override
    public String toString() {
        return "Demand: " + demand + ", Response: " + response;
    }
}

class Capacity {
    private int serverStatus;
    private long timestamp;

    public Capacity(int serverStatus) {
        this.serverStatus = serverStatus;
        this.timestamp = Instant.now().getEpochSecond();
    }

    @Override
    public String toString() {
        return "server1_status: " + serverStatus + ", timestamp: " + timestamp;
    }
}

public class Server1 {
    private static final int PORT = 5000;

    public static void handleClient(Socket clientSocket) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
             PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true)) {
            
            String message = in.readLine();
            System.out.println("Server1 üzerinde istemciden gelen mesaj: " + message);

            Message responseMsg;
            String responseText;

            if ("STRT".equals(message)) {
                responseMsg = new Message("STRT", "YEP");
                System.out.println("Server1 üzerinde istemciden gelen mesaj sonucu: " + responseMsg);
                
                Capacity capacity = new Capacity(1000);
                responseText = capacity.toString();
                System.out.println("Server1 üzerinde kapasite yanıtı: " + responseText);
            } else {
                responseMsg = new Message("STRT", "NOP");
                responseText = responseMsg.toString();
                System.out.println("Server1 üzerinde istemciden gelen mesaj sonucu: " + responseMsg);
            }

            out.println(responseText);
        } catch (IOException e) {
            System.out.println("İstemci işleme hatası: " + e.getMessage());
        }
    }

    public static void pingOtherServer(String host, int port) {
        while (true) {
            try (Socket socket = new Socket()) {
                socket.connect(new InetSocketAddress(host, port), 5000);
                System.out.println(host + " üzerindeki " + port + " portuna ping gönderildi");
            } catch (IOException e) {
                System.out.println(host + " üzerindeki " + port + " portuna ping başarısız oldu, yeniden deniyor...");
            }

            try {
                Thread.sleep(10000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }

    public static void startServer() {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Server1 " + PORT + " portunda çalışıyor");

            // Diğer sunuculara ping atan iş parçacıkları
            new Thread(() -> pingOtherServer("localhost", 5001)).start();
            new Thread(() -> pingOtherServer("localhost", 5002)).start();

            // İstemci bağlantılarını kabul eden döngü
            while (true) {
                Socket clientSocket = serverSocket.accept();
                new Thread(() -> handleClient(clientSocket)).start();
            }
        } catch (IOException e) {
            System.out.println("Sunucu hatası: " + e.getMessage());
        }
    }

    public static void main(String[] args) {
        startServer();
    }
}
