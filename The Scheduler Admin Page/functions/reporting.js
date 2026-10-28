const MS_PER_DAY = 1000 * 60 * 60 * 24;

function generateReportMock(startDate, endDate) {
  const totalDays = Math.max(1, differenceInDays(startDate, endDate));
  const start = new Date(`${startDate}T00:00:00Z`);
  const revenueSeries = [];

  for (let i = 0; i <= totalDays; i += 1) {
    const date = new Date(start.getTime() + i * MS_PER_DAY);
    const weekdayBoost = [1, 2, 3, 4].includes(date.getUTCDay()) ? 1.1 : 0.85;
    const base = 1400 + (i % 6) * 120;
    const variance = ((i * 73) % 200) - 100;
    const collected = Math.max(700, base * weekdayBoost + variance);
    const cancelled = Math.max(0, Math.round(collected * (0.05 + ((i % 5) * 0.005))));
    revenueSeries.push({
      date: date.toISOString().slice(0, 10),
      collected: Number(collected.toFixed(0)),
      cancelled,
    });
  }

  const totalRevenue = revenueSeries.reduce((sum, point) => sum + point.collected, 0);
  const totalCancelled = revenueSeries.reduce((sum, point) => sum + point.cancelled, 0);

  const cancellationReasons = [
    { reason: 'Client canceled', count: Math.round(totalCancelled * 0.4) },
    { reason: 'Provider conflict', count: Math.round(totalCancelled * 0.25) },
    { reason: 'No-show', count: Math.round(totalCancelled * 0.2) },
    { reason: 'Weather', count: Math.round(totalCancelled * 0.15) },
  ];

  const staffUtilization = MOCK_STAFF.map((staff, index) => {
    const baseUtilization = 0.55 + 0.1 * ((index + totalDays) % 3);
    const utilization = Math.min(0.95, baseUtilization + (totalDays % 5) * 0.02);
    return {
      ...staff,
      utilization: Number(utilization.toFixed(2)),
      hoursScheduled: 32 + (index % 3) * 4,
    };
  });

  const clientRetention = [
    { cohort: '0-30 days', retained: 28, churned: 7 },
    { cohort: '31-60 days', retained: 33, churned: 5 },
    { cohort: '61-90 days', retained: 29, churned: 6 },
    { cohort: '90+ days', retained: 41, churned: 4 },
  ];

  const bookingSources = [
    { source: 'Client Portal', count: 180 },
    { source: 'Staff Created', count: 120 },
    { source: 'Waitlist', count: 45 },
    { source: 'Rebook', count: 85 },
  ];

  const peakHours = [
    { label: '08:00', bookings: 32 },
    { label: '10:00', bookings: 56 },
    { label: '12:00', bookings: 48 },
    { label: '14:00', bookings: 42 },
    { label: '16:00', bookings: 37 },
    { label: '18:00', bookings: 21 },
  ];

  const avgRevenuePerDay = totalRevenue / revenueSeries.length;
  const totalAppointments =
    revenueSeries.reduce((sum, point) => sum + point.collected / 140, 0) + totalCancelled;
  const cancellationRate = totalAppointments ? totalCancelled / Math.max(1, totalAppointments) : 0;

  const retentionTotals = clientRetention.reduce(
    (acc, cohort) => {
      acc.retained += cohort.retained;
      acc.churned += cohort.churned;
      return acc;
    },
    { retained: 0, churned: 0 },
  );

  const summary = {
    totalRevenue: Number(totalRevenue.toFixed(2)),
    avgRevenuePerDay: Number(avgRevenuePerDay.toFixed(2)),
    cancellationRate: Number(cancellationRate.toFixed(3)),
    retentionRate: Number(
      retentionTotals.retained / Math.max(1, retentionTotals.retained + retentionTotals.churned),
    ),
    avgUtilization:
      staffUtilization.reduce((sum, staff) => sum + staff.utilization, 0) / staffUtilization.length,
  };

  return {
    revenueSeries,
    cancellationReasons,
    staffUtilization,
    clientRetention,
    bookingSources,
    peakHours,
    summary,
  };
}

function buildCsvFromReport(report, request) {
  const lines = [];
  lines.push(`"Reporting Window","${request.startDate}","${request.endDate}"`);
  lines.push('');
  lines.push('"Date","Collected","Cancelled"');
  report.revenueSeries.forEach((point) => {
    lines.push(`"${point.date}",${point.collected},${point.cancelled}`);
  });
  lines.push('');
  lines.push('"Cancellation Reason","Count"');
  report.cancellationReasons.forEach((reason) => {
    lines.push(`"${reason.reason}",${reason.count}`);
  });
  lines.push('');
  lines.push('"Staff","Utilization","Hours Scheduled"');
  report.staffUtilization.forEach((staff) => {
    lines.push(`"${staff.staffName}",${staff.utilization},${staff.hoursScheduled}`);
  });
  lines.push('');
  lines.push('"Cohort","Retained","Churned"');
  report.clientRetention.forEach((cohort) => {
    lines.push(`"${cohort.cohort}",${cohort.retained},${cohort.churned}`);
  });
  lines.push('');
  lines.push('"Source","Count"');
  report.bookingSources.forEach((source) => {
    lines.push(`"${source.source}",${source.count}`);
  });
  lines.push('');
  lines.push('"Hour","Bookings"');
  report.peakHours.forEach((hour) => {
    lines.push(`"${hour.label}",${hour.bookings}`);
  });

  return lines.join('\n');
}

function buildPlaintextDigest(report, request) {
  if (!report) {
    return `Scheduler Reports\n${request.startDate} → ${request.endDate}\n(no data loaded)`;
  }

  const lines = [
    'Scheduler Reports',
    `${request.startDate} → ${request.endDate}`,
    '',
    `Total Revenue: ${report.summary.totalRevenue.toFixed(2)}`,
    `Average Revenue/Day: ${report.summary.avgRevenuePerDay.toFixed(2)}`,
    `Cancellation Rate: ${(report.summary.cancellationRate * 100).toFixed(1)}%`,
    `Retention Rate: ${(report.summary.retentionRate * 100).toFixed(1)}%`,
    '',
    'Top Booking Sources:',
    ...report.bookingSources.map((source) => `• ${source.source}: ${source.count}`),
    '',
    'Peak Hours:',
    ...report.peakHours.map((hour) => `• ${hour.label}: ${hour.bookings}`),
  ];

  return lines.join('\n');
}

function buildPdfBuffer(report, request) {
  const digestLines = buildPlaintextDigest(report, request).split('\n');
  const sanitizedLines = digestLines.length ? digestLines : ['Scheduler Reports'];
  const commands = sanitizedLines
    .map((line, index) => {
      const prefix = index === 0 ? '' : 'T*\n';
      return `${prefix}(${escapePdfText(line) || ' '}) Tj`;
    })
    .join('\n');
  const content = `BT
/F1 12 Tf
14 TL
72 720 Td
${commands}
ET`;
  const streamLength = Buffer.byteLength(content, 'utf8');
  let pdf = '%PDF-1.4\n';
  const objects = [
    '1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj',
    '2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj',
    '3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >> endobj',
    `4 0 obj << /Length ${streamLength} >>
stream
${content}
endstream
endobj`,
    '5 0 obj << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> endobj',
  ];
  const offsets = [0];
  objects.forEach((obj) => {
    offsets.push(Buffer.byteLength(pdf, 'utf8'));
    pdf += `${obj}\n`;
  });
  const xrefOffset = Buffer.byteLength(pdf, 'utf8');
  pdf += `xref
0 ${offsets.length}
`;
  pdf += '0000000000 65535 f \n';
  for (let i = 1; i < offsets.length; i += 1) {
    pdf += `${offsets[i].toString().padStart(10, '0')} 00000 n \n`;
  }
  pdf += `trailer
<< /Size ${offsets.length} /Root 1 0 R >>
startxref
${xrefOffset}
%%EOF`;
  return Buffer.from(pdf, 'utf8');
}

function buildFileName(request, extension) {
  return `reports-${request.startDate}-${request.endDate}.${extension}`;
}

function createDataUrl(contents, mimeType) {
  return `data:${mimeType};base64,${Buffer.from(contents, 'utf8').toString('base64')}`;
}

function differenceInDays(start, end) {
  const startDate = new Date(`${start}T00:00:00Z`);
  const endDate = new Date(`${end}T00:00:00Z`);
  return Math.max(1, Math.round((endDate.getTime() - startDate.getTime()) / MS_PER_DAY));
}

function escapePdfText(text) {
  return text.replace(/\\/g, '\\\\').replace(/\(/g, '\\(').replace(/\)/g, '\\)');
}

const MOCK_STAFF = [
  { staffId: 's1', staffName: 'Dr. Patel' },
  { staffId: 's2', staffName: 'Dr. Gomez' },
  { staffId: 's3', staffName: 'Therapist Lee' },
  { staffId: 's4', staffName: 'NP Moore' },
  { staffId: 's5', staffName: 'Coach Miller' },
];

module.exports = {
  generateReportMock,
  buildCsvFromReport,
  buildPdfBuffer,
  buildFileName,
  createDataUrl,
};
