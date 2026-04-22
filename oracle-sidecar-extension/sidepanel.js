let currentTabId;

async function init() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (!tab || tab.url.startsWith('chrome://')) return;
  
  currentTabId = tab.id;
  
  // สั่งให้ Background Attach Debugger
  chrome.runtime.sendMessage({ type: "ATTACH_DEBUGGER", tabId: currentTabId }, (response) => {
    if (response && response.success) {
      document.getElementById('status').innerText = "🔮 Inhabiting: " + tab.title;
      document.getElementById('status').style.color = "#00ff00";
    } else {
      document.getElementById('status').innerText = "❌ Connection Failed";
      document.getElementById('status').style.color = "#ff4444";
    }
  });
}

// ฟังก์ชัน "สกัดแผนที่" (Accessibility Tree) - นี่คือหัวใจของความฉลาด
async function getMap() {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage({
      type: "SEND_CDP_COMMAND",
      tabId: currentTabId,
      method: "Accessibility.getFullAXTree",
      params: {}
    }, (response) => {
      resolve(response.result);
    });
  });
}

// ปุ่มทดสอบ "คลิกจุดพิกัด" (ตัวอย่างการคุมเมาส์แบบเทพ)
async function testClick(x, y) {
  chrome.runtime.sendMessage({
    type: "SEND_CDP_COMMAND",
    tabId: currentTabId,
    method: "Input.dispatchMouseEvent",
    params: { type: "mousePressed", x, y, button: "left", clickCount: 1 }
  });
  setTimeout(() => {
    chrome.runtime.sendMessage({
      type: "SEND_CDP_COMMAND",
      tabId: currentTabId,
      method: "Input.dispatchMouseEvent",
      params: { type: "mouseReleased", x, y, button: "left", clickCount: 1 }
    });
  }, 100);
}

// เรียกใช้งานเมื่อเปิด Sidepanel
init();

// รับฟังการเปลี่ยนแท็บ
chrome.tabs.onActivated.addListener(init);
