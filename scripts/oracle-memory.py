import os
import re
from datetime import datetime

# Path: ψ/memory/
MEMORY_DIR = 'ψ/memory'
PATTERNS_FILE = os.path.join(MEMORY_DIR, 'patterns.md')
PEOPLE_FILE = os.path.join(MEMORY_DIR, 'people.md')
RETROSPECTIVES_DIR = os.path.join(MEMORY_DIR, 'retrospectives')
LEARNINGS_DIR = os.path.join(MEMORY_DIR, 'learnings')

def read_file(path):
    if not os.path.exists(path):
        return ""
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def write_file(path, content):
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def extract_patterns(content):
    # Heuristic: Find sections like ## YYYY-MM-DD — [Title]
    # and extract: Observation, Insight, Action, Confidence
    patterns = []
    sections = re.split(r'##\s*(\d{4}-\d{2}-\d{2}\s*—\s*.*)', content)
    for i in range(1, len(sections), 2):
        header = sections[i]
        body = sections[i+1]
        patterns.append({'header': header, 'body': body})
    return patterns

def consolidate_patterns():
    print("--- Consolidating Patterns ---")
    current_patterns = read_file(PATTERNS_FILE)
    existing_headers = [p['header'] for p in extract_patterns(current_patterns)]
    
    new_patterns = []
    
    # Scan Retrospectives (last 2 files)
    retro_files = sorted(os.listdir(RETROSPECTIVES_DIR), reverse=True)[:2]
    for rf in retro_files:
        content = read_file(os.path.join(RETROSPECTIVES_DIR, rf))
        # Extract "เรียนรู้" section
        match = re.search(r'##\s*เรียนรู้(.*?)(##|\Z)', content, re.DOTALL)
        if match:
            learnings = match.group(1).strip()
            # Simple extraction: each bullet point can be a pattern
            for line in learnings.split('\n'):
                line = line.strip()
                if line.startswith('-'):
                    title = line.lstrip('-').strip()
                    if title not in [h.split('—')[-1].strip() for h in existing_headers]:
                        new_patterns.append({
                            'header': f'{datetime.now().strftime("%Y-%m-%d")} — {title}',
                            'body': f'- **สิ่งที่สังเกต**: [Extracted from {rf}]\n- **Insight**: [Needs detail]\n- **การกระทำ**: [Needs detail]\n- **ความมั่นใจ**: สูง'
                        })

    if new_patterns:
        content_to_add = "\n"
        for np in new_patterns:
            print(f"Adding new pattern: {np['header']}")
            content_to_add += f"## {np['header']}\n{np['body']}\n\n"
        
        write_file(PATTERNS_FILE, current_patterns + content_to_add)
    else:
        print("No new patterns found.")

def consolidate_people():
    # Placeholder for updating people.md based on new preferences
    print("--- Consolidating People (Preference) ---")
    pass

if __name__ == "__main__":
    consolidate_patterns()
    consolidate_people()
