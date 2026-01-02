import { MockService } from '../mock/MockService';
import { FinancialReport } from '../model/Finance';

export class FinanceService {
  
  static async getFinancialReport(): Promise<FinancialReport> {
    return MockService.getFinancialReport();
  }
}