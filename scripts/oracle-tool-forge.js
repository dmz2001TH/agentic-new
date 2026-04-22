const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const TOOLS_DIR = path.join(__dirname, '../oracle-cowork/dynamic_tools');
if (!fs.existsSync(TOOLS_DIR)) {
    fs.mkdirSync(TOOLS_DIR, { recursive: true });
}

const command = process.argv[2];

if (command === 'forge') {
    const toolName = process.argv[3];
    // ในสถานการณ์จริง โค้ดตรงนี้จะมาจาก LLM (เช่น GPT-4 หรือ Claude) 
    // ที่ถูกสั่งให้เขียนสคริปต์แก้ปัญหาตามที่ผู้ใช้ขอ
    const simulatedLlmCode = process.argv[4] || `
        // Auto-generated Dynamic Tool: ${toolName}
        const args = process.argv.slice(2);
        console.log(\`🔧 [${toolName}] Executing with args: \${args.join(', ')}\`);
        if (args.length === 0) console.log('No arguments provided.');
        // Simulated logic...
        console.log(\`✅ [${toolName}] Task completed successfully.\`);
    `;

    const toolPath = path.join(TOOLS_DIR, `${toolName}.js`);
    
    console.log(`🔨 [Oracle Forge] กำลังหลอมเครื่องมือใหม่: ${toolName}...`);
    fs.writeFileSync(toolPath, simulatedLlmCode);
    console.log(`✨ [Oracle Forge] สร้างเครื่องมือสำเร็จ! บันทึกที่: ${toolPath}`);

} else if (command === 'run') {
    const toolName = process.argv[3];
    const toolArgs = process.argv.slice(4).join(' ');
    const toolPath = path.join(TOOLS_DIR, `${toolName}.js`);

    if (fs.existsSync(toolPath)) {
        console.log(`⚡ [Oracle Forge] กำลังรันเครื่องมือ: ${toolName}...`);
        try {
            const output = execSync(`node ${toolPath} ${toolArgs}`, { encoding: 'utf-8' });
            console.log(output);
        } catch (error) {
            console.error(`❌ [Oracle Forge] Error running tool: ${error.message}`);
        }
    } else {
        console.log(`❌ [Oracle Forge] ไม่พบเครื่องมือชื่อ ${toolName}. เอเจนท์ต้องไป Forge ขึ้นมาก่อน!`);
    }
} else {
    console.log('Usage: node oracle-tool-forge.js [forge|run] <toolName> [code_or_args]');
}
