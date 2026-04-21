
const { launchBrowser } = require('./browser-base');

const SLACK_URL_PATTERN = /app\.slack\.com/;

/**
 * Finds a Slack page from the browser context.
 * @param {import('playwright').BrowserContext} browserContext
 * @returns {Promise<import('playwright').Page | null>}
 */
const findSlackPage = async (browserContext) => {
  const pages = browserContext.pages();
  for (const page of pages) {
    if (SLACK_URL_PATTERN.test(page.url())) {
      return page;
    }
  }
  return null;
};

/**
 * Extracts unread channel names from a Slack page.
 * NOTE: These selectors are based on the Slack web UI as of late 2023/early 2024.
 * They are subject to change and might need updating.
 * @param {import('playwright').Page} page
 * @returns {Promise<string[]>}
 */
const getUnreadChannels = async (page) => {
    // In Slack's UI, unread channels are typically bold.
    // We find the sidebar, then look for channel links that are styled as unread.
    // The selector `[class*="p-channel_sidebar__channel--unread"]` is a common pattern.
    const unreadChannelLocators = page.locator('.p-channel_sidebar__channel--unread:not(.p-channel_sidebar__channel--muted) a[data-qa^="channel_sidebar_channel_"]');
    
    try {
        const count = await unreadChannelLocators.count();
        if (count === 0) {
            return [];
        }

        const channels = [];
        for (let i = 0; i < count; i++) {
            const locator = unreadChannelLocators.nth(i);
            const channelName = await locator.textContent();
            // Clean up the name which might include notification counts
            if (channelName) {
                channels.push(channelName.replace(/\d+$/, '').trim());
            }
        }
        return channels;
    } catch (error) {
        console.error("Could not query for unread channels, Slack UI might have changed.", error);
        return [];
    }
};

/**
 * Extracts the number of mentions from the Slack page.
 * @param {import('playwright').Page} page
 * @returns {Promise<number>}
 */
const getMentionsCount = async (page) => {
    // Mentions are usually in the "Mentions & reactions" section with a badge.
    // The selector `[data-qa="mention_badge"]` is a good candidate.
    const mentionBadge = page.locator('[data-qa="mention_badge"]');
    try {
        if (await mentionBadge.isVisible()) {
            const countText = await mentionBadge.textContent();
            return parseInt(countText, 10) || 0;
        }
        return 0;
    } catch (error) {
        // If the badge is not found, it's likely there are no mentions.
        return 0;
    }
};


(async () => {
  const { browserContext, page } = await launchBrowser();
  
  try {
    const slackPage = await findSlackPage(browserContext);

    if (!slackPage) {
      console.log("No active Slack workspace found in the browser.");
      return;
    }

    // Bring the slack page to the front to ensure it's active
    await slackPage.bringToFront();
    
    // Wait for the sidebar to be loaded
    await slackPage.waitForSelector('.p-channel_sidebar', { timeout: 10000 });

    const unreadChannels = await getUnreadChannels(slackPage);
    const mentionsCount = await getMentionsCount(slackPage);

    const output = {
        unreadChannels,
        mentionsCount,
        threadsCount: 0, // Placeholder, as thread counting is more complex
    };

    console.log(JSON.stringify(output, null, 2));

  } catch (error) {
    console.error("An error occurred during Slack extraction:", error);
  } finally {
    if (browserContext) {
      await browserContext.close();
    }
  }
})();
