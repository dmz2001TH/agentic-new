const fs = require('fs');
const path = require('path');
const { launchBrowser } = require('./browser-base');

/**
 * Oracle Cowork: GMAIL DEEP ANALYZER
 * Phase 1: Extracts last 10 emails, classifies them, and generates a markdown report.
 */

const classifyEmail = (sender, subject, snippet) => {
  const lowerSender = sender.toLowerCase();
  const lowerSubject = subject.toLowerCase();
  const lowerSnippet = (snippet || '').toLowerCase();
  const fullText = `${lowerSender} ${lowerSubject} ${lowerSnippet}`;

  // More specific keywords and sender-based rules
  const actionSenders = ['github', 'gitlab', 'jira', 'asana', 'trello'];
  const actionKeywords = [
    'please review', 'action required', 'review request', 'approval needed',
    'meeting request', 'invitation', 'due date', 'task assigned', 'deploy', 'build failed',
    're:', 'question for',
  ];
  
  const fyiKeywords = [
    'update', 'summary', 'report', 'notification', 'analytics', 'daily digest', 
    'weekly status', 'merge successful', 'deployment successful'
  ];
  
  const promoSenders = ['support@', 'no-reply@', 'newsletter@', 'deals@'];
  const promoKeywords = [
    'sale', 'offer', 'discount', 'limited time', 'newsletter', 'deals', 'save', 
    'subscription', 'free trial', 'webinar', 'coupon', 'unsubscribe'
  ];

  const highPriorityKeywords = ['urgent', 'important', 'security', 'alert', 'password reset'];

  // --- Classification Logic ---

  // 1. Check for Promotions first (most likely to be ignorable)
  if (promoSenders.some(s => lowerSender.includes(s)) || promoKeywords.some(kw => fullText.includes(kw))) {
    return { type: 'Promo', priority: 'Low' };
  }

  // 2. Check for high-priority Action Items
  if (highPriorityKeywords.some(kw => fullText.includes(kw))) {
    return { type: 'Action Item', priority: 'High' };
  }

  // 3. Check for standard Action Items
  if (actionSenders.some(s => lowerSender.includes(s)) || actionKeywords.some(kw => fullText.includes(kw))) {
      // Differentiate priority within Action Items
      if (['deploy', 'build failed', 're:'].some(kw => lowerSubject.includes(kw))) {
          return { type: 'Action Item', priority: 'Mid' };
      }
      return { type: 'Action Item', priority: 'Low' };
  }

  // 4. Check for FYI
  if (fyiKeywords.some(kw => fullText.includes(kw))) {
    return { type: 'FYI', priority: 'Low' };
  }

  // 5. Default classification
  return { type: 'FYI', priority: 'Low' };
};

async function scanGmail() {
  console.log('═══════════════════════════════════════════════════════════');
  console.log('📧 ORACLE GMAIL DEEP ANALYZER');
  console.log('═══════════════════════════════════════════════════════════');
  
  let browserContext;
  try {
    const { browserContext: context, page } = await launchBrowser();
    browserContext = context;

    console.log('🌐 Navigating to Gmail Inbox...');
    await page.goto('https://mail.google.com', { waitUntil: 'networkidle', timeout: 90000 });

    console.log('⏳ Waiting for Gmail inbox to load...');
    await page.waitForSelector('tr.zA', { timeout: 60000 });

    console.log('🧪 Extracting intelligence (Last 10 Emails)...');
    
    const emails = await page.evaluate(() => {
        const emailRows = Array.from(document.querySelectorAll('tr.zA')).slice(0, 10);
        return emailRows.map(row => {
            const senderEl = row.querySelector('span[email]');
            const subjectEl = row.querySelector('.y6 span');
            const snippetEl = row.querySelector('.y2');
            
            const sender = senderEl ? senderEl.getAttribute('name') : 'Unknown Sender';
            const subject = subjectEl ? subjectEl.innerText.trim() : 'No Subject';
            const snippet = snippetEl ? snippetEl.innerText.replace(/\n/g, ' ').trim() : '';

            return { sender, subject, snippet };
        });
    });

    if (emails.length === 0) {
      console.log('📪 No emails found in the inbox.');
      if (browserContext) {
        await browserContext.close();
      }
      return;
    }

    console.log(`📊 Found ${emails.length} emails. Classifying...`);

    const reportData = emails.map((email, index) => {
      const { type, priority } = classifyEmail(email.sender, email.subject, email.snippet);
      return {
        num: index + 1,
        ...email,
        type,
        priority,
      };
    });

    const today = new Date().toISOString().slice(0, 10);
    const reportPath = path.join(process.cwd(), 'ψ', 'memory', 'inbox', `gmail-report-${today}.md`);
    
    let markdownContent = `# Gmail Report - ${today}\n\n`;
    markdownContent += '| No. | Sender | Subject | Type | Priority |\n';
    markdownContent += '|:----|:-------|:--------|:-----|:---------|\n';
    reportData.forEach(item => {
      const cleanSender = item.sender.replace(/\|/g, '\\|');
      const cleanSubject = item.subject.replace(/\|/g, '\\|');
      markdownContent += `| ${item.num} | ${cleanSender} | ${cleanSubject} | ${item.type} | ${item.priority} |\n`;
    });
    
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, markdownContent);
    
    console.log('───────────────────────────────────────────────────────────');
    console.log(`✅ Report generated successfully!`);
    console.log(`📍 Location: ${reportPath}`);
    console.log('───────────────────────────────────────────────────────────');


  } catch (err) {
    console.error(`
❌ GMAIL SCANNER ERROR: ${err.message}`);
     if (browserContext) {
        const pages = browserContext.pages();
        if (pages.length > 0) {
          const errorPath = path.join(process.cwd(), 'gmail-error.png');
          console.log(`📸 Taking error screenshot at: ${errorPath}`);
          try {
            await pages[0].screenshot({ path: errorPath });
          } catch (e) {
            console.error(`Failed to take screenshot: ${e.message}`);
          }
        }
      }
    process.exit(1);
  } finally {
    if (browserContext) {
      await browserContext.close();
      console.log('🚪 Browser closed.');
    }
  }
}

scanGmail();
