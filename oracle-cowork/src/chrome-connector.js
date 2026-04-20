const { chromium } = require('playwright');
const fs = require('fs');

/**
 * Gets potential Windows Host IPs
 * @returns {string[]}
 */
function getPotentialHostIPs() {
  const ips = new Set();
  
  // Method 1: resolv.conf (requested by GOD)
  try {
    const resolvConf = fs.readFileSync('/etc/resolv.conf', 'utf8');
    const matches = resolvConf.matchAll(/nameserver\s+([\d.]+)/g);
    for (const match of matches) {
      const ip = match[1];
      if (ip && ip !== '127.0.0.1' && ip !== '0.0.0.0') {
        ips.add(ip);
      }
    }
  } catch (e) {
    // Ignore errors reading resolv.conf
  }

  // Method 2: ip route (as a robust backup to find the real gateway)
  try {
    const { execSync } = require('child_process');
    const gateway = execSync("ip route show | grep default | awk '{print $3}'", { encoding: 'utf8' }).trim();
    if (gateway && /^[\d.]+$/.test(gateway)) {
      ips.add(gateway);
    }
  } catch (e) {
    // Ignore errors running ip route
  }
  
  return Array.from(ips);
}

async function tryConnect(url, timeout = 5000) {
  console.log(`\x1b[36mAttempting to connect to Chrome at ${url} (timeout: ${timeout}ms)...\x1b[0m`);
  try {
    const browser = await chromium.connectOverCDP(url, { timeout });
    return browser;
  } catch (error) {
    throw error;
  }
}

(async () => {
  const attempts = ['http://localhost:9222'];
  const hostIps = getPotentialHostIPs();
  
  hostIps.forEach(ip => {
    const url = `http://${ip}:9222`;
    if (!attempts.includes(url)) {
      attempts.push(url);
    }
  });

  let browser = null;
  let lastError = null;
  let successfulUrl = null;

  for (const url of attempts) {
    try {
      browser = await tryConnect(url, 5000);
      if (browser) {
        successfulUrl = url;
        break;
      }
    } catch (error) {
      lastError = error;
      console.log(`\x1b[33mFailed to connect to ${url}: ${error.message}\x1b[0m`);
    }
  }

  if (browser) {
    try {
      // Get the first context
      const contexts = browser.contexts();
      const context = contexts.length > 0 ? contexts[0] : await browser.newContext();
      
      // Check pages
      const pages = context.pages();
      if (pages.length > 0) {
        const page = pages[0];
        const title = await page.title();
        console.log(`\x1b[32m✅ Successfully connected to ${successfulUrl}! Current page title: "${title}"\x1b[0m`);
      } else {
        const page = await context.newPage();
        await page.goto('about:blank');
        console.log(`\x1b[32m✅ Successfully connected to ${successfulUrl}! Opened a new blank page.\x1b[0m`);
      }
      
      console.log('\x1b[36mGracefully disconnecting from Chrome...\x1b[0m');
      await browser.close(); 
      console.log('\x1b[32mDisconnected successfully.\x1b[0m');
    } catch (e) {
      console.error(`Error during browser operations: ${e.message}`);
      await browser.close();
    }
  } else {
    console.error('\n\x1b[41m\x1b[37m ❌ ERROR: COULD NOT CONNECT TO CHROME VIA CDP \x1b[0m\n');
    console.error('\x1b[33mChecked following endpoints:\x1b[0m');
    attempts.forEach(url => console.error(` - ${url}`));
    console.error('\n\x1b[33mPlease ensure Chrome is running on Windows with remote debugging enabled.\x1b[0m');
    console.error('\x1b[36mTo start Chrome correctly on Windows/WSL, run the following command in your Windows Run dialog (Win + R) or a standard Windows CMD/PowerShell:\x1b[0m\n');
    console.error('\x1b[1m\x1b[32mchrome.exe --remote-debugging-port=9222 --user-data-dir="C:\\chrome-dev-profile"\x1b[0m\n');
    console.error('\x1b[33m(Make sure all existing Chrome instances are fully closed before running this command, or the flag will be ignored.)\x1b[0m\n');
    console.error(`\x1b[90mLast error details: ${lastError ? lastError.message : 'Unknown error'}\x1b[0m\n`);
    process.exit(1);
  }
})();
