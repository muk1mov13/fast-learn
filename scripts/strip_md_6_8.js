const fs = require('fs');
const path = require('path');

function stripMd(text) {
  return text
    .replace(/\*\*(.+?)\*\*/gs, '$1')
    .replace(/\*(.+?)\*/gs, '$1')
    .replace(/^#{1,6} +/gm, '')
    .replace(/^\|.+\|$/gm, '')
    .replace(/^[-*] /gm, '')
    .replace(/^---+$/gm, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

const contentDir = path.join(__dirname, '..', 'assets', 'content');

for (let i = 6; i <= 8; i++) {
  const filePath = path.join(contentDir, `topic_${i}.json`);
  const raw = fs.readFileSync(filePath, 'utf8');
  const data = JSON.parse(raw);
  const original = data.lesson.bodyMarkdown;
  const cleaned = stripMd(original);
  if (original !== cleaned) {
    data.lesson.bodyMarkdown = cleaned;
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
    console.log(`topic_${i}: yangilandi (${original.length} -> ${cleaned.length} belgi)`);
  } else {
    console.log(`topic_${i}: o'zgarish yo'q (allaqachon toza)`);
  }
}
