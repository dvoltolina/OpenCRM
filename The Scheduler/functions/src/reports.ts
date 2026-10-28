/**
 * Cloud Functions for Reporting & Exports
 *
 * Priority 5: Reporting Export Functions
 *
 * Handles:
 * - CSV export generation
 * - PDF report generation
 * - Report metrics aggregation
 */

import {onRequest} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {db, Timestamp, FieldValue, auth} from "./firebaseAdmin";
import {applyCors} from "./httpUtils";
import PDFDocument from "pdfkit";
import {isAdminRole, normalizeUserRole} from "./roleUtils";

interface ReportMetricsResponse {
  success: boolean;
  metrics?: Record<string, number>;
  error?: string;
}

type RowData = Record<string, unknown>;

const getErrorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Internal server error";

const requireReportsAuth = async (
  req: {headers: {authorization?: string}; body: {businessId?: string}},
  res: {status: (code: number) => {json: (data: unknown) => void}}
): Promise<{uid: string; businessId: string} | null> => {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) {
    res.status(401).json({error: "Unauthorized"});
    return null;
  }

  const token = authHeader.split("Bearer ")[1];
  try {
    const decodedToken = await auth.verifyIdToken(token);
    const uid = decodedToken.uid;
    const businessId = typeof req.body.businessId === "string" ?
      req.body.businessId.trim() :
      "";

    if (!businessId) {
      res.status(400).json({success: false, error: "businessId is required"});
      return null;
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      res.status(403).json({error: "User not found"});
      return null;
    }

    const userData = userDoc.data();
    if (userData?.businessId !== businessId) {
      res.status(403).json({error: "Access denied to this business"});
      return null;
    }

    const role = normalizeUserRole(decodedToken.role) ?? normalizeUserRole(userData?.role);
    if (!isAdminRole(role)) {
      res.status(403).json({error: "Reporting access requires owner or admin role"});
      return null;
    }

    return {uid, businessId};
  } catch (error) {
    logger.error("Reporting auth verification failed", {error: getErrorMessage(error)});
    res.status(401).json({error: "Invalid or expired token"});
    return null;
  }
};

/**
 * Convert data to CSV format
 */
const convertToCSV = (data: RowData[], headers: string[]): string => {
  const csvHeaders = headers.join(",");
  const csvRows = data.map((row) => {
    return headers
      .map((header) => {
        const value = row[header] ?? "";
        // Escape quotes and wrap in quotes if contains comma
        const stringValue = String(value).replace(/"/g, "\"\"");
        return stringValue.includes(",") ? `"${stringValue}"` : stringValue;
      })
      .join(",");
  });

  return [csvHeaders, ...csvRows].join("\n");
};

/**
 * Export report as CSV
 *
 * POST /exportReportCsv
 * Body: {
 *   businessId: string,
 *   reportType: 'appointments' | 'payments' | 'clients',
 *   startDate: string (ISO 8601),
 *   endDate: string (ISO 8601)
 * }
 *
 * Returns: {
 *   success: true,
 *   downloadUrl: string
 * }
 */
export const exportReportCsv = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const authResult = await requireReportsAuth(req, res);
    if (!authResult) return;

    const {reportType, startDate, endDate} = req.body;
    const {uid, businessId} = authResult;

    if (!reportType || !startDate || !endDate) {
      res.status(400).json({
        success: false,
        error: "All fields are required",
      });
      return;
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    let data: RowData[] = [];
    let headers: string[] = [];

    switch (reportType) {
    case "appointments": {
      const appointmentsSnapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("appointments")
        .where("startTime", ">=", Timestamp.fromDate(start))
        .where("startTime", "<=", Timestamp.fromDate(end))
        .get();

      data = appointmentsSnapshot.docs.map((doc) => {
        const appt = doc.data();
        return {
          id: doc.id,
          date: appt.startTime?.toDate().toISOString().split("T")[0],
          time: appt.startTime?.toDate().toISOString().split("T")[1].substring(0, 5),
          clientId: appt.clientId,
          providerId: appt.providerId,
          serviceId: appt.serviceId,
          status: appt.status,
          paymentStatus: appt.paymentStatus,
        };
      });

      headers = [
        "id",
        "date",
        "time",
        "clientId",
        "providerId",
        "serviceId",
        "status",
        "paymentStatus",
      ];
      break;
    }

    case "payments": {
      const paymentsSnapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("payments")
        .where("createdAt", ">=", Timestamp.fromDate(start))
        .where("createdAt", "<=", Timestamp.fromDate(end))
        .get();

      data = paymentsSnapshot.docs.map((doc) => {
        const payment = doc.data();
        return {
          id: doc.id,
          date: payment.createdAt?.toDate().toISOString().split("T")[0],
          amount: payment.amountCents / 100,
          currency: payment.currency,
          status: payment.status,
          type: payment.type,
          appointmentId: payment.appointmentId,
        };
      });

      headers = ["id", "date", "amount", "currency", "status", "type", "appointmentId"];
      break;
    }

    case "clients": {
      const clientsSnapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("clients")
        .where("createdAt", ">=", Timestamp.fromDate(start))
        .where("createdAt", "<=", Timestamp.fromDate(end))
        .get();

      data = clientsSnapshot.docs.map((doc) => {
        const client = doc.data();
        return {
          id: doc.id,
          firstName: client.firstName,
          lastName: client.lastName,
          email: client.email,
          phone: client.phone,
          lifecycleStatus: client.lifecycleStatus,
          createdAt: client.createdAt?.toDate().toISOString().split("T")[0],
        };
      });

      headers = [
        "id",
        "firstName",
        "lastName",
        "email",
        "phone",
        "lifecycleStatus",
        "createdAt",
      ];
      break;
    }

    default:
      res.status(400).json({
        success: false,
        error: "Invalid report type",
      });
      return;
    }

    // Convert to CSV
    const csv = convertToCSV(data, headers);

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("audit_logs")
      .add({
        businessId,
        userId: uid,
        actionType: "dataExport",
        entityType: reportType,
        entityId: `${reportType}_${startDate}_${endDate}`,
        timestamp: FieldValue.serverTimestamp(),
        metadata: {reportType, format: "csv", startDate, endDate, recordCount: data.length},
      });

    // In production, upload to Cloud Storage and return signed URL
    // For now, return CSV directly
    res.setHeader("Content-Type", "text/csv");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${reportType}_${startDate}_${endDate}.csv"`
    );
    res.send(csv);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error exporting CSV:", {error});
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Export report as PDF
 *
 * POST /exportReportPdf
 * Body: {
 *   businessId: string,
 *   reportType: 'appointments' | 'payments' | 'clients',
 *   startDate: string (ISO 8601),
 *   endDate: string (ISO 8601)
 * }
 *
 * Returns: PDF file directly or signed URL
 */
export const exportReportPdf = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const authResult = await requireReportsAuth(req, res);
    if (!authResult) return;

    const {reportType, startDate, endDate} = req.body;
    const {uid, businessId} = authResult;

    if (!reportType || !startDate || !endDate) {
      res.status(400).json({
        success: false,
        error: "All fields are required",
      });
      return;
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    // Fetch data based on report type
    let data: (string | number)[][] = [];
    let title = "";
    let headers: string[] = [];

    switch (reportType) {
    case "appointments": {
      title = "Appointments Report";
      headers = ["Date", "Time", "Client ID", "Provider ID", "Service ID", "Status"];
      const snapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("appointments")
        .where("startTime", ">=", Timestamp.fromDate(start))
        .where("startTime", "<=", Timestamp.fromDate(end))
        .orderBy("startTime", "asc")
        .get();

      data = snapshot.docs.map((doc) => {
        const appt = doc.data();
        return [
          appt.startTime?.toDate().toISOString().split("T")[0] || "",
          appt.startTime?.toDate().toISOString().split("T")[1]?.substring(0, 5) || "",
          appt.clientId || "",
          appt.providerId || "",
          appt.serviceId || "",
          appt.status || "",
        ];
      });
      break;
    }

    case "payments": {
      title = "Payments Report";
      headers = ["Date", "Amount", "Currency", "Status", "Type", "Appointment ID"];
      const snapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("payments")
        .where("createdAt", ">=", Timestamp.fromDate(start))
        .where("createdAt", "<=", Timestamp.fromDate(end))
        .orderBy("createdAt", "asc")
        .get();

      data = snapshot.docs.map((doc) => {
        const payment = doc.data();
        return [
          payment.createdAt?.toDate().toISOString().split("T")[0] || "",
          `$${((payment.amountCents || 0) / 100).toFixed(2)}`,
          payment.currency || "USD",
          payment.status || "",
          payment.type || "",
          payment.appointmentId || "",
        ];
      });
      break;
    }

    case "clients": {
      title = "Clients Report";
      headers = ["Name", "Email", "Phone", "Lifecycle", "Created"];
      const snapshot = await db
        .collection("businesses")
        .doc(businessId)
        .collection("clients")
        .where("createdAt", ">=", Timestamp.fromDate(start))
        .where("createdAt", "<=", Timestamp.fromDate(end))
        .orderBy("createdAt", "asc")
        .get();

      data = snapshot.docs.map((doc) => {
        const client = doc.data();
        return [
          `${client.firstName || ""} ${client.lastName || ""}`.trim(),
          client.email || "",
          client.phone || "",
          client.lifecycleStatus || "",
          client.createdAt?.toDate().toISOString().split("T")[0] || "",
        ];
      });
      break;
    }

    default:
      res.status(400).json({success: false, error: "Invalid report type"});
      return;
    }

    // Generate PDF
    const doc = new PDFDocument({margin: 50});
    const chunks: Buffer[] = [];

    doc.on("data", (chunk: Buffer) => chunks.push(chunk));

    // Header
    doc.fontSize(20).text(title, {align: "center"});
    doc.moveDown(0.5);
    doc.fontSize(10).text(
      `Period: ${start.toISOString().split("T")[0]} to ${end.toISOString().split("T")[0]}`,
      {align: "center"}
    );
    doc.text(`Generated: ${new Date().toISOString().split("T")[0]}`, {align: "center"});
    doc.text(`Total Records: ${data.length}`, {align: "center"});
    doc.moveDown(1.5);

    // Table header
    const colWidth = (doc.page.width - 100) / headers.length;
    const startX = 50;
    let y = doc.y;

    // Draw header row background
    doc.fillColor("#2c3e50").rect(startX, y, doc.page.width - 100, 20).fill();
    doc.fillColor("#ffffff");

    headers.forEach((header, i) => {
      doc.fontSize(9).text(header, startX + i * colWidth + 5, y + 5, {
        width: colWidth - 10,
        align: "left",
      });
    });

    doc.fillColor("#000000");
    y += 25;

    // Draw data rows
    data.forEach((row, rowIndex) => {
      // Check if we need a new page
      if (y > doc.page.height - 80) {
        doc.addPage();
        y = 50;
      }

      // Alternate row background
      if (rowIndex % 2 === 0) {
        doc.fillColor("#f8f9fa").rect(startX, y - 3, doc.page.width - 100, 18).fill();
        doc.fillColor("#000000");
      }

      row.forEach((cell, i) => {
        doc.fontSize(8).text(String(cell || ""), startX + i * colWidth + 5, y, {
          width: colWidth - 10,
          align: "left",
        });
      });

      y += 18;
    });

    // Footer
    doc.fontSize(8).text(
      "CONFIDENTIAL - This report may contain PHI protected under HIPAA",
      50,
      doc.page.height - 50,
      {align: "center"}
    );

    doc.end();

    // Wait for PDF generation to complete
    await new Promise<void>((resolve) => doc.on("end", resolve));

    const pdfBuffer = Buffer.concat(chunks);

    // Log audit event (HIPAA compliance)
    await db
      .collection("businesses")
      .doc(businessId)
      .collection("audit_logs")
      .add({
        businessId,
        userId: uid,
        actionType: "dataExport",
        entityType: reportType,
        entityId: `${reportType}_${startDate}_${endDate}`,
        timestamp: FieldValue.serverTimestamp(),
        metadata: {reportType, format: "pdf", startDate, endDate, recordCount: data.length},
      });

    // Return PDF directly
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="${reportType}_${startDate}_${endDate}.pdf"`
    );
    res.send(pdfBuffer);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error exporting PDF:", {error});
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});

/**
 * Get aggregated report metrics
 *
 * POST /getReportMetrics
 * Body: {
 *   businessId: string,
 *   startDate: string (ISO 8601),
 *   endDate: string (ISO 8601)
 * }
 *
 * Returns: {
 *   success: true,
 *   metrics: {
 *     totalAppointments: number,
 *     completedAppointments: number,
 *     cancelledAppointments: number,
 *     totalRevenue: number,
 *     newClients: number,
 *     ...
 *   }
 * }
 */
export const getReportMetrics = onRequest(async (req, res) => {
  if (applyCors(req, res)) return;

  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  try {
    const authResult = await requireReportsAuth(req, res);
    if (!authResult) return;

    const {startDate, endDate} = req.body;
    const {uid, businessId} = authResult;

    if (!startDate || !endDate) {
      res.status(400).json({
        success: false,
        error: "All fields are required",
      });
      return;
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    // Get appointments
    const appointmentsSnapshot = await db
      .collection("businesses")
      .doc(businessId)
      .collection("appointments")
      .where("startTime", ">=", Timestamp.fromDate(start))
      .where("startTime", "<=", Timestamp.fromDate(end))
      .get();

    const totalAppointments = appointmentsSnapshot.size;
    let completedAppointments = 0;
    let cancelledAppointments = 0;

    appointmentsSnapshot.docs.forEach((doc) => {
      const status = doc.data().status;
      if (status === "completed") completedAppointments++;
      if (status === "cancelled") cancelledAppointments++;
    });

    // Get payments
    const paymentsSnapshot = await db
      .collection("businesses")
      .doc(businessId)
      .collection("payments")
      .where("createdAt", ">=", Timestamp.fromDate(start))
      .where("createdAt", "<=", Timestamp.fromDate(end))
      .where("status", "==", "completed")
      .get();

    let totalRevenue = 0;
    paymentsSnapshot.docs.forEach((doc) => {
      totalRevenue += doc.data().amountCents || 0;
    });

    // Get new clients
    const clientsSnapshot = await db
      .collection("businesses")
      .doc(businessId)
      .collection("clients")
      .where("createdAt", ">=", Timestamp.fromDate(start))
      .where("createdAt", "<=", Timestamp.fromDate(end))
      .get();

    const newClients = clientsSnapshot.size;

    const metrics = {
      totalAppointments,
      completedAppointments,
      cancelledAppointments,
      totalRevenue: totalRevenue / 100, // Convert cents to dollars
      newClients,
      averageRevenuePerAppointment:
        totalAppointments > 0 ? totalRevenue / 100 / totalAppointments : 0,
      completionRate:
        totalAppointments > 0 ? (completedAppointments / totalAppointments) * 100 : 0,
    };

    const response: ReportMetricsResponse = {
      success: true,
      metrics,
    };

    await db
      .collection("businesses")
      .doc(businessId)
      .collection("audit_logs")
      .add({
        businessId,
        userId: uid,
        actionType: "phiReadList",
        entityType: "report_metrics",
        entityId: `${startDate}_${endDate}`,
        timestamp: FieldValue.serverTimestamp(),
        metadata: {
          startDate,
          endDate,
          totalAppointments,
          completedAppointments,
          cancelledAppointments,
          newClients,
        },
      });

    res.json(response);
  } catch (error: unknown) {
    const message = getErrorMessage(error);
    logger.error("Error getting report metrics:", {error});
    res.status(500).json({
      success: false,
      error: message,
    });
  }
});
