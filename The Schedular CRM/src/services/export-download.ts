import { buildInlineDataUrl } from './export-document';

export function downloadExportContent(
  content: string,
  contentType: string,
  filename: string
): void {
  const link = document.createElement('a');
  link.download = filename;

  if (typeof URL !== 'undefined' && typeof URL.createObjectURL === 'function') {
    const blob = new Blob([content], { type: contentType });
    const objectUrl = URL.createObjectURL(blob);
    link.href = objectUrl;
    link.click();
    URL.revokeObjectURL(objectUrl);
    return;
  }

  link.href = buildInlineDataUrl(contentType, content);
  link.click();
}
