#!/usr/bin/env python3
import socket
import threading
import subprocess
import os
import sys
import time

def get_host_ip():
    """Detect Windows Host IP from WSL."""
    # Method 1: ip route
    try:
        result = subprocess.check_output("ip route show default | awk '{print $3}'", shell=True)
        ip = result.decode().strip()
        if ip: return ip
    except: pass

    # Method 2: /etc/resolv.conf (WSL2 usually puts host IP as nameserver)
    try:
        with open("/etc/resolv.conf", "r") as f:
            for line in f:
                if "nameserver" in line:
                    parts = line.split()
                    if len(parts) >= 2:
                        return parts[1].strip()
    except: pass
    
    return None

def forward_data(source, destination):
    try:
        while True:
            data = source.recv(8192)
            if not data:
                break
            destination.sendall(data)
    except:
        pass
    finally:
        try: source.close()
        except: pass
        try: destination.close()
        except: pass

def handler(client_socket, host_ip, port):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        # Connect to Windows Chrome
        server_socket.settimeout(2.0)
        server_socket.connect((host_ip, port))
        server_socket.settimeout(None)
        
        # Start bidirectional forwarding
        # Thread 1: WSL -> Windows
        t1 = threading.Thread(target=forward_data, args=(client_socket, server_socket), daemon=True)
        # Thread 2: Windows -> WSL
        t2 = threading.Thread(target=forward_data, args=(server_socket, client_socket), daemon=True)
        
        t1.start()
        t2.start()
    except Exception as e:
        # print(f"[{time.strftime('%H:%M:%S')}] ❌ Forwarding error: {e}")
        client_socket.close()

def main():
    listen_port = 9222
    target_port = 9222
    host_ip = get_host_ip()
    
    if not host_ip:
        print("❌ Error: Could not detect Windows Host IP.")
        sys.exit(1)

    print(f"🌐 BRIDGE: WSL localhost:{listen_port} ➔ Windows {host_ip}:{target_port}")
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        server.bind(('127.0.0.1', listen_port))
    except Exception as e:
        print(f"❌ Error: Bind failure on localhost:{listen_port} - {e}")
        sys.exit(1)

    server.listen(20)
    
    try:
        while True:
            client, addr = server.accept()
            # New thread for each client connection
            threading.Thread(target=handler, args=(client, host_ip, target_port), daemon=True).start()
    except KeyboardInterrupt:
        print("\n🛑 Bridge shutting down.")
    finally:
        server.close()

if __name__ == "__main__":
    main()
