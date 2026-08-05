import pypdf

doc = pypdf.PdfReader(r'C:/Users/anyda/Desktop/2603.16021v2.pdf')
total_pages = len(doc.pages)
print(f'Total pages: {total_pages}')

all_text = []
for i in range(total_pages):
    page = doc.pages[i]
    text = page.extract_text()
    all_text.append(f'=== Page {i+1} ===\n{text}\n')

with open(r'D:/innate-works/innate-factory/fire-skills/mwp_paper_full_text.txt', 'w', encoding='utf-8') as f:
    f.write('\n'.join(all_text))

print('Saved to mwp_paper_full_text.txt')
