
class Capacity:
    def __init__(self, server_status, timestamp):
        self.server_status = server_status
        self.timestamp = timestamp

    def __str__(self):
        return f"Server Status: {self.server_status} , Timestamp: {self.timestamp}"
