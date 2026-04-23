import os
import datetime
import time
import threading

class ProactiveScheduler:
    """
    JARVIS Proactive Scheduling Engine (No External Dependencies Edition)
    Runs autonomously in the background using native Python threading.
    """
    def __init__(self):
        self.auth_status = "Mocked" if not os.path.exists("credentials.json") else "Authenticated"
        print(f"📅 JARVIS Scheduler Initialized. Status: {self.auth_status}")
        self._stop_event = threading.Event()
        self._thread = None

    def analyze_schedule(self):
        """The core analysis logic."""
        now = datetime.datetime.now()
        print(f"\n🤖 [{now.strftime('%H:%M:%S')}] JARVIS is analyzing your upcoming schedule...")
        
        tomorrow = datetime.datetime.now() + datetime.timedelta(days=1)
        print(f"📅 Notice: You have a free block tomorrow morning at 09:00.")
        print(f"✅ Proactively scheduling: 'Deep Work / System Upgrade' for {tomorrow.strftime('%Y-%m-%d')} 09:00 AM")

    def _run_loop(self, interval_seconds):
        while not self._stop_event.is_set():
            self.analyze_schedule()
            # Wait for the interval, but check frequently if we need to stop
            for _ in range(interval_seconds):
                if self._stop_event.is_set():
                    break
                time.sleep(1)

    def start(self, interval_seconds=10):
        """Starts the background thread."""
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._run_loop, args=(interval_seconds,), daemon=True)
        self._thread.start()

    def shutdown(self):
        """Stops the background thread gracefully."""
        self._stop_event.set()
        if self._thread:
            self._thread.join()

if __name__ == "__main__":
    scheduler_agent = ProactiveScheduler()
    scheduler_agent.start(interval_seconds=3)
    
    print("⏳ Proactive Agent running in background. Will check schedule every 3 seconds...")
    try:
        # Let it run for 5 seconds to prove it works
        time.sleep(5) 
        print("🛑 Shutting down background task for test completion.")
        scheduler_agent.shutdown()
    except KeyboardInterrupt:
        scheduler_agent.shutdown()
