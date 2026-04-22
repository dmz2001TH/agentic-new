const fs = require('fs');
const path = require('path');

const WIKI_DIR = path.join(__dirname, '../oracle-cowork/wiki');
if (!fs.existsSync(WIKI_DIR)) {
    fs.mkdirSync(WIKI_DIR, { recursive: true });
}

// จำลองการใช้ LLM ในการสกัด Keyword (Entity Extraction)
// ในระบบจริง จะยิง Prompt หา Claude/GPT เพื่อสกัดคำหลัก
function extractEntities(text) {
    const keywords = ['AI', 'Agent', 'Oracle', 'React', 'Terminal', 'Playwright', 'UI', 'Token'];
    const foundEntities = [];
    keywords.forEach(kw => {
        if (text.toLowerCase().includes(kw.toLowerCase())) {
            foundEntities.push(kw);
        }
    });
    return foundEntities;
}

function createWikiPage(title, rawContent) {
    const fileName = `${title.replace(/\s+/g, '-').toLowerCase()}.md`;
    const filePath = path.join(WIKI_DIR, fileName);

    const entities = extractEntities(rawContent);
    let linkedContent = rawContent;
    
    // สอดแทรก [[Wiki-Links]] เข้าไปในเนื้อหา
    entities.forEach(entity => {
        const regex = new RegExp(`\\b${entity}\\b`, 'gi');
        linkedContent = linkedContent.replace(regex, `[[${entity}]]`);
    });

    const markdownContent = `---
title: ${title}
date: ${new Date().toISOString().split('T')[0]}
tags: [${entities.map(e => `'${e}'`).join(', ')}]
---

# ${title}

${linkedContent}

---
**Related Topics:**
${entities.map(e => `- [[${e}]]`).join('\n')}
`;

    fs.writeFileSync(filePath, markdownContent, 'utf-8');
    console.log(`📚 [Agentic Wiki] Compiled & Saved: ${filePath}`);
    return filePath;
}

const command = process.argv[2];
if (command === 'compile') {
    const pageTitle = process.argv[3];
    const pageContent = process.argv[4];
    
    if (!pageTitle || !pageContent) {
        console.log('Usage: node agentic-wiki.js compile "Title" "Raw content text..."');
        process.exit(1);
    }
    
    createWikiPage(pageTitle, pageContent);
} else {
    console.log('Usage: node agentic-wiki.js compile <Title> <Content>');
}
