// 🔮 Oracle Supreme Background Controller
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true });

// ฟังข้อความจาก Sidepanel หรือ GOD Brain
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "ATTACH_DEBUGGER") {
    const target = { tabId: message.tabId };
    chrome.debugger.attach(target, "1.3", () => {
      if (chrome.runtime.lastError) {
        console.error(chrome.runtime.lastError);
        sendResponse({ success: false, error: chrome.runtime.lastError.message });
      } else {
        console.log("🟢 Debugger Attached to tab:", message.tabId);
        sendResponse({ success: true });
      }
    });
    return true; // Keep channel open
  }

  if (message.type === "SEND_CDP_COMMAND") {
    const target = { tabId: message.tabId };
    chrome.debugger.sendCommand(target, message.method, message.params, (result) => {
      sendResponse({ success: !chrome.runtime.lastError, result, error: chrome.runtime.lastError });
    });
    return true;
  }
});

// แจ้งเตือนเมื่อหลุดการเชื่อมต่อ
chrome.debugger.onDetach.addListener((source, reason) => {
  console.warn("🔴 Debugger Detached:", reason);
});
