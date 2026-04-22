const fs = require('fs');
const path = require('path');

const BLACKBOARD_FILE = path.join(__dirname, '../oracle-cowork/blackboard.json');

// สร้างกระดานดำถ้ายังไม่มี
if (!fs.existsSync(BLACKBOARD_FILE)) {
    fs.writeFileSync(BLACKBOARD_FILE, JSON.stringify({ tasks: [] }, null, 2));
}

const command = process.argv[2];

function loadBoard() {
    return JSON.parse(fs.readFileSync(BLACKBOARD_FILE, 'utf-8'));
}

function saveBoard(data) {
    fs.writeFileSync(BLACKBOARD_FILE, JSON.stringify(data, null, 2));
}

switch (command) {
    case 'publish':
        // สั่งงานทิ้งไว้พร้อมความสำคัญ (Pheromone)
        const agentName = process.argv[3];
        const taskName = process.argv[4];
        const initialPheromone = parseInt(process.argv[5] || '100');
        
        let board = loadBoard();
        board.tasks.push({
            id: Date.now().toString(),
            publisher: agentName,
            task: taskName,
            pheromone: initialPheromone,
            status: 'pending',
            timestamp: new Date().toISOString()
        });
        saveBoard(board);
        console.log(`📣 [${agentName}] ทิ้งร่องรอยงาน: "${taskName}" (Pheromone: ${initialPheromone})`);
        break;

    case 'decay':
        // ลดความสำคัญของงานลงตามกาลเวลา (ระเหย)
        let decayBoard = loadBoard();
        let decayedCount = 0;
        decayBoard.tasks = decayBoard.tasks.map(t => {
            if (t.status === 'pending' && t.pheromone > 0) {
                t.pheromone = Math.max(0, t.pheromone - 10);
                decayedCount++;
            }
            return t;
        }).filter(t => t.pheromone > 0 || t.status !== 'pending'); // ลบงานที่ระเหยหมด
        
        saveBoard(decayBoard);
        console.log(`💨 กลิ่นร่องรอยระเหยลง 10 หน่วย (กระทบ ${decayedCount} งาน)`);
        break;

    case 'consume':
        // เอเจนท์มาดมกลิ่นและรับงานที่ Pheromone สูงสุดไปทำ
        const consumerName = process.argv[3];
        let consumeBoard = loadBoard();
        
        // หางานที่สำคัญที่สุด
        let bestTask = consumeBoard.tasks
            .filter(t => t.status === 'pending')
            .sort((a, b) => b.pheromone - a.pheromone)[0];

        if (bestTask) {
            bestTask.status = 'processing';
            bestTask.consumer = consumerName;
            saveBoard(consumeBoard);
            console.log(`🐺 [${consumerName}] ดมกลิ่นเจองานสำคัญสุด: "${bestTask.task}" (Pheromone: ${bestTask.pheromone}) -> กำลังดำเนินการ!`);
        } else {
            console.log(`💤 [${consumerName}] ไม่ได้กลิ่นงานใหม่เลย... พักผ่อน`);
        }
        break;

    case 'status':
        let statusBoard = loadBoard();
        console.log('\n📋 --- ORACLE BLACKBOARD ---');
        statusBoard.tasks.forEach(t => {
            const icon = t.status === 'pending' ? '🟡' : '🟢';
            console.log(`${icon} [Pheromone: ${t.pheromone.toString().padStart(3)}] ${t.task} (Pub: ${t.publisher})`);
        });
        console.log('---------------------------\n');
        break;

    default:
        console.log('Usage: node oracle-blackboard.js [publish|consume|decay|status] <args>');
}
