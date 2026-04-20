const { chromium } = require('playwright');

/**
 * Launches a Playwright browser with a persistent context.
 * @returns {Promise<{browserContext: import('playwright').BrowserContext, page: import('playwright').Page}>}
 */
const launchBrowser = async () => {
  const userDataDir = 'C:\Users\Public\.oracle-browser-profile';
  
  try {
    const browserContext = await chromium.launchPersistentContext(userDataDir, {
      headless: true, // Headless is better for autonomous operation
      // viewport: null, // Use the default viewport
      // userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    });
    
    // The first page in a persistent context is often a blank page, 
    // it's better to create a new one.
    const page = await browserContext.newPage();

    return { browserContext, page };
  } catch (error) {
    console.error('Failed to launch browser with persistent context:', error);
    process.exit(1);
  }
};

module.exports = { launchBrowser };
