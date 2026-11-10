# AAYUSATHI Phase D11.1: PDF Output / Open / Save Fix

## Overview
Phase D11.1 corrects the user-facing output flow of the official 9-section Visit Report PDF generated in Phase D11. It ensures that the generated PDF is written to a real, accessible Windows filesystem location and provides immediate **[ OPEN PDF ]** and **[ SAVE AS ]** capabilities directly to the Doctor.

## Architecture
- **Result Model**: `VisitReportPdfResult` (`lib/doctor/models/visit_report_pdf_result.dart`)
- **Service Interface**: `PdfOutputService` (`lib/doctor/services/pdf_output_service.dart`)
- **Windows Implementation**: `WindowsPdfOutputService` (`lib/doctor/services/windows_pdf_output_service.dart`)
  - Target Path: `%USERPROFILE%\Documents\AAYUSATHI\VisitReports`
  - Shell Launcher: `cmd /c start ""` / `powershell Start-Process`
  - Safe-As destination copy to Desktop
- **Mock Double**: `MockPdfOutputService` (`lib/doctor/services/mock_pdf_output_service.dart`)
- **UI Dialog**: `DoctorPdfSuccessDialog` (`lib/doctor/widgets/doctor_pdf_success_dialog.dart`)

## Filename Standard
Format: `AAYUSATHI_Visit_Report_<patientId>_Visit_<visitNumber>.pdf`
Example: `AAYUSATHI_Visit_Report_AAYU-102938_Visit_1.pdf`
All illegal path traversal characters are sanitized.
