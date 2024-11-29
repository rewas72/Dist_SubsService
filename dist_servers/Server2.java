import java.io.*;
import java.net.*;
import java.time.Instant;

public class Server2 {
    private static final int PORT = 5001; // Server2 portu
    private static final int[] OTHER_PORTS = {5000, 5002}; // Diğer sunucuların portları

    public static void main(String[] args) {
        // Diğer sunucularla bağlantı kur
        for (int port : OTHER_PORTS) {
            new Thread(() -> connectToServer("localhost", port)).start();
        }

        // Sunucuyu başlat
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Server2 " + PORT + " portunda çalışıyor...");
            while (true) {
                Socket clientSocket = serverSocket.accept();
                new Thread(() -> handleClient(clientSocket)).start();
            }
        } catch (IOException e) {
            System.out.println("Server2 hata: " + e.getMessage());
        }
    }

    private static void connectToServer(String host, int port) {
        try (Socket socket = new Socket(host, port)) {
            System.out.println("Server2, " + host + ":" + port + " ile bağlantı kurdu.");
        } catch (IOException e) {
            System.out.println("Server2, " + host + ":" + port + " bağlantı kuramadı.");
        }
    }

    private static void handleClient(Socket clientSocket) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
             PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true)) {

            String message = in.readLine();
            System.out.println("Server2'den gelen mesaj: " + message);

            if ("STRT".equals(message)) {
                out.println("Demand: STRT, Response: YEP");
            } else if ("CPCTY".equals(message)) {
                long timestamp = Instant.now().getEpochSecond();
                out.println("server2_status: 1000, timestamp: " + timestamp);
            } else {
                out.println("Demand: " + message + ", Response: NOP");
            }

        } catch (IOException e) {
            System.out.println("Server2 istemci hatası: " + e.getMessage());
        }
    }
}
