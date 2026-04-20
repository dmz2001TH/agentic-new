const { chromium } = require('playwright');

/**
 * Oracle Cowork Browser Engine
 * Powered by Master Peach's ULTIMATE method: Playwright with Persistent Context.
 * 
 * v2.0: Now supports modular data extraction.
 */

const DEFAULT_PROFILE_PATH = 'C:\\Users\\Public\\.oracle-browser-profile';

async function launchOracleBrowser(options = {}) {
  const profilePath = options.profilePath || DEFAULT_PROFILE_PATH;
  const headless = options.headless !== undefined ? options.headless : false;

  console.log(`🚀 Launching Oracle Browser with profile: ${profilePath}`);
  
  const context = await chromium.launchPersistentContext(profilePath, {
    headless: headless,
    channel: 'chrome', // Use the installed Chrome browser
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-blink-features=AutomationControlled',
      '--start-maximized'
    ],
    viewport: null // Allow the browser to control the viewport (maximized)
  });

  return context;
}

/**
 * Utility for simple data extraction
 * @param {import('playwright').Page} page 
 * @param {string} selector 
 * @param {(elements: Element[]) => any} evaluator 
 */
async function extractData(page, selector, evaluator) {
  await page.waitForSelector(selector, { timeout: 10000 });
  return await page.$$eval(selector, evaluator);
}

// Export for other scripts
if (require.main !== module) {
  module.exports = {
    launchOracleBrowser,
    extractData,
    DEFAULT_PROFILE_PATH
  };
} else {
  // Main execution logic for standalone use
  (async () => {
    const targetUrl = process.argv[2] || 'https://google.com';

    console.log('═══════════════════════════════════════════════════════════');
    console.log('🚀 ORACLE COWORK — BROWSER ENGINE (v2.0)');
    console.log(`🔗 Target:  ${targetUrl}`);
    console.log('═══════════════════════════════════════════════════════════');

    try {
      const context = await launchOracleBrowser();
      console.log('✅ Browser launched successfully!');

      // Get the first page or create a new one
      let page = context.pages().length > 0 ? context.pages()[0] : await context.newPage();

      // Navigate to the target URL if it's provided
      if (targetUrl) {
        console.log(`🌐 Navigating to: ${targetUrl}`);
        await page.goto(targetUrl).catch(e => console.error(`⚠️ Navigation failed: ${e.message}`));
      }

      console.log('\n💡 Tip: Keep this window open. Oracle can now "Co-work" with you!');
      console.log('❌ Close the browser window to exit.');

      // Handle closure
      context.on('close', () => {
        console.log('\n🛑 Browser context closed. Exiting.');
        process.exit(0);
      });

    } catch (err) {
      console.error('\n❌ CRITICAL ERROR:');
      console.error(err);
      
      if (err.message.includes('executable')) {
        console.log('\n💡 Troubleshooting: Ensure Google Chrome is installed on Windows.');
        console.log('Run: bun playwright install chrome');
      }
      
      process.exit(1);
    }
  })();
}
