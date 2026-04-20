
const { launchBrowser } = require('./browser-base.js');

const FACEBOOK_URL = 'https://www.facebook.com';

const main = async () => {
    const { browserContext, page } = await launchBrowser();

    try {
        console.log('Navigating to Facebook...');
        await page.goto(FACEBOOK_URL, { waitUntil: 'networkidle' });
        await page.waitForTimeout(5000); // Wait for potential redirects and dynamic content

        // --- 1. Handle Notifications ---
        console.log('Looking for notifications icon...');
        
        // Using a selector that is less likely to change. Facebook uses SVGs inside divs for icons.
        // This targets a link that commonly directs to the notifications page.
        const notificationIconSelector = 'a[href="https://www.facebook.com/notifications/"]';
        await page.waitForSelector(notificationIconSelector, { timeout: 15000 });
        console.log('Found notifications icon, clicking...');
        await page.click(notificationIconSelector);

        console.log('Waiting for notifications to appear...');
        // Notifications are often in a list with a specific aria-label
        const notificationListSelector = 'div[aria-label="Notifications"] > div > div > ul';
        await page.waitForSelector(notificationListSelector, { timeout: 10000 });
        
        const notifications = await page.evaluate((selector) => {
            const notificationItems = Array.from(document.querySelectorAll(`${selector} > li`));
            return notificationItems.slice(0, 5).map(item => item.innerText.replace(/
/g, ' ').trim());
        }, notificationListSelector);

        console.log(`Facebook Notifications (5): [${notifications.join(', ')}]`);


        // --- 2. Handle Messenger Unread Count ---
        console.log('Looking for Messenger icon and unread count...');
        
        // Messenger icon often has an aria-label 'Messenger' and contains the unread count in a child element.
        const messengerIconSelector = 'a[aria-label="Messenger"]';
        await page.waitForSelector(messengerIconSelector, { timeout: 10000 });
        
        const unreadCount = await page.evaluate((selector) => {
            const messengerIcon = document.querySelector(selector);
            // The count is usually in a visually hidden element or a span with a specific role.
            const countElement = messengerIcon.querySelector('.x1xka2u1 .x126k92a');
            return countElement ? countElement.innerText.trim() : '0';
        }, messengerIconSelector);

        console.log(`Unread Messages: [${unreadCount || '0'}]`);

    } catch (error) {
        console.error('An error occurred during the Facebook scan:', error.message);
        // Taking a screenshot for debugging purposes
        const screenshotPath = `facebook-scan-error-${Date.now()}.png`;
        await page.screenshot({ path: screenshotPath, fullPage: true });
        console.error(`Screenshot saved to ${screenshotPath}`);
    } finally {
        console.log('Closing browser.');
        await browserContext.close();
    }
};

main();
