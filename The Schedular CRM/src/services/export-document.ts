export type ExportCellValue = string | number | boolean | Date | null | undefined;

const PDF_MAX_CHARS_PER_LINE = 88;
const PDF_LINES_PER_PAGE = 46;

function normalizeCell(value: ExportCellValue): string {
  if (value === null || value === undefined) {
    return '';
  }
  if (value instanceof Date) {
    return value.toISOString();
  }
  return String(value);
}

function escapeCsvCell(value: ExportCellValue): string {
  const normalized = normalizeCell(value);
  if (/[",\n]/.test(normalized)) {
    return `"${normalized.replace(/"/g, '""')}"`;
  }
  return normalized;
}

function normalizePdfText(value: string): string {
  return value
    .replace(/\\/g, '\\\\')
    .replace(/\(/g, '\\(')
    .replace(/\)/g, '\\)')
    .replace(/[^\x20-\x7E]/g, '?');
}

function wrapPdfLine(line: string): string[] {
  const normalized = line.replace(/\s+/g, ' ').trim();
  if (!normalized) {
    return [''];
  }

  const words = normalized.split(' ');
  const wrapped: string[] = [];
  let current = '';

  for (const word of words) {
    if (!current) {
      current = word;
      continue;
    }

    if (`${current} ${word}`.length <= PDF_MAX_CHARS_PER_LINE) {
      current = `${current} ${word}`;
      continue;
    }

    wrapped.push(current);
    current = word;
  }

  if (current) {
    wrapped.push(current);
  }

  return wrapped;
}

function buildPdfContentStream(lines: string[]): string {
  const commands = ['BT', '/F1 12 Tf', '50 760 Td', '14 TL'];

  for (const line of lines) {
    commands.push(`(${normalizePdfText(line)}) Tj`);
    commands.push('T*');
  }

  commands.push('ET');
  return commands.join('\n');
}

export function buildCsvDocument(headers: string[], rows: ExportCellValue[][]): string {
  const csvRows = [headers.map(escapeCsvCell).join(',')];

  for (const row of rows) {
    csvRows.push(row.map(escapeCsvCell).join(','));
  }

  return csvRows.join('\n');
}

export function buildInlineDataUrl(contentType: string, content: string): string {
  return `data:${contentType};charset=utf-8,${encodeURIComponent(content)}`;
}

export function buildSimplePdfDocument(title: string, lines: string[]): string {
  const wrappedLines = [title, '', ...lines].flatMap(wrapPdfLine);
  const pageChunks: string[][] = [];

  for (let index = 0; index < wrappedLines.length; index += PDF_LINES_PER_PAGE) {
    pageChunks.push(wrappedLines.slice(index, index + PDF_LINES_PER_PAGE));
  }

  if (pageChunks.length === 0) {
    pageChunks.push([title, '', 'No export data available.']);
  }

  const fontObjectNumber = 3 + pageChunks.length * 2;
  const objects: string[] = [];
  const pageRefs: string[] = [];

  objects[1] = '<< /Type /Catalog /Pages 2 0 R >>';

  pageChunks.forEach((pageLines, index) => {
    const pageObjectNumber = 3 + index * 2;
    const contentObjectNumber = pageObjectNumber + 1;
    const contentStream = buildPdfContentStream(pageLines);
    pageRefs.push(`${pageObjectNumber} 0 R`);

    objects[pageObjectNumber] =
      `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] ` +
      `/Resources << /Font << /F1 ${fontObjectNumber} 0 R >> >> ` +
      `/Contents ${contentObjectNumber} 0 R >>`;
    objects[contentObjectNumber] =
      `<< /Length ${contentStream.length} >>\nstream\n${contentStream}\nendstream`;
  });

  objects[2] = `<< /Type /Pages /Kids [${pageRefs.join(' ')}] /Count ${pageChunks.length} >>`;
  objects[fontObjectNumber] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>';

  let pdf = '%PDF-1.4\n';
  const offsets: number[] = [0];

  for (let objectNumber = 1; objectNumber < objects.length; objectNumber += 1) {
    const objectBody = objects[objectNumber];
    if (!objectBody) {
      continue;
    }
    offsets[objectNumber] = pdf.length;
    pdf += `${objectNumber} 0 obj\n${objectBody}\nendobj\n`;
  }

  const xrefOffset = pdf.length;
  pdf += `xref\n0 ${objects.length}\n`;
  pdf += '0000000000 65535 f \n';

  for (let objectNumber = 1; objectNumber < objects.length; objectNumber += 1) {
    const offset = offsets[objectNumber] ?? 0;
    pdf += `${String(offset).padStart(10, '0')} 00000 n \n`;
  }

  pdf += `trailer\n<< /Size ${objects.length} /Root 1 0 R >>\nstartxref\n${xrefOffset}\n%%EOF`;
  return pdf;
}
