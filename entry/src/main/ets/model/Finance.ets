export interface FinancialReportByType {
  tournament: number;
  rental: number;
  other: number;
}

export interface FinancialReport {
  totalRevenue: number;
  byType: FinancialReportByType;
}