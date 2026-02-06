"""This script is to identify domains that have:
  At least 5 distinct occurrences across 6-hour time slots in a day, 
  with each event either having 5 unique userIDs or 5 unique srcHosts. 
  
  A domain is considered "common" 
    if it satisfies both the time slot and user/srcHost criteria based 
    on DNS response or link-click events provided in the input."""


def get_time_slot(timestamp):
    # Returns "YYYY-MM-DD_S#" to keep slots unique across different days
    date = timestamp.split('T')[0]
    hour = int(timestamp.split('T')[1].split(':')[0])  
    return f"{date}_S{hour // 6}"  

def solution(strArr):    
    #Structure: { domain: { slot_id: { 'srcHosts': set(), 'userIDs': set() } } }
    domain_data = {}  
    
    for event_str in strArr:
        # Each event has 3 components: "timestamp domain userID/Host"
        parts = event_str.split(' ')
        if len(parts) != 3: continue
  
        timestamp_str = parts[0].split('=')[1]   
        domain = parts[1].split('=')[1]   
        
        src_host = None 
        user_id = None
        slot = get_time_slot(timestamp_str)
              
        if domain not in domain_data:
            domain_data[domain] = {}
        if slot not in domain_data[domain]:
            domain_data[domain][slot] = {'srcHosts': set(), 'userIDs': set()}   
        
        # Parse the identity (userID or srcHost)
        key, value = parts[2].split('=')
        if key == "srcHost":
            domain_data[domain][slot]['srcHosts'].add(value)
        elif key == "userID":
            domain_data[domain][slot]['userIDs'].add(value)

    #print(domain_data)  # Debug: Print the collected domain data

    # Find common domains that meet the criteria
    common_domains = []
    for domain, slots in domain_data.items():
        # Check if ANY slot for this domain meets the "5 unique" criteria
        for slot_id, collections in slots.items():
            unique_hosts = len(collections['srcHosts'])
            unique_users = len(collections['userIDs'])
            
            if unique_hosts >= 5 or unique_users >= 5:
                common_domains.append(domain)
                break # Move to next domain once criteria is met once
    
    return common_domains

# Example usage
input_data = [
    # dns-response events (srcHost)
    "timestamp=2023-09-27T00:00:00.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:00:30.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:01:00.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:01:30.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:03:00.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:07:00.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:10:00.000Z domain=example.com srcHost=192.168.0.1",
    "timestamp=2023-09-27T00:17:00.000Z domain=example.com srcHost=192.168.0.1",
    
    # link-click events (userID)
    "timestamp=2023-09-27T00:00:00.000Z domain=example.com userID=1",
    "timestamp=2023-09-27T01:00:00.000Z domain=example.com userID=2",
    "timestamp=2023-09-27T02:00:00.000Z domain=example.com userID=3",
    "timestamp=2023-09-27T03:00:00.000Z domain=example.com userID=4",
    "timestamp=2023-09-27T04:00:00.000Z domain=example.com userID=5"
]

# Run the function with the example input
print(solution(input_data))  # Expected output: ['example.com']
