
class Message:
    def __init__(self, demand, response):
        self.demand = demand
        self.response = response

    def __str__(self):
        return f"Demand: {self.demand}, Response: {self.response}"
