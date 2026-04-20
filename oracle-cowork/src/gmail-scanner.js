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

  // Priority Keywords
  const highPriorityKeywords = ['urgent', 'action required', 'important', 'alert', 'security', 'password', 'reset'];
  const midPriorityKeywords = ['meeting', 'question', 'update', 'review', 'follow-up', 'deploy', 'build failed'];

  // Type Keywords
  const actionKeywords = ['meeting', 'question', 'task', 'required', 'please', 'review', 'approve', 'action', 'deploy'];
  const fyiKeywords = ['github', 'vercel', 'aws', 'google cloud', 'update', 'summary', 'report', 'notification', 'analytics'];
  const promoKeywords = ['sale', 'offer', 'discount', 'limited time', 'newsletter', 'deals', 'save', 'subscription'];

  let type = 'FYI'; // Default type
  let priority = 'Low'; // Default priority

  if (promoKeywords.some(kw => fullText.includes(kw))) {
    type = 'Promo/Spam';
    priority = 'Low';
  } else if (actionKeywords.some(kw => fullText.includes(kw))) {
    type = 'Action Item';
    priority = 'Mid'; // Default for action items
  } else if (fyiKeywords.some(kw => fullText.includes(kw))) {
    type = 'FYI';
    priority = 'Low';
  }

  // Override priority based on high/mid keywords
  if (highPriorityKeywords.some(kw => fullText.includes(kw))) {
    priority = 'High';
  } else if (priority !== 'High' && midPriorityKeywords.some(kw => fullText.includes(kw))) {
    priority = 'Mid';
  }
  
  if (type === 'Action Item' && priority === 'Low') {
      priority = 'Mid';
  }


  return { type, priority };
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
            const snippet = snippetEl ? snippetEl.innerText.replace(/
/g, ' ').trim() : '';

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
    
    let markdownContent = `# Gmail Report - ${today}

`;
    markdownContent += '| No. | Sender | Subject | Type | Priority |
';
    markdownContent += '|:----|:-------|:--------|:-----|:---------|
';
    reportData.forEach(item => {
      const cleanSender = item.sender.replace(/\|/g, '\|');
      const cleanSubject = item.subject.replace(/\|/g, '\|');
      markdownContent += `| ${item.num} | ${cleanSender} | ${cleanSubject} | ${item.type} | ${item.priority} |
`;
    });
    
    fs.mkdirSync(path.dirname(reportPath), { recursive: true });
    fs.writeFileSync(reportPath, markdownContent);
    
    console.log('───────────────────────────────────────────────────────────');
    console.log(`✅ Report generated successfully!`);
    console.log(`📍 Location: ${reportPath}`);
    console.log('───────────────────────────────────────────────────────────
');


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
