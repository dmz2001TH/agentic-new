
const { launchBrowser } = require('./browser-base.js');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');

const GMAIL_URL = 'https://mail.google.com/';

async function archivePromotions(page) {
    console.log('Navigating to Promotions category...');
    // This is a best-guess selector. It might need adjustment.
    // It looks for a tab with the text "Promotions"
    await page.click('div[role="tab"][aria-label="Promotions"]');
    await page.waitForSelector('div.Cp tr'); // Wait for email rows to load

    console.log('Identifying and selecting promo emails...');

    // This is a simplified keyword search.
    // A more robust solution would be to use Gmail's search.
    // For now, we search for common promo keywords in the visible part of the email list.
    const promoKeywords = ['sale', 'offer', 'discount', 'save', 'deals'];
    const emailRows = await page.$$('div.Cp tr');
    let emailsSelected = 0;

    for (const row of emailRows) {
        const rowText = await row.innerText();
        const hasKeyword = promoKeywords.some(keyword => rowText.toLowerCase().includes(keyword));
        if (hasKeyword) {
            const checkbox = await row.$('div.oZ-x3');
            if (checkbox) {
                await checkbox.click();
                emailsSelected++;
                // Add a small delay to mimic human behavior
                await page.waitForTimeout(100); 
            }
        }
    }

    if (emailsSelected > 0) {
        console.log(`Selected ${emailsSelected} promotional emails.`);
        // Click the archive button
        const archiveButton = await page.$('div[aria-label="Archive"]');
        if (archiveButton) {
            await archiveButton.click();
            console.log('Emails archived successfully.');
        } else {
            console.error('Could not find the Archive button.');
        }
    } else {
        console.log('No promotional emails found to archive with the current keywords.');
    }
}

async function unsubscribeAndArchive(page, sender) {
    console.log(`Searching for emails from sender: ${sender}`);
    
    // Use Gmail's search bar
    const searchInput = await page.$('input[aria-label="Search mail"]');
    await searchInput.fill(`from:${sender}`);
    await searchInput.press('Enter');
    
    await page.waitForSelector('div.Cp tr', { timeout: 10000 }).catch(() => {
        console.log('No emails found from that sender.');
        return;
    });

    // Find the first email
    const firstEmail = await page.$('div.Cp tr:first-child');
    if (!firstEmail) {
        console.log('No emails found from that sender.');
        return;
    }

    await firstEmail.click();

    // Wait for the email to open
    await page.waitForSelector('a:text-is("unsubscribe")', { timeout: 15000 }).catch(async () => {
         // Fallback if case-sensitive doesn't work
         await page.waitForSelector('a:text-is("Unsubscribe")', { timeout: 5000 });
    });


    console.log('Looking for an unsubscribe link...');
    // This looks for a link with the text 'unsubscribe'. It might not always work.
    const unsubscribeLink = await page.$('a:text-is("unsubscribe"), a:text-is("Unsubscribe")');

    if (unsubscribeLink) {
        console.log('Unsubscribe link found. Clicking...');
        // Clicking might open a new tab. We need to handle that.
        const [newPage] = await Promise.all([
            page.context().waitForEvent('page'),
            unsubscribeLink.click(),
        ]);
        await newPage.waitForLoadState();
        console.log(`Navigated to unsubscribe page: ${newPage.url()}`);
        // We assume the unsubscribe is successful on this new page.
        // A more robust solution would interact with the new page.
        await newPage.close();
        console.log('Unsubscribe page closed.');

    } else {
        console.log('Could not find a standard unsubscribe link in the email.');
        // Still proceed to archive
    }
    
    // Go back to the inbox view
    await page.goto(GMAIL_URL);
    await page.waitForLoadState();

    console.log(`Archiving all emails from ${sender}...`);
    // Res-search for the sender
    await searchInput.fill(`from:${sender}`);
    await searchInput.press('Enter');
    await page.waitForSelector('div.Cp tr');
    
    // Select all emails
    const selectAllCheckbox = await page.$('div[aria-label="Select"] span[role="checkbox"]');
    if (selectAllCheckbox) {
        await selectAllCheckbox.click();
        await page.waitForTimeout(500);

        // Click the archive button
        const archiveButton = await page.$('div[aria-label="Archive"]');
        if (archiveButton) {
            await archiveButton.click();
            console.log(`All emails from ${sender} have been archived.`);
        } else {
            console.error('Could not find Archive button after selecting all.');
        }
    } else {
        console.error('Could not find the "Select All" checkbox.');
    }
}


(async () => {
    const argv = yargs(hideBin(process.argv))
        .option('archive-promo', {
            describe: 'Finds and archives promotional emails.',
            type: 'boolean',
        })
        .option('unsubscribe-from', {
            describe: 'Unsubscribes and archives all emails from a specific sender.',
            type: 'string',
        })
        .help()
        .argv;

    if (!argv.archivePromo && !argv.unsubscribeFrom) {
        console.log('Please specify an action: --archive-promo or --unsubscribe-from <sender>');
        return;
    }

    const { browserContext, page } = await launchBrowser();

    try {
        console.log('Navigating to Gmail...');
        await page.goto(GMAIL_URL, { waitUntil: 'networkidle' });
        
        // Wait for the main UI to be ready
        await page.waitForSelector('div[role="tablist"]', { timeout: 60000 });
        console.log('Gmail loaded.');

        if (argv.archivePromo) {
            await archivePromotions(page);
        } else if (argv.unsubscribeFrom) {
            await unsubscribeAndArchive(page, argv.unsubscribeFrom);
        }

    } catch (error) {
        console.error('An error occurred during the Gmail management task:', error);
    } finally {
        console.log('Closing browser.');
        await browserContext.close();
    }
})();
